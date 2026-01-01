import 'package:flutter_test/flutter_test.dart';
import 'package:pencet_print/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PencetPrintApp());

    // Verify that splash screen shows
    expect(find.text('Pencet Print'), findsOneWidget);
    expect(find.text('Simple Invoice Printing'), findsOneWidget);
  });
}
