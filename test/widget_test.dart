import 'package:flutter_test/flutter_test.dart';
import 'package:pynexa_schedule/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PyNexa Schedule dashboard opens successfully', (tester) async {
    await tester.pumpWidget(const PyNexaScheduleApp());

    // Allow initial loading and scheduled UI updates.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(PyNexaScheduleApp), findsOneWidget);
    expect(find.text('PyNexa'), findsWidgets);
  });
}
