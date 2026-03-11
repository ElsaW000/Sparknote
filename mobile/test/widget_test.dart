import 'package:flutter_test/flutter_test.dart';

import 'package:sparknote_mobile/main.dart';

void main() {
  testWidgets('renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const SparknoteApp());
    expect(find.text('登录'), findsOneWidget);
    expect(find.text('去注册'), findsOneWidget);
  });
}
