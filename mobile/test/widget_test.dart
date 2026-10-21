import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mallika_hospitals/app/mallika_app.dart';
import 'package:mallika_hospitals/core/session/session_controller.dart';

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
