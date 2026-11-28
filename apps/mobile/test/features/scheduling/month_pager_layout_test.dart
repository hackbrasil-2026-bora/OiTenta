import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/scheduling/presentation/calendar_widgets.dart';
import 'package:oitenta/features/scheduling/presentation/week_controller.dart';

import '../../helpers/test_app.dart';

/// Mês que ocupa 6 semanas (ex.: novembro de 2026 começa num domingo e
/// termina numa segunda): o caso mais alto da grade.
List<List<MonthDayView>> _sixWeeks(DateTime month) => [
  for (var w = 0; w < 6; w++)
    [
      for (var d = 0; d < 7; d++)
        MonthDayView(
          date: DateTime(2026, 11, 1 + w * 7 + d),
          weekday: 'D',
          number: 1 + ((w * 7 + d) % 30),
          inMonth: true,
          isToday: false,
          isSelected: false,
          // Bolinhas em todos os dias: a célula fica na altura máxima.
          colorIndexes: const [0, 1, 2],
        ),
    ],
];

void main() {
  testWidgets('mês de 6 semanas cabe no MonthPager sem overflow', (
    tester,
  ) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      themed(
        MonthPager(
          initialMonth: DateTime(2026, 11),
          weeksOf: _sixWeeks,
          onSelectDate: (_) {},
          onMonthChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
