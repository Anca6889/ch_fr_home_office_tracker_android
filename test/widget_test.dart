import 'package:flutter_test/flutter_test.dart';
import 'package:home_office_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HomeOfficeApp());
    expect(find.byType(HomeOfficeApp), findsOneWidget);
  });
}
