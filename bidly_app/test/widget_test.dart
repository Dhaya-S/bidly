import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bidly_app/main.dart';

void main() {
  testWidgets('Bidly app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BidlyApp()));
    expect(find.byType(BidlyApp), findsOneWidget);
  });
}
