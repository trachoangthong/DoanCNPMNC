
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('app opens the splash page', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('cellphoneS'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });
}
