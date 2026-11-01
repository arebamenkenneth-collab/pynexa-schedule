import 'package:flutter_test/flutter_test.dart';
import 'package:pynexa_schedule/main.dart';

void main() {
  testWidgets('PyNexa Schedule opens successfully', (tester) async {
    await tester.pumpWidget(const PyNexaScheduleApp());

    expect(find.text('PyNexa Schedule'), findsOneWidget);
    expect(
      find.text('Plan smarter. Stay consistent. Get things done.'),
      findsOneWidget,
    );
  });
}
