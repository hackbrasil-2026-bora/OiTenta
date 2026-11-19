import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/core/widgets/bora_widgets.dart';
import 'package:oitenta/features/profile/presentation/routine_controller.dart';
import 'package:oitenta/features/profile/presentation/routine_screen.dart';

import '../../helpers/test_app.dart';
import 'routine_fakes.dart';

Widget host(
  RoutineController c, {
  VoidCallback? onSave,
  VoidCallback? onBack,
}) => themed(
  ListenableBuilder(
    listenable: c,
    builder: (_, _) => RoutineScreen(
      state: c,
      onBack: onBack ?? () {},
      onToggle: c.toggle,
      onLimit: c.setLimitHours,
      onSave: onSave ?? () {},
    ),
  ),
);

void main() {
  testWidgets('título, subtítulo, grade Seg…Dom × 8h…20h e legenda', (
    tester,
  ) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      host(RoutineController(FakeSchedulingRepository())),
    );
    expect(find.text('Redefinir minha rotina'), findsOneWidget);
    expect(
      find.text(
        'Pinte os horários em que você costuma estar livre. Eu só encaixo etapas neles.',
      ),
      findsOneWidget,
    );
    for (final d in ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']) {
      expect(find.text(d), findsOneWidget);
    }
    for (final h in ['8h', '10h', '12h', '14h', '16h', '18h', '20h']) {
      expect(find.text(h), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Dom 20h'), findsOneWidget);
    expect(find.text('Livre'), findsOneWidget);
    expect(find.text('Ocupado'), findsOneWidget);
    expect(find.text('0h livres por semana'), findsOneWidget);
  });

  testWidgets('tocar uma célula pinta e despinta', (tester) async {
    await usePhoneSize(tester);
    final c = RoutineController(FakeSchedulingRepository());
    await tester.pumpWidget(host(c));
    final cell = find.bySemanticsLabel('Seg 8h');
    expect(tester.getSemantics(cell), isSemantics(isSelected: false));

    await tester.tap(cell);
    await tester.pump();
    expect(c.isFree(0, 0), isTrue);
    expect(tester.getSemantics(cell), isSemantics(isSelected: true));
    expect(find.text('2h livres por semana'), findsOneWidget);

    await tester.tap(cell);
    await tester.pump();
    expect(c.isFree(0, 0), isFalse);
    expect(tester.getSemantics(cell), isSemantics(isSelected: false));
    expect(find.text('0h livres por semana'), findsOneWidget);
  });

  testWidgets('a célula da quarta 14h é dia 2, linha 3', (tester) async {
    await usePhoneSize(tester);
    final c = RoutineController(FakeSchedulingRepository());
    await tester.pumpWidget(host(c));
    await tester.tap(find.bySemanticsLabel('Qua 14h'));
    await tester.pump();
    expect(c.isFree(2, 3), isTrue);
  });

  testWidgets('"Limite diário" mostra o valor e o slider muda o limite', (
    tester,
  ) async {
    await usePhoneSize(tester);
    final c = RoutineController(FakeSchedulingRepository());
    await tester.pumpWidget(host(c));
    expect(find.text('LIMITE DIÁRIO'), findsOneWidget);
    expect(find.text('4h'), findsOneWidget);
    final slider = tester.widget<BoraSlider>(find.byType(BoraSlider));
    expect(slider.value, 4);
    expect(slider.min, 1);
    expect(slider.max, 8);

    final box = tester.getRect(find.byType(BoraSlider));
    await tester.tapAt(Offset(box.right - 2, box.center.dy));
    await tester.pump();
    expect(c.limitHours, 8);
    // "8h" também é o rótulo da primeira linha da grade.
    expect(find.text('8h'), findsNWidgets(2));
    expect(find.text('4h'), findsNothing);
  });

  testWidgets(
    '"Salvar e recalcular plano" fica desabilitado sem células e chama onSave com células',
    (tester) async {
      await usePhoneSize(tester);
      final c = RoutineController(FakeSchedulingRepository());
      var saves = 0;
      await tester.pumpWidget(host(c, onSave: () => saves++));
      final btn = find.text('Salvar e recalcular plano');
      await tester.tap(btn);
      await tester.pump();
      expect(saves, 0);

      await tester.tap(find.bySemanticsLabel('Ter 10h'));
      await tester.pump();
      await tester.tap(btn);
      await tester.pump();
      expect(saves, 1);
    },
  );

  testWidgets('o erro do salvar aparece na tela', (tester) async {
    await usePhoneSize(tester);
    final repo = FakeSchedulingRepository()
      ..setError = ValidationFailure('Janela inválida.');
    final c = RoutineController(repo)..toggle(0, 0);
    await tester.pumpWidget(host(c, onSave: c.save));
    await tester.tap(find.text('Salvar e recalcular plano'));
    await tester.pumpAndSettle();
    expect(find.text('Janela inválida.'), findsOneWidget);
  });

  testWidgets('o botão voltar chama onBack', (tester) async {
    await usePhoneSize(tester);
    var backs = 0;
    await tester.pumpWidget(
      host(
        RoutineController(FakeSchedulingRepository()),
        onBack: () => backs++,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Voltar'));
    expect(backs, 1);
  });
}
