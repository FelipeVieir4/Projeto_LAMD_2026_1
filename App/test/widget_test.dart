import 'package:flutter_test/flutter_test.dart';
import 'package:lamd_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LamdApp());
    expect(find.text('Fixit LAMD'), findsOneWidget);
  });
}
