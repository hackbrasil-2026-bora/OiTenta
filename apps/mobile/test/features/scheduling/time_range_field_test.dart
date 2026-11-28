import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/scheduling/presentation/time_range_field.dart';

import '../../helpers/test_app.dart';

void main() {
  test('formatMinutes: 24 h com zero à esquerda', () {
    expect(formatMinutes(1140), '19:00');
    expect(formatMinutes(545), '09:05');
    expect(formatMinutes(0), '00:00');
  });

  Future<List<String>> pump(
    WidgetTester tester, {
    int start = 1140,
    int end = 1260,
  }) async {
    await usePhoneSize(tester);
    final calls = <String>[];
    await tester.pumpWidget(
      themed(
        Padding(
          padding: const EdgeInsets.all(20),
          child: TimeRangeField(
            start: start,
            end: end,
            onStart: (m) => calls.add('start:$m'),
            onEnd: (m) => calls.add('end:$m'),
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('mostra início, "até" e fim, com rótulos', (tester) async {
    await pump(tester);
    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('até'), findsOneWidget);
    expect(find.text('21:00'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Início')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Fim')), findsOneWidget);
    expect(find.text('O fim precisa ser depois do início'), findsNothing);
  });

  testWidgets('fim antes do início mostra o erro', (tester) async {
    await pump(tester, start: 1260, end: 1260);
    expect(find.text('O fim precisa ser depois do início'), findsOneWidget);
  });

  testWidgets('início: seletor de 5 em 5 min, 24 h, e confirma', (
    tester,
  ) async {
    final calls = await pump(tester);
    await tester.tap(find.text('19:00'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.mode, CupertinoDatePickerMode.time);
    expect(picker.use24hFormat, isTrue);
    expect(picker.minuteInterval, 5);
    expect(picker.initialDateTime.hour, 19);
    expect(picker.initialDateTime.minute, 0);
    picker.onDateTimeChanged(DateTime(2000, 1, 1, 8, 40));
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(calls, ['start:520']);
    expect(find.byType(CupertinoDatePicker), findsNothing);
  });

  testWidgets('fim: confirma sem mexer devolve o mesmo horário', (
    tester,
  ) async {
    final calls = await pump(tester);
    await tester.tap(find.text('21:00'));
    await tester.pumpAndSettle();
    expect(find.text('Fim'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(calls, ['end:1260']);
  });

  testWidgets('fechar o seletor sem confirmar não muda nada', (tester) async {
    final calls = await pump(tester);
    await tester.tap(find.text('19:00'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('21:00'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });
}
