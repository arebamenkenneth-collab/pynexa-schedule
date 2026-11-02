import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pynexa_schedule/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PyNexa Schedule dashboard opens successfully', (tester) async {
    await tester.pumpWidget(const PyNexaScheduleApp());

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(PyNexaScheduleApp), findsOneWidget);
    expect(find.text('PyNexa'), findsWidgets);
  });
}
