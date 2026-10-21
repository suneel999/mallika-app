import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/auth_api.dart';
import '../api/booking_api.dart';
import '../api/catalogue_api.dart';
import '../api/updates_api.dart';
import 'token_store.dart';

enum Gate { booting, signedOut, needsProfile, ready, unreachable }

class SessionController extends ChangeNotifier {
  SessionController({
    AuthApi? api,
    CatalogueApi? catalogue,
    BookingApi? bookings,
    UpdatesApi? updates,
    TokenStore? tokens,
  }) : api = api ?? AuthApi(),
       catalogue = catalogue ?? CatalogueApi(),
       bookings = bookings ?? BookingApi(),
       updates = updates ?? UpdatesApi(),
       tokens = tokens ?? SecureTokenStore();

  factory SessionController.preview(
    Gate gate, {
    CatalogueApi? catalogue,
    BookingApi? bookings,
    UpdatesApi? updates,
  }) {
    final session = SessionController(
      api: AuthApi(),
      catalogue: catalogue,
      bookings: bookings,
      updates: updates,
      tokens: MemoryTokenStore(),
    );
    session.gate = gate;
    if (gate == Gate.needsProfile || gate == Gate.ready) {
      session.account = const Account(
        id: 'preview',
        mobileNumber: '+919876543210',
        preferredLanguage: 'en',
        userKind: 'patient',
      );
    }
    if (gate == Gate.ready) {
      session.profile = const PatientProfile(
        id: 'preview-profile',
        patientNumber: 'MAL-PT-000001',
        fullName: 'Preview Patient',
        dateOfBirth: null,
        sex: null,
        mobileNumber: '+919876543210',
        preferredLanguage: 'en',
      );
    }
    return session;
  }

  final AuthApi api;
  final CatalogueApi catalogue;
  final BookingApi bookings;
  final UpdatesApi updates;
  final TokenStore tokens;

  Gate gate = Gate.booting;
  String language = 'en';
  String pendingMobile = '';
  Account? account;
  PatientProfile? profile;
  List<PatientProfile> profiles = [];

  Future<void> boot() async {
    final started = DateTime.now();
    try {
      final refresh = await tokens.read(TokenStore.refreshKey);
      if (refresh == null || refresh.isEmpty) {
        gate = Gate.signedOut;
      } else {
        await _restore(refresh);
      }
    } catch (_) {
      gate = Gate.unreachable;
    }
    final remaining = const Duration(milliseconds: 900) - DateTime.now().difference(started);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    notifyListeners();
  }

  Future<void> _restore(String refresh) async {
    try {
      final verified = await api.refresh(refresh);
      await _store(verified);
      _apply(verified);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await tokens.delete(TokenStore.accessKey);
        await tokens.delete(TokenStore.refreshKey);
        account = null;
        profile = null;
        profiles = [];
        gate = Gate.signedOut;
        return;
      }
      gate = Gate.unreachable;
    }
  }

  void setLanguage(String value) {
    if (value != 'en' && value != 'te') {
      return;
    }
    language = value;
    notifyListeners();
  }

  Future<OtpRequest> requestOtp(String mobileNumber) async {
    final request = await api.requestOtp(mobileNumber);
    pendingMobile = request.mobileNumber;
    return request;
  }

  Future<void> verifyOtp(String code) async {
    final verified = await api.verifyOtp(mobileNumber: pendingMobile, code: code);
    await _store(verified);
    _apply(verified);
    notifyListeners();
  }

  Future<void> completeProfile({
    required String fullName,
    String? dateOfBirth,
    String? sex,
    required String preferredLanguage,
  }) async {
    final created = await _authed(
      (access) => api.createProfile(
        access: access,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        sex: sex,
        preferredLanguage: preferredLanguage,
      ),
    );
    profile = created;
    language = created.preferredLanguage;
    final current = account;
    if (current != null) {
      account = current.copyWith(preferredLanguage: created.preferredLanguage);
    }
    gate = Gate.ready;
    profiles = [created];
    notifyListeners();
  }

  Future<List<CatalogueDepartment>> loadDepartments({String search = ''}) {
    return _authed((access) => catalogue.departments(access, search: search));
  }

  Future<List<CatalogueDoctor>> loadDoctors({String search = ''}) {
    return _authed((access) => catalogue.doctors(access, search: search));
  }

  Future<List<CatalogueService>> loadServices({String search = ''}) {
    return _authed((access) => catalogue.services(access, search: search));
  }

  Future<List<HospitalUpdate>> loadUpdates() {
    return _authed(updates.notifications);
  }

  Future<List<HospitalBanner>> loadBanners() {
    return _authed(updates.banners);
  }

  Future<BookingOptions> loadBookingOptions() {
    return _authed(bookings.options);
  }

  Future<BookingSummary> requestCancellation(String bookingId, {String? reason}) {
    return _authed((access) => bookings.requestCancellation(access, bookingId, reason: reason));
  }

  Future<List<BookingSummary>> loadBookings() {
    return _authed(bookings.list);
  }

  Future<BookingSummary> requestBooking({
    required String idempotencyKey,
    required String patientProfileId,
    String? serviceId,
    required String requestedDate,
    required String timeSlot,
    String? note,
  }) {
    return _authed(
      (access) => bookings.create(
        access: access,
        idempotencyKey: idempotencyKey,
        patientProfileId: patientProfileId,
        serviceId: serviceId,
        requestedDate: requestedDate,
        timeSlot: timeSlot,
        note: note,
      ),
    );
  }

  Future<void> loadProfiles() async {
    final listed = await _authed(api.listProfiles);
    profiles = listed;
    for (final item in listed) {
      if (item.relationship == 'self') {
        profile = item;
      }
    }
    notifyListeners();
  }

  Future<PatientProfile> addFamilyMember({
    required String fullName,
    required String relationship,
    String? mobileNumber,
  }) async {
    final created = await _authed(
      (access) => api.createFamilyProfile(
        access: access,
        fullName: fullName,
        relationship: relationship,
        mobileNumber: mobileNumber,
        preferredLanguage: language,
      ),
    );
    profiles = [...profiles, created];
    notifyListeners();
    return created;
  }

  Future<PatientProfile> updateFamilyMember({
    required PatientProfile person,
    required String fullName,
    required String relationship,
    String? mobileNumber,
  }) async {
    final updated = await _authed(
      (access) => api.updateFamilyProfile(
        access: access,
        profileId: person.id,
        fullName: fullName,
        relationship: relationship,
        mobileNumber: mobileNumber,
      ),
    );
    profiles = [
      for (final item in profiles)
        if (item.id == updated.id) updated else item,
    ];
    notifyListeners();
    return updated;
  }

  Future<void> removeFamilyMember(PatientProfile person) async {
    await _authed((access) => api.deleteFamilyProfile(access, person.id));
    profiles = [for (final item in profiles) if (item.id != person.id) item];
    notifyListeners();
  }

  Future<void> logout() async {
    final refresh = await tokens.read(TokenStore.refreshKey);
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await api.logout(refresh);
      } on ApiException {
        // Local sign-out still proceeds when the server session is already gone.
      }
    }
    await tokens.delete(TokenStore.accessKey);
    await tokens.delete(TokenStore.refreshKey);
    account = null;
    profile = null;
    profiles = [];
    pendingMobile = '';
    gate = Gate.signedOut;
    notifyListeners();
  }

  Future<T> _authed<T>(Future<T> Function(String access) action) async {
    final access = await tokens.read(TokenStore.accessKey);
    if (access == null || access.isEmpty) {
      gate = Gate.signedOut;
      notifyListeners();
      throw const ApiException(
        statusCode: 401,
        code: 'AUTHENTICATION_REQUIRED',
        message: 'Authentication is required.',
      );
    }
    try {
      return await action(access);
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
      final refresh = await tokens.read(TokenStore.refreshKey);
      if (refresh == null || refresh.isEmpty) {
        rethrow;
      }
      final verified = await api.refresh(refresh);
      await _store(verified);
      return action(verified.access);
    }
  }

  Future<void> _store(VerifiedSession verified) async {
    await tokens.write(TokenStore.accessKey, verified.access);
    await tokens.write(TokenStore.refreshKey, verified.refresh);
  }

  void _apply(VerifiedSession verified) {
    account = verified.account;
    profile = verified.profile;
    language = verified.account.preferredLanguage;
    gate = verified.profile == null ? Gate.needsProfile : Gate.ready;
  }
}
