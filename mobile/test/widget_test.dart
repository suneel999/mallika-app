import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mallika_hospitals/app/mallika_app.dart';
import 'package:mallika_hospitals/core/api/api_exception.dart';
import 'package:mallika_hospitals/core/api/auth_api.dart';
import 'package:mallika_hospitals/core/session/session_controller.dart';
import 'package:mallika_hospitals/features/profile/profile_screen.dart';
import 'package:mallika_hospitals/features/profile/family_member_screen.dart';

void main() {
  testWidgets('shows the Stitch home screen', (tester) async {
    await tester.pumpWidget(MallikaApp(session: SessionController.preview(Gate.ready)));

    expect(find.text('MALLIKA HOSPITALS'), findsOneWidget);
    expect(find.text('Our Medical Services'), findsOneWidget);
    expect(find.text('Book Appointment'), findsOneWidget);
    expect(find.text('Call Now'), findsOneWidget);
    expect(find.text('7 Dedicated Wings'), findsOneWidget);
  });

  testWidgets('welcome leads to mobile number entry', (tester) async {
    await _open(tester, MallikaApp(session: SessionController.preview(Gate.signedOut)));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send OTP'));
    await tester.pump();
    expect(find.text('Enter a 10-digit Indian mobile number.'), findsOneWidget);
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

  testWidgets('profile list updates when the session gains a family member', (tester) async {
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

  testWidgets('family member form asks for a name and relationship', (tester) async {
    await _open(
      tester,
      MaterialApp(
        home: FamilyMemberScreen(session: SessionController.preview(Gate.ready)),
      ),
    );

    await tester.tap(find.text('Save family member'));
    await tester.pump();
    expect(find.textContaining('full name'), findsOneWidget);
  });

  testWidgets('profile setup asks for a full name', (tester) async {
    await _open(tester, MallikaApp(session: SessionController.preview(Gate.needsProfile)));

    await tester.tap(find.text('Complete Setup'));
    await tester.pump();
    expect(find.textContaining('full name'), findsOneWidget);
  });
}

Future<void> _open(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
}
