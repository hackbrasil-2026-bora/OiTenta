import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_form_controller.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_form_screen.dart';

import '../../helpers/test_app.dart';
import 'commitment_form_fakes.dart';

/// Sexta, 20/11/2026.
final today = DateTime(2026, 11, 20, 10);

CommitmentFormController make({
  FakeCommitmentsRepository? repo,
  FakeWeekPlanRepository? plan,
  String? id,
  CommitmentFormArgs args = const CommitmentFormArgs(),
}) => CommitmentFormController(
  commitments: repo ?? FakeCommitmentsRepository(),
  scheduling: plan ?? FakeWeekPlanRepository(),
  clock: FixedClock(today),
  commitmentId: id,
  args: args,
  semesterEnd: '2026-12-12',
);

/// Sobe a tela ligada ao controlador; as ações de página vão para [calls].
Future<List<String>> pumpScreen(
  WidgetTester tester,
  CommitmentFormController c, {
  bool settle = true,
}) async {
  await usePhoneSize(tester);
  final calls = <String>[];
  await tester.pumpWidget(
    themed(
      ListenableBuilder(
        listenable: c,
        builder: (_, _) => CommitmentFormScreen(
          state: c,
          onBack: () => calls.add('back'),
          onTitle: c.setTitle,
          onCategory: c.setCategory,
          onRepeat: c.setRepeat,
          onWeekday: c.toggleWeekday,
          onUntil: (u) {
            calls.add('until:${u.name}');
            c.chooseUntil(u);
          },
          onPickDate: () => calls.add('date'),
          onStart: c.setStart,
          onEnd: c.setEnd,
          onSave: () => calls.add('save'),
          onCancel: () => calls.add('cancel'),
          onDelete: () => calls.add('delete'),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return calls;
}

PrimaryButton primary(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton));

void main() {
  testWidgets('novo: todos os campos do template', (tester) async {
    final c = make();
    await c.load();
    final calls = await pumpScreen(tester, c);
    for (final t in [
      'Novo compromisso',
      'Me conta quando você tá ocupado pra eu não marcar etapa por cima.',
      'NOME',
      'Ex.: Aula de Banco de Dados',
      'TIPO',
      'Aula',
      'Trabalho',
      'Saúde',
      'Pessoal',
      'REPETE?',
      'Toda semana',
      'Aulas, estágio, treino',
      'Só uma vez',
      'Consulta, reunião, viagem',
      'DIAS DA SEMANA',
      'ATÉ QUANDO?',
      'Sem fim',
      'Fim do semestre',
      'Escolher data',
      'Repete até você mudar ou excluir.',
      'HORÁRIO',
      '19:00',
      '21:00',
      'Salvar compromisso',
      'Cancelar',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    for (final d in [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ]) {
      expect(find.bySemanticsLabel(d), findsOneWidget, reason: d);
    }
    expect(find.text('DATA'), findsNothing);
    expect(find.text('Excluir compromisso'), findsNothing);
    expect(primary(tester).onPressed, isNull);

    await tester.enterText(find.byType(EditableText), 'Aula de BD');
    await tester.pump();
    expect(c.title, 'Aula de BD');
    expect(primary(tester).onPressed, isNotNull);

    await tester.tap(find.text('Trabalho'));
    await tester.tap(find.bySemanticsLabel('Segunda'));
    await tester.tap(find.text('Fim do semestre'));
    await tester.pump();
    expect(c.category, CommitmentCategory.trabalho);
    expect(c.weekdays, {0, 4});
    expect(
      find.text('Para de repetir depois de 12/12, no fim do semestre.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Escolher data'));
    await tester.tap(find.text('Sem fim'));
    await tester.pump();
    expect(calls, ['until:semester', 'until:date', 'until:none']);

    await tester.tap(find.text('Salvar compromisso'));
    await tester.tap(find.text('Cancelar'));
    await tester.tap(find.bySemanticsLabel('Voltar'));
    expect(calls.sublist(3), ['save', 'cancel', 'back']);

    await tester.tap(find.text('Só uma vez'));
    await tester.pumpAndSettle();
    expect(c.repeat, CommitmentRepeat.once);
    expect(find.text('DIAS DA SEMANA'), findsNothing);
    expect(find.text('DATA'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Data')));
    expect(calls.last, 'date');
    await tester.tap(find.text('Toda semana'));
    await tester.pumpAndSettle();
    expect(c.repeat, CommitmentRepeat.weekly);

    await tester.tap(find.text('19:00'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar'), findsOneWidget);
  });

  testWidgets('aviso de conflito', (tester) async {
    final c = make(
      plan: FakeWeekPlanRepository(
        weeks: {
          '2026-11-16': [block(DateTime(2026, 11, 20), 20, 0, 90)],
        },
      ),
    );
    await c.load();
    await pumpScreen(tester, c);
    expect(
      find.text('Bate com "Implementar Merge Sort" (20/11 · 20h)'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Sem estresse: quando você salvar, eu mudo essa etapa pra outro horário livre.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('novo com data: "Só uma vez" com a data', (tester) async {
    final c = make(args: const CommitmentFormArgs(date: '2026-11-24'));
    await pumpScreen(tester, c);
    expect(find.text('Ter, 24/11/2026'), findsOneWidget);
  });

  testWidgets('editar todas: "Excluir compromisso"', (tester) async {
    final c = make(
      repo: FakeCommitmentsRepository(commitment: sampleCommitment()),
      id: 'violao',
    );
    await c.load();
    final calls = await pumpScreen(tester, c);
    expect(find.text('Editar compromisso'), findsOneWidget);
    expect(find.text('Vale pra todas as semanas.'), findsOneWidget);
    expect(find.text('Salvar alterações'), findsOneWidget);
    await tester.tap(find.text('Excluir compromisso'));
    expect(calls, ['delete']);
  });

  testWidgets('só nesse dia: nome fixo, sem Tipo e Repete', (tester) async {
    final c = make(
      repo: FakeCommitmentsRepository(commitment: sampleCommitment()),
      id: 'violao',
      args: const CommitmentFormArgs(occurrenceDate: '2026-11-24'),
    );
    await c.load();
    await pumpScreen(tester, c);
    expect(
      find.text(
        'Mudando só Ter, 24/11/2026. As outras semanas continuam iguais.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aula de violão'), findsOneWidget);
    expect(find.text('NOME'), findsNothing);
    expect(find.text('TIPO'), findsNothing);
    expect(find.text('REPETE?'), findsNothing);
    expect(find.text('DATA'), findsOneWidget);
    expect(find.text('Ter, 24/11/2026'), findsOneWidget);
    expect(find.text('Salvar só nesse dia'), findsOneWidget);
    expect(find.text('Excluir compromisso'), findsNothing);
  });

  testWidgets('desse dia em diante: sem Repete, com os dias', (tester) async {
    final c = make(
      repo: FakeCommitmentsRepository(commitment: sampleCommitment()),
      id: 'violao',
      args: const CommitmentFormArgs(
        scope: CommitmentScope.following,
        occurrenceDate: '2026-11-24',
      ),
    );
    await c.load();
    await pumpScreen(tester, c);
    expect(find.text('NOME'), findsOneWidget);
    expect(find.text('REPETE?'), findsNothing);
    expect(find.text('DIAS DA SEMANA'), findsOneWidget);
  });

  testWidgets('carregando e falha na carga', (tester) async {
    final c = make(repo: FakeCommitmentsRepository(), id: 'violao')
      ..loading = true;
    await pumpScreen(tester, c, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PrimaryButton), findsNothing);

    c
      ..loading = false
      ..error = 'Compromisso não encontrado.'
      ..setTitle('');
    await tester.pump();
    expect(find.text('Compromisso não encontrado.'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsNothing);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('erro ao salvar aparece acima do botão', (tester) async {
    final c = make()..error = 'O horário precisa ser de 5 em 5 minutos.';
    await pumpScreen(tester, c);
    expect(
      find.text('O horário precisa ser de 5 em 5 minutos.'),
      findsOneWidget,
    );
  });
}
