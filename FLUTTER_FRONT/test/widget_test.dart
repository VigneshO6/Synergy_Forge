import 'package:flutter_test/flutter_test.dart';
import 'package:onion_smart/main.dart';

void main() {
  testWidgets('Onion Smart App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OnionSmartApp());
    expect(find.byType(OnionSmartApp), findsOneWidget);
    // Allow splash timer to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
