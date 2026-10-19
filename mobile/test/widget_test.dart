import 'package:flutter_test/flutter_test.dart';
import 'package:mallika_hospitals/app/mallika_app.dart';

void main() {
  testWidgets('shows the Stitch home screen', (tester) async {
    await tester.pumpWidget(const MallikaApp());

    expect(find.text('MALLIKA HOSPITALS'), findsOneWidget);
    expect(find.text('Our Medical Services'), findsOneWidget);
    expect(find.text('Book Appointment'), findsOneWidget);
    expect(find.text('Call Now'), findsOneWidget);
    expect(find.text('7 Dedicated Wings'), findsOneWidget);
  });
}
