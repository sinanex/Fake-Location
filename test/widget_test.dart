import 'package:flutter_test/flutter_test.dart';
import 'package:mock_location_app/main.dart';

void main() {
  testWidgets('App loads title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MockLocationApp());
    expect(find.text('Mock Location'), findsOneWidget);
  });
}
