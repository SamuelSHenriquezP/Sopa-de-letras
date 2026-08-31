import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sopa_de_letras/main.dart';

void main() {
  testWidgets('SopaSeniorApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SopaSeniorApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('SOPA DE LETRAS'), findsOneWidget);
  });
}
