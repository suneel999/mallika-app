import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mallika_hospitals/app/mallika_app.dart';
import 'package:mallika_hospitals/core/api/api_exception.dart';
import 'package:mallika_hospitals/core/api/auth_api.dart';
import 'package:mallika_hospitals/core/api/booking_api.dart';
import 'package:mallika_hospitals/core/api/catalogue_api.dart';
import 'package:mallika_hospitals/core/api/updates_api.dart';
import 'package:mallika_hospitals/core/session/session_controller.dart';
import 'package:mallika_hospitals/features/bookings/booking_screens.dart';
import 'package:mallika_hospitals/core/session/token_store.dart';
import 'package:mallika_hospitals/features/profile/profile_screen.dart';
import 'package:mallika_hospitals/features/profile/family_member_screen.dart';

void main() {
  testWidgets('shows the Stitch home screen', (tester) async {
    await tester.pumpWidget(
      MallikaApp(session: SessionController.preview(Gate.ready)),
    );

    expect(find.text('MALLIKA HOSPITALS'), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsNothing);
    expect(find.bySemanticsLabel('Book Your Consultation'), findsOneWidget);
    expect(find.bySemanticsLabel('Open in Google Maps'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsWidgets);
    for (final title in [
      'Book Consultation',
      '4D Echo',
      'CT Calcium',
      'CT Angio',
      'Lab Tests',
      'Ambulance',
    ]) {
      expect(find.bySemanticsLabel(title), findsOneWidget);
    }
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Book for Family'), findsNothing);
    expect(find.text('SOS Call'), findsOneWidget);
    expect(find.textContaining('40%'), findsNothing);

    await tester.tap(find.byIcon(Icons.person).first);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Add family member'), findsOneWidget);
  });

  testWidgets('service cards stay two per row on every phone width', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const titles = [
      'Book Consultation',
      '4D Echo',
      'CT Calcium',
      'CT Angio',
      'Lab Tests',
      'Ambulance',
    ];
    for (final width in [320.0, 360.0, 390.0, 430.0, 600.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MallikaApp(session: SessionController.preview(Gate.ready)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final rects = [
        for (final title in titles)
          tester.getRect(find.bySemanticsLabel(title)),
      ];
      expect(rects, hasLength(6));
      final banner = tester.getRect(
        find.bySemanticsLabel('Book Your Consultation'),
      );
      expect(banner.width, closeTo(rects[1].right - rects[0].left, 1));
      expect(banner.height, closeTo(banner.width * 9 / 16, 1.5));
      for (var row = 0; row < 3; row++) {
        final left = rects[row * 2];
        final right = rects[row * 2 + 1];
        expect(left.top, right.top);
        expect(left.width, right.width);
        expect(left.height, left.width);
        expect(right.height, right.width);
        expect(left.right, lessThan(right.left));
        expect(right.right - left.left, closeTo(width - 32, 1));
        if (row > 0) {
          expect(left.left, rects[0].left);
          expect(right.left, rects[1].left);
          expect(left.top, greaterThan(rects[row * 2 - 2].bottom));
        }
      }
    }
  });

  testWidgets('book appointment asks for a date and time with the one doctor', (
    tester,
  ) async {
    final session = await _signedIn(
      api: _LinkedProfiles(),
      bookings: _ConsultationOptions(),
    );
    await _open(tester, MallikaApp(session: session));
    await tester.pumpAndSettle();

    expect(find.text('Dr. K. Srinivas Rao'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Book Your Consultation'));
    await tester.pumpAndSettle();

    expect(find.text('Hospital Doctor'), findsOneWidget);

    expect(find.text('Choose a time'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('Departments'), findsNothing);
  });

  testWidgets('the request form books for the signed-in patient only', (
    tester,
  ) async {
    final session = await _signedIn(
      api: _LinkedProfiles(),
      bookings: _ConsultationOptions(),
    );
    await _open(
      tester,
      MaterialApp(
        home: BookingRequestScreen(session: session, consultation: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Who is this for?'), findsNothing);
    expect(find.text('Arun Rao'), findsNothing);
    expect(find.text('Book for Family'), findsNothing);
  });

  testWidgets('a home service tile opens published services by id', (
    tester,
  ) async {
    final session = await _signedIn(
      api: _LinkedProfiles(),
      bookings: _ConsultationOptions(),
      catalogue: _HeartService(),
    );
    await _open(tester, MallikaApp(session: session));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('4D Echo'));
    await tester.pumpAndSettle();

    expect(find.text('Heart checkup'), findsOneWidget);
    expect(
      find.text('The hospital has not opened booking for this service yet.'),
      findsNothing,
    );

    await tester.tap(find.text('Heart checkup'));
    await tester.pumpAndSettle();
    expect(find.text('Request service'), findsOneWidget);
    expect(
      find.text('The hospital has not opened booking for this service yet.'),
      findsNothing,
    );
  });

  testWidgets('bookings tab shows a pending request', (tester) async {
    final session = SessionController.preview(
      Gate.ready,
      bookings: _CancellableBookings(),
    );
    await session.tokens.write(TokenStore.accessKey, 'preview-access');
    await _open(tester, MallikaApp(session: session));

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('MAL-BK-000001'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(
      find.text('You have not booked any appointment yet.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.verified), findsOneWidget);

    await tester.tap(find.text('Missed'));
    await tester.pumpAndSettle();
    expect(
      find.text('You have not booked any appointment yet.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.event_busy), findsOneWidget);

    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request cancellation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request cancellation').last);
    await tester.pumpAndSettle();
    expect(find.text('Cancellation requested'), findsOneWidget);
  });

  testWidgets('updates tab shows a stored hospital message', (tester) async {
    final session = await _signedIn(
      api: _LinkedProfiles(),
      bookings: _ConsultationOptions(),
      updates: _OneUpdate(),
    );
    await _open(tester, MallikaApp(session: session));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Updates'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('The hospital confirmed MAL-BK-000001.'), findsOneWidget);
  });

  testWidgets('welcome leads to mobile number entry', (tester) async {
    await _open(
      tester,
      MallikaApp(session: SessionController.preview(Gate.signedOut)),
    );

    expect(find.text('Patient Login'), findsOneWidget);
    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Enter a 10-digit Indian mobile number.'), findsOneWidget);
  });

  testWidgets('the test number signs in when the server is down', (
    tester,
  ) async {
    final session = SessionController(
      api: _OfflineAuth(),
      tokens: MemoryTokenStore(),
    );
    session.gate = Gate.signedOut;
    await _open(tester, MallikaApp(session: session));

    await tester.enterText(
      find.byKey(const Key('mobile-number')),
      '9999999999',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Enter Verification Code'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('otp-code')), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Hi Test'), findsOneWidget);
  });

  test('field errors are shown instead of the generic validation message', () {
    const error = ApiException(
      statusCode: 400,
      code: 'VALIDATION_ERROR',
      message: 'Please check the submitted fields.',
      fields: {'mobile_number': 'Enter a 10-digit Indian mobile number.'},
    );
    expect(error.displayMessage, 'Enter a 10-digit Indian mobile number.');
  });

  testWidgets('profile list updates when the session gains a family member', (
    tester,
  ) async {
    final session = SessionController.preview(Gate.ready);
    session.profiles = [session.profile!];
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(session: session)));
    expect(find.text('Preview Patient'), findsOneWidget);

    session.profiles = [
      session.profile!,
      const PatientProfile(
        id: 'family',
        patientNumber: 'MAL-PT-000002',
        fullName: 'Arun Rao',
        dateOfBirth: null,
        sex: null,
        mobileNumber: '+919876543299',
        preferredLanguage: 'en',
        relationship: 'child',
      ),
    ];
    session.notifyListeners();
    await tester.pump();

    expect(find.text('Arun Rao'), findsOneWidget);
  });

  testWidgets('family member form asks for a name and relationship', (
    tester,
  ) async {
    await _open(
      tester,
      MaterialApp(
        home: FamilyMemberScreen(
          session: SessionController.preview(Gate.ready),
        ),
      ),
    );

    await tester.tap(find.text('Save family member'));
    await tester.pump();
    expect(find.textContaining('full name'), findsOneWidget);
  });

  testWidgets('profile setup asks for a full name', (tester) async {
    await _open(
      tester,
      MallikaApp(session: SessionController.preview(Gate.needsProfile)),
    );

    await tester.tap(find.text('Save and continue'));
    await tester.pump();
    expect(find.textContaining('full name'), findsOneWidget);
  });
}

Future<SessionController> _signedIn({
  AuthApi? api,
  BookingApi? bookings,
  CatalogueApi? catalogue,
  UpdatesApi? updates,
}) async {
  final session = SessionController(
    api: api ?? AuthApi(),
    bookings: bookings,
    catalogue: catalogue,
    updates: updates,
    tokens: MemoryTokenStore(),
  );
  session.gate = Gate.ready;
  session.profile = const PatientProfile(
    id: 'self',
    patientNumber: 'MAL-PT-000001',
    fullName: 'Preview Patient',
    dateOfBirth: null,
    sex: null,
    mobileNumber: '+919876543210',
    preferredLanguage: 'en',
  );
  await session.tokens.write(TokenStore.accessKey, 'preview-access');
  return session;
}

class _OfflineAuth extends AuthApi {
  @override
  Future<OtpRequest> requestOtp(String mobileNumber, {Duration? timeout}) {
    throw const ApiException(
      statusCode: 0,
      code: 'NETWORK',
      message: 'The server did not connect.',
    );
  }

  @override
  Future<VerifiedSession> verifyOtp({
    required String mobileNumber,
    required String code,
    Duration? timeout,
  }) {
    throw const ApiException(
      statusCode: 0,
      code: 'NETWORK',
      message: 'The server did not connect.',
    );
  }
}

class _LinkedProfiles extends AuthApi {
  @override
  Future<List<PatientProfile>> listProfiles(String access) async {
    return const [
      PatientProfile(
        id: 'self',
        patientNumber: 'MAL-PT-000001',
        fullName: 'Preview Patient',
        dateOfBirth: null,
        sex: null,
        mobileNumber: '+919876543210',
        preferredLanguage: 'en',
        relationship: 'self',
      ),
      PatientProfile(
        id: 'family',
        patientNumber: 'MAL-PT-000002',
        fullName: 'Arun Rao',
        dateOfBirth: null,
        sex: null,
        mobileNumber: '+919876543299',
        preferredLanguage: 'en',
        relationship: 'child',
      ),
    ];
  }
}

class _HeartService extends CatalogueApi {
  @override
  Future<List<CatalogueService>> services(
    String access, {
    String search = '',
    String serviceType = '',
  }) async {
    return const [
      CatalogueService(
        id: 'svc-1',
        name: 'Heart checkup',
        serviceType: 'health_checkup',
      ),
    ];
  }
}

class _OneUpdate extends UpdatesApi {
  @override
  Future<List<HospitalBanner>> banners(String access) async => const [];

  @override
  Future<List<HospitalUpdate>> notifications(String access) async {
    return const [
      HospitalUpdate(
        id: 'update',
        title: 'Mallika Hospitals',
        body: 'The hospital confirmed MAL-BK-000001.',
        createdAt: '2026-10-21T10:00:00+05:30',
      ),
    ];
  }
}

class _ConsultationOptions extends BookingApi {
  @override
  Future<BookingOptions> options(String access) async {
    return const BookingOptions(
      doctor: ConsultationDoctor(
        id: 'doctor',
        fullName: 'Hospital Doctor',
        qualification: 'MD',
      ),
      timeSlots: ['10:00', '16:00'],
    );
  }
}

class _CancellableBookings extends BookingApi {
  @override
  Future<BookingOptions> options(String access) async {
    return const BookingOptions(timeSlots: ['10:00']);
  }

  @override
  Future<List<BookingSummary>> list(String access) async {
    return const [
      BookingSummary(
        id: 'booking',
        reference: 'MAL-BK-000001',
        patientName: 'Preview Patient',
        status: 'requested',
        requestedDate: '2026-10-22',
        serviceName: 'Heart checkup',
      ),
    ];
  }

  @override
  Future<BookingSummary> requestCancellation(
    String access,
    String bookingId, {
    String? reason,
  }) async {
    return const BookingSummary(
      id: 'booking',
      reference: 'MAL-BK-000001',
      patientName: 'Preview Patient',
      status: 'cancellation_requested',
      requestedDate: '2026-10-22',
      serviceName: 'Heart checkup',
    );
  }
}

Future<void> _open(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
}
