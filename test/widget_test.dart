import 'package:flutter_test/flutter_test.dart';
import 'package:inner_archive/app.dart';

void main() {
  testWidgets('App renders', (tester) async {
    await tester.pumpWidget(const InnerArchiveApp());
    expect(find.text('Library'), findsOneWidget);
  });
}
