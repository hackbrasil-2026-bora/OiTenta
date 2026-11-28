import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/core/routes/app_routes.dart';
import 'package:oitenta/core/sample/bora_sample_data.dart';
import 'package:oitenta/features/activation/data/sample_activation_repository.dart';
import 'package:oitenta/features/auth/data/sample_auth_repository.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/goals/data/sample_goals_repository.dart';
import 'package:oitenta/features/scheduling/data/commitments_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_form_pages.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_form_screen.dart';

import '../../helpers/test_app.dart';
import 'commitment_form_fakes.dart';

/// Dados de exemplo (hoje = quinta, 6/11/2025), com outro repositório de
/// compromissos quando o teste pedir.
AppDependencies sampleDeps({CommitmentsRepository? commitments}) =>
    AppDependencies(
      auth: SampleAuthRepository(),
      scheduling: SampleSchedulingRepository(),
      goals: SampleGoalsRepository(),
      activation: SampleActivationRepository(),
      gamification: SampleGamificationRepository(),
      clock: FixedClock(BoraSample.today),
      commitments: commitments,
    );

/// Abre o formulário por cima da Semana (com `pop` disponível).
Future<void> openForm(
  WidgetTester tester,
  String location, {
  Object? extra,
}) async {
  GoRouter.of(
    tester.element(find.text('Semana').first),
  ).push(location, extra: extra);
  await tester.pumpAndSettle();
}

/// Espera o toast sumir (o timer de 2,4 s).
Future<void> waitToast(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

void main() {
  testWidgets('novo: conflito com a etapa das 19h, salva e volta pra Semana', (
    tester,
  ) async {
    final deps = await pumpApp(tester, location: AppRoutes.week);
    await openForm(tester, AppRoutes.commitmentNew);
    expect(find.byType(CommitmentFormScreen), findsOneWidget);
    expect(
      find.text('Bate com "README do projeto de Compiladores" (06/11 · 19h)'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(EditableText), 'Aula de Banco de Dados');
    await tester.pump();
    await tester.tap(find.text('Salvar compromisso'));
    await tester.pumpAndSettle();
    expect(find.text('Plano recalculado'), findsOneWidget);
    expect(
      find.text('Mudei "README do projeto de Compiladores" pra outro horário.'),
      findsOneWidget,
    );
    expect(find.byType(CommitmentFormScreen), findsNothing);
    final created = await deps.commitments.get('compromisso-1');
    expect(created.title, 'Aula de Banco de Dados');
    expect(created.recurrence!.weekdays, [3]);
    expect(created.startDate, '2025-11-06');
    await waitToast(tester);
  });

  testWidgets('novo com o dia: "Só uma vez" e escolhe outra data', (
    tester,
  ) async {
    final deps = await pumpApp(tester, location: AppRoutes.week);
    await openForm(
      tester,
      AppRoutes.commitmentNew,
      extra: const CommitmentFormArgs(date: '2025-11-07'),
    );
    expect(find.text('Sex, 07/11/2025'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Consulta');
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Data')));
    await tester.pumpAndSettle();
    expect(find.text('Data do compromisso'), findsOneWidget);
    // "Sem prazo" não muda a data.
    await tester.tap(find.text('Sem prazo'));
    await tester.pumpAndSettle();
    expect(find.text('Sex, 07/11/2025'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Data')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Qua, 12/11/2025'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Qua, 12/11/2025'), findsOneWidget);
    await tester.tap(find.text('Salvar compromisso'));
    await tester.pumpAndSettle();
    expect(find.text('Compromisso salvo'), findsOneWidget);
    expect(find.text('Não vou marcar etapas nesse horário.'), findsOneWidget);
    final created = await deps.commitments.get('compromisso-1');
    expect(created.startDate, '2025-11-12');
    expect(created.recurrence, isNull);
    await waitToast(tester);
  });

  testWidgets('"Escolher data" no "Até quando?" abre o seletor', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.week);
    await openForm(tester, AppRoutes.commitmentNew);
    await tester.tap(find.text('Escolher data'));
    await tester.pumpAndSettle();
    expect(find.text('Repete até'), findsOneWidget);
    await tester.tap(find.text('Sem prazo'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha o último dia.'), findsOneWidget);
    await tester.tap(find.text('Escolher data'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Próximo mês'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Sex, 12/12/2025'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Até 12/12'), findsOneWidget);
    expect(
      find.text('Para de repetir depois de Sex, 12/12/2025.'),
      findsOneWidget,
    );
  });

  testWidgets('editar todas: excluir e voltar pra Semana', (tester) async {
    final deps = await pumpApp(tester, location: AppRoutes.week);
    await openForm(
      tester,
      AppRoutes.commitmentEdit('violao'),
      extra: const CommitmentFormArgs(scope: CommitmentScope.all),
    );
    expect(find.text('Editar compromisso'), findsOneWidget);
    expect(find.text('Aula de violão'), findsOneWidget);
    await tester.tap(find.text('Excluir compromisso'));
    await tester.pumpAndSettle();
    expect(find.text('Compromisso excluído'), findsOneWidget);
    expect(find.text('Liberei esses horários pro seu plano.'), findsOneWidget);
    expect(find.byType(CommitmentFormScreen), findsNothing);
    await expectLater(
      deps.commitments.get('violao'),
      throwsA(isA<NotFoundFailure>()),
    );
    await waitToast(tester);
  });

  testWidgets('só nesse dia: muda a data e salva (M52)', (tester) async {
    final deps = await pumpApp(tester, location: AppRoutes.week);
    await openForm(
      tester,
      AppRoutes.commitmentEdit('violao'),
      extra: const CommitmentFormArgs(occurrenceDate: '2025-11-11'),
    );
    expect(
      find.text(
        'Mudando só Ter, 11/11/2025. As outras semanas continuam iguais.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ter, 11/11/2025'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Data')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Qua, 12/11/2025'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar só nesse dia'));
    await tester.pumpAndSettle();
    expect(find.text('Só esse dia mudou'), findsOneWidget);
    final c = await deps.commitments.get('violao');
    expect(c.exceptionOn('2025-11-11')!.newDate, '2025-11-12');
    await waitToast(tester);
  });

  testWidgets('erro ao salvar fica na tela', (tester) async {
    final repo = FakeCommitmentsRepository(
      commitment: sampleCommitment(),
      error: null,
    );
    await pumpApp(
      tester,
      location: AppRoutes.week,
      deps: sampleDeps(commitments: repo),
    );
    await openForm(tester, AppRoutes.commitmentEdit('violao'));
    repo.error = ValidationFailure('O horário precisa ser de 5 em 5 minutos.');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(
      find.text('O horário precisa ser de 5 em 5 minutos.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Excluir compromisso'));
    await tester.pumpAndSettle();
    expect(find.byType(CommitmentFormScreen), findsOneWidget);
  });

  testWidgets('falha na carga: mensagem e sem salvar', (tester) async {
    await pumpApp(
      tester,
      location: AppRoutes.week,
      deps: sampleDeps(
        commitments: FakeCommitmentsRepository(
          error: NotFoundFailure('Compromisso não encontrado.'),
        ),
      ),
    );
    await openForm(tester, AppRoutes.commitmentEdit('x'));
    expect(find.text('Compromisso não encontrado.'), findsOneWidget);
    expect(find.text('Salvar alterações'), findsNothing);
  });

  testWidgets('Cancelar e Voltar fecham sem salvar', (tester) async {
    await pumpApp(tester, location: AppRoutes.week);
    await openForm(tester, AppRoutes.commitmentNew);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(CommitmentFormScreen), findsNothing);
    await openForm(tester, AppRoutes.commitmentNew);
    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(CommitmentFormScreen), findsNothing);
  });

  testWidgets('aberto direto (sem pop): salvar e cancelar vão pra Semana', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.commitmentNew);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(CommitmentFormScreen), findsNothing);
    expect(find.text('Semana'), findsWidgets);

    GoRouter.of(
      tester.element(find.text('Semana').first),
    ).go(AppRoutes.commitmentEdit('violao'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(find.byType(CommitmentFormScreen), findsNothing);
    await waitToast(tester);
  });
}
