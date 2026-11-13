import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/auth_api.dart';
import '../api/booking_api.dart';
import '../api/catalogue_api.dart';
import '../api/updates_api.dart';
import '../config.dart';
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
  String? pendingProfileName;
  bool _demoOffline = false;
  final List<BookingSummary> _demoBookings = [];
  int _demoSerial = 1;
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
    final remaining =
        const Duration(milliseconds: 900) - DateTime.now().difference(started);
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

  bool _isTestMobile(String mobileNumber) {
    final digits = mobileNumber.replaceAll(RegExp(r'\D'), '');
    final national = digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits;
    return national == AppConfig.testMobileDigits;
  }

  Future<OtpRequest> requestOtp(String mobileNumber) async {
    if (_isTestMobile(mobileNumber)) {
      _demoOffline = true;
      pendingMobile = _demoMobile(mobileNumber);
      return OtpRequest(
        mobileNumber: pendingMobile,
        expiresIn: 300,
        resendAfter: 120,
      );
    }
    if (AppConfig.demoOtp.isEmpty) {
      final request = await api.requestOtp(mobileNumber);
      pendingMobile = request.mobileNumber;
      return request;
    }
    final mobile = _demoMobile(mobileNumber);
    pendingMobile = mobile;
    try {
      final request = await api.requestOtp(
        mobileNumber,
        timeout: const Duration(seconds: 4),
      );
      _demoOffline = false;
      pendingMobile = request.mobileNumber;
      return request;
    } on ApiException catch (error) {
      if (error.statusCode != 0) {
        rethrow;
      }
      _demoOffline = true;
      return OtpRequest(mobileNumber: mobile, expiresIn: 300, resendAfter: 0);
    }
  }

  Future<void> verifyOtp(String code) async {
    if (_isTestMobile(pendingMobile)) {
      if (code != AppConfig.testOtp) {
        throw const ApiException(
          statusCode: 400,
          code: 'VALIDATION_ERROR',
          message: 'Enter 123456 for the test number.',
        );
      }
      _enterTestUser(pendingMobile);
      notifyListeners();
      return;
    }
    if (AppConfig.demoOtp.isNotEmpty) {
      if (code != AppConfig.demoOtp) {
        throw ApiException(
          statusCode: 400,
          code: 'VALIDATION_ERROR',
          message: 'The demo code is ${AppConfig.demoOtp}.',
        );
      }
      if (!_demoOffline) {
        try {
          final verified = await api.verifyOtp(
            mobileNumber: pendingMobile,
            code: code,
            timeout: const Duration(seconds: 4),
          );
          await _store(verified);
          _apply(verified);
          await _applyPendingProfile();
          notifyListeners();
          return;
        } on ApiException {
          _demoOffline = true;
        }
      }
      _enterLocalDemo(pendingMobile);
      await _applyPendingProfile();
      notifyListeners();
      return;
    }
    final verified = await api.verifyOtp(
      mobileNumber: pendingMobile,
      code: code,
    );
    await _store(verified);
    _apply(verified);
    await _applyPendingProfile();
    notifyListeners();
  }

  Future<void> completeProfile({
    required String fullName,
    String? dateOfBirth,
    String? sex,
    required String preferredLanguage,
  }) async {
    if (_demoOffline) {
      final created = PatientProfile(
        id: 'demo-self',
        patientNumber: 'MAL-PT-000001',
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        sex: sex,
        mobileNumber: account?.mobileNumber ?? pendingMobile,
        preferredLanguage: preferredLanguage,
        relationship: 'self',
        isDefault: true,
      );
      profile = created;
      profiles = [created];
      language = preferredLanguage;
      final current = account;
      if (current != null) {
        account = current.copyWith(preferredLanguage: preferredLanguage);
      }
      gate = Gate.ready;
      notifyListeners();
      return;
    }
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
    if (_demoOffline) {
      return Future.value(const []);
    }
    return _authed((access) => catalogue.departments(access, search: search));
  }

  Future<List<CatalogueDoctor>> loadDoctors({String search = ''}) {
    if (_demoOffline) {
      return Future.value(const []);
    }
    return _authed((access) => catalogue.doctors(access, search: search));
  }

  Future<List<CatalogueService>> loadServices({String search = ''}) {
    if (_demoOffline) {
      return Future.value(const []);
    }
    return _authed((access) => catalogue.services(access, search: search));
  }

  Future<List<HospitalUpdate>> loadUpdates() {
    if (_demoOffline) {
      return Future.value(const []);
    }
    return _authed(updates.notifications);
  }

  Future<List<HospitalBanner>> loadBanners() {
    if (_demoOffline) {
      return Future.value(const []);
    }
    return _authed(updates.banners);
  }

  Future<BookingOptions> loadBookingOptions() {
    if (_demoOffline) {
      return Future.value(
        const BookingOptions(
          timeSlots: [
            '09:00',
            '10:00',
            '11:00',
            '12:00',
            '16:00',
            '17:00',
            '18:00',
          ],
        ),
      );
    }
    return _authed(bookings.options);
  }

  Future<BookingSummary> requestCancellation(
    String bookingId, {
    String? reason,
  }) async {
    if (_demoOffline) {
      final index = _demoBookings.indexWhere((item) => item.id == bookingId);
      if (index < 0) {
        throw const ApiException(
          statusCode: 404,
          code: 'NOT_FOUND',
          message: 'That request was not found.',
        );
      }
      final current = _demoBookings[index];
      final updated = BookingSummary(
        id: current.id,
        reference: current.reference,
        patientName: current.patientName,
        status: 'cancellation_requested',
        requestedDate: current.requestedDate,
        doctorName: current.doctorName,
        serviceName: current.serviceName,
        patientNote: current.patientNote,
        preferredTimeSlot: current.preferredTimeSlot,
        confirmedFor: current.confirmedFor,
      );
      _demoBookings[index] = updated;
      return updated;
    }
    return _authed(
      (access) =>
          bookings.requestCancellation(access, bookingId, reason: reason),
    );
  }

  Future<List<BookingSummary>> loadBookings() {
    if (_demoOffline) {
      return Future.value(List<BookingSummary>.from(_demoBookings));
    }
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
    if (_demoOffline) {
      final person = _demoPerson(patientProfileId);
      final created = BookingSummary(
        id: 'demo-booking-$_demoSerial',
        reference: 'MAL-BK-${_demoSerial.toString().padLeft(6, '0')}',
        patientName: person?.fullName ?? 'Patient',
        status: 'requested',
        requestedDate: requestedDate,
        serviceName: serviceId == null ? null : 'Published service',
        patientNote: note,
        preferredTimeSlot: timeSlot,
      );
      _demoSerial += 1;
      _demoBookings.add(created);
      return Future.value(created);
    }
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
    if (_demoOffline) {
      return;
    }
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
    if (_demoOffline) {
      final created = _localProfile(
        fullName: fullName,
        relationship: relationship,
        mobileNumber: mobileNumber,
      );
      profiles = [...profiles, created];
      notifyListeners();
      return created;
    }
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
    if (_demoOffline) {
      final updated = PatientProfile(
        id: person.id,
        patientNumber: person.patientNumber,
        fullName: fullName,
        dateOfBirth: person.dateOfBirth,
        sex: person.sex,
        mobileNumber: (mobileNumber == null || mobileNumber.isEmpty)
            ? person.mobileNumber
            : mobileNumber,
        preferredLanguage: person.preferredLanguage,
        relationship: relationship,
        isDefault: person.isDefault,
      );
      profiles = [
        for (final item in profiles)
          if (item.id == updated.id) updated else item,
      ];
      notifyListeners();
      return updated;
    }
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
    if (_demoOffline) {
      profiles = [
        for (final item in profiles)
          if (item.id != person.id) item,
      ];
      notifyListeners();
      return;
    }
    await _authed((access) => api.deleteFamilyProfile(access, person.id));
    profiles = [
      for (final item in profiles)
        if (item.id != person.id) item,
    ];
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
    pendingProfileName = null;
    _demoOffline = false;
    _demoBookings.clear();
    gate = Gate.signedOut;
    notifyListeners();
  }

  Future<void> _applyPendingProfile() async {
    final name = pendingProfileName?.trim() ?? '';
    if (gate != Gate.needsProfile || name.length < 2) {
      return;
    }
    pendingProfileName = null;
    await completeProfile(fullName: name, preferredLanguage: language);
  }

  void _enterTestUser(String mobile) {
    _demoOffline = true;
    final typed = pendingProfileName?.trim() ?? '';
    final fullName = typed.length >= 2 ? typed : 'Test Patient';
    pendingProfileName = null;
    account = Account(
      id: 'test-user',
      mobileNumber: mobile,
      preferredLanguage: language,
      userKind: 'patient',
    );
    profile = PatientProfile(
      id: 'test-self',
      patientNumber: 'MAL-PT-TEST',
      fullName: fullName,
      dateOfBirth: null,
      sex: null,
      mobileNumber: mobile,
      preferredLanguage: language,
      relationship: 'self',
      isDefault: true,
    );
    profiles = [profile!];
    gate = Gate.ready;
  }

  void _enterLocalDemo(String mobile) {
    _demoOffline = true;
    account = Account(
      id: 'demo',
      mobileNumber: mobile,
      preferredLanguage: language,
      userKind: 'patient',
    );
    profile = null;
    profiles = [];
    gate = Gate.needsProfile;
  }

  PatientProfile? _demoPerson(String profileId) {
    for (final item in profiles) {
      if (item.id == profileId) {
        return item;
      }
    }
    return profile;
  }

  PatientProfile _localProfile({
    required String fullName,
    required String relationship,
    String? mobileNumber,
  }) {
    _demoSerial += 1;
    final serial = _demoSerial;
    return PatientProfile(
      id: 'demo-$serial',
      patientNumber: 'MAL-PT-${serial.toString().padLeft(6, '0')}',
      fullName: fullName,
      dateOfBirth: null,
      sex: null,
      mobileNumber: (mobileNumber == null || mobileNumber.isEmpty)
          ? (account?.mobileNumber ?? pendingMobile)
          : mobileNumber,
      preferredLanguage: language,
      relationship: relationship,
    );
  }

  String _demoMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final national = digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits;
    return '+91$national';
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
