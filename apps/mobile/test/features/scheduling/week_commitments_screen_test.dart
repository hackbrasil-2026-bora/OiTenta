import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/core/sample/bora_sample_data.dart';
import 'package:oitenta/features/activation/data/sample_activation_repository.dart';
import 'package:oitenta/features/auth/data/sample_auth_repository.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/goals/data/sample_goals_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_commitments_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_form_pages.dart';

import '../../helpers/test_app.dart';

/// Compromissos de exemplo que contam as leituras e podem falhar.
class _Commitments extends SampleCommitmentsRepository {
  int reads = 0;
  bool fail = false;

  @override
  Future<List<CommitmentOccurrence>> listOccurrences(String from, String to) {
    reads++;
    if (fail) throw StateError('fora do ar');
    return super.listOccurrences(from, to);
  }

  bool failMutation = false;

  @override
  Future<Commitment> setOccurrence(
    String id,
    String date,
    OccurrenceChange change,
  ) {
    if (failMutation) throw StateError('fora do ar');
    return super.setOccurrence(id, date, change);
  }
}

AppDependencies _deps(_Commitments commitments) => AppDependencies(
  auth: SampleAuthRepository(),
  scheduling: SampleSchedulingRepository(),
  goals: SampleGoalsRepository(),
  activation: SampleActivationRepository(),
  gamification: SampleGamificationRepository(),
  clock: FixedClock(BoraSample.today),
  commitments: commitments,
);

/// Sai do formulário (placeholder do M2) como o "voltar" do app.
Future<void> _leaveForm(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(CommitmentFormPage))).pop();
  await tester.pumpAndSettle();
}

CommitmentFormPage _form(WidgetTester tester) =>
    tester.widget<CommitmentFormPage>(find.byType(CommitmentFormPage));

/// Espera o toast sumir (o timer dele não pode ficar pendente).
Future<void> _settleToast(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

void main() {
  late _Commitments commitments;

  setUp(() => commitments = _Commitments());

  Future<void> openFriday(WidgetTester tester) async {
    await pumpApp(tester, location: '/semana', deps: _deps(commitments));
    await tester.tap(find.bySemanticsLabel('Sex 7'));
    await tester.pumpAndSettle();
  }

  testWidgets('"+ Compromisso" só em Execução; abre o formulário com a data '
      'do dia e recarrega ao voltar', (tester) async {
    await pumpApp(tester, location: '/semana', deps: _deps(commitments));
    expect(find.text('Compromisso'), findsOneWidget);

    await tester.tap(find.text('Prazos'));
    await tester.pumpAndSettle();
    expect(find.text('Compromisso'), findsNothing);
    await tester.tap(find.text('Execução'));
    await tester.pumpAndSettle();

    final before = commitments.reads;
    await tester.tap(find.text('Compromisso'));
    await tester.pumpAndSettle();
    expect(find.text('Novo compromisso'), findsOneWidget);
    expect(_form(tester).args.date, '2025-11-06');
    expect(_form(tester).commitmentId, isNull);

    await _leaveForm(tester);
    expect(find.text('HOJE, QUINTA, 6 DE NOVEMBRO'), findsOneWidget);
    expect(commitments.reads, greaterThan(before));
  });

  testWidgets('sexta: cartões dos compromissos entre as etapas', (
    tester,
  ) async {
    await openFriday(tester);
    expect(find.text('Academia'), findsOneWidget);
    expect(find.text('Não vai ter'), findsOneWidget);
    expect(find.text('Estágio na Lumen Tech'), findsOneWidget);
    expect(find.text('Compromisso · Toda seg, qua e sex'), findsNWidgets(2));
    expect(find.text('13:00–15:30'), findsOneWidget);
    expect(find.text('06:30–07:30'), findsOneWidget);
    expect(find.text('6:30'), findsOneWidget);
    expect(find.text('Diagrama de classes'), findsOneWidget);
    expect(find.text('Nada planejado pra esse dia.'), findsNothing);
  });

  testWidgets('sheet: "Não vai ter nesse dia" libera o horário', (
    tester,
  ) async {
    await openFriday(tester);
    await tester.tap(find.bySemanticsLabel('Opções de Estágio na Lumen Tech'));
    await tester.pumpAndSettle();
    expect(find.text('Sex, 07/11/2025 · 13:00–15:30'), findsOneWidget);
    expect(find.text('Toda seg, qua e sex'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Horário, nome ou dias'), findsOneWidget);
    expect(find.text('Não vai ter nesse dia'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);

    await tester.tap(find.text('Não vai ter nesse dia'));
    await tester.pumpAndSettle();
    expect(find.text('Horário liberado'), findsOneWidget);
    expect(
      find.text('Só nesse dia. Posso encaixar etapas aí.'),
      findsOneWidget,
    );
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Não vai ter'), findsNWidgets(2));
    await _settleToast(tester);
  });

  testWidgets('sheet do dia cancelado: "Vai ter sim" devolve o horário', (
    tester,
  ) async {
    await openFriday(tester);
    await tester.tap(find.bySemanticsLabel('Opções de Academia'));
    await tester.pumpAndSettle();
    expect(find.text('Não vai ter nesse dia'), findsOneWidget);
    expect(
      find.text(
        'Liberei esse horário só nesse dia. As outras semanas continuam iguais.',
      ),
      findsOneWidget,
    );
    expect(find.text('Editar'), findsNothing);

    await tester.tap(find.text('Vai ter sim'));
    await tester.pumpAndSettle();
    expect(find.text('Voltou pra agenda'), findsOneWidget);
    expect(find.text('Não vai ter'), findsNothing);
    await _settleToast(tester);
  });

  testWidgets('Excluir → "Excluir qual?" → Todas as semanas', (tester) async {
    await openFriday(tester);
    await tester.tap(find.bySemanticsLabel('Opções de Estágio na Lumen Tech'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir qual?'), findsOneWidget);
    expect(find.text('Só nesse dia'), findsOneWidget);
    expect(find.text('Sex, 07/11/2025'), findsOneWidget);
    expect(
      find.text('A partir de 07/11. Antes fica como era.'),
      findsOneWidget,
    );
    expect(find.text('A série inteira'), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);

    await tester.tap(find.text('Todas as semanas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Compromisso excluído'), findsOneWidget);
    expect(find.text('Liberei esses horários pro seu plano.'), findsOneWidget);
    expect(find.text('Estágio na Lumen Tech'), findsNothing);
    await _settleToast(tester);
  });

  testWidgets('Voltar no passo de escopo volta ao menu', (tester) async {
    await openFriday(tester);
    await tester.tap(find.bySemanticsLabel('Opções de Estágio na Lumen Tech'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar qual?'), findsOneWidget);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar qual?'), findsNothing);
    expect(find.text('Não vai ter nesse dia'), findsOneWidget);
  });

  testWidgets('Editar → Só nesse dia → formulário com a data da ocorrência', (
    tester,
  ) async {
    await openFriday(tester);
    await tester.tap(find.bySemanticsLabel('Opções de Estágio na Lumen Tech'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar compromisso'), findsOneWidget);
    expect(_form(tester).commitmentId, 'est');
    expect(_form(tester).args.scope, isNull);
    expect(_form(tester).args.occurrenceDate, '2025-11-07');

    final before = commitments.reads;
    await _leaveForm(tester);
    expect(find.text('SEXTA, 7 DE NOVEMBRO'), findsOneWidget);
    expect(commitments.reads, greaterThan(before));
  });

  testWidgets('compromisso único (ter 11, pelo mês): Editar abre todas', (
    tester,
  ) async {
    await pumpApp(tester, location: '/semana', deps: _deps(commitments));
    await tester.tap(
      find.bySemanticsLabel('Arraste pra expandir ou recolher o calendário'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ter 11'));
    await tester.pumpAndSettle();
    expect(find.text('Compromisso · Só uma vez'), findsOneWidget);
    expect(find.text('Compromisso · Toda terça'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Opções de Consulta no dentista'));
    await tester.pumpAndSettle();
    expect(find.text('Data, horário ou nome'), findsOneWidget);
    expect(find.text('Tirar da sua agenda'), findsOneWidget);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(_form(tester).commitmentId, 'dent');
    expect(_form(tester).args.scope, CommitmentScope.all);
  });

  testWidgets('dia movido (qua 12): pílula e "Voltar pro horário normal"', (
    tester,
  ) async {
    await pumpApp(tester, location: '/semana', deps: _deps(commitments));
    await tester.tap(
      find.bySemanticsLabel('Arraste pra expandir ou recolher o calendário'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Qua 12'));
    await tester.pumpAndSettle();
    expect(find.text('Horário alterado'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Opções de Estágio na Lumen Tech'));
    await tester.pumpAndSettle();
    expect(
      find.text('Horário alterado · normal é 13:00–15:30'),
      findsOneWidget,
    );
    await tester.tap(find.text('Voltar pro horário normal'));
    await tester.pumpAndSettle();
    expect(find.text('Horário normal de volta'), findsOneWidget);
    expect(find.text('Horário alterado'), findsNothing);
    await _settleToast(tester);
  });

  testWidgets('erro nos compromissos: mensagem curta e as etapas ficam', (
    tester,
  ) async {
    commitments.fail = true;
    await pumpApp(tester, location: '/semana', deps: _deps(commitments));
    expect(find.text('Não deu pra carregar os compromissos.'), findsOneWidget);
    expect(find.text('Diagrama de casos de uso'), findsOneWidget);
  });

  testWidgets('Excluir desse dia em diante → "Encerrado"', (tester) async {
    await openFriday(tester);
    await tester.tap(find.bySemanticsLabel('Opções de Estágio na Lumen Tech'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desse dia em diante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Encerrado'), findsOneWidget);
    expect(find.text('O último foi em 06/11.'), findsOneWidget);
    expect(find.text('Estágio na Lumen Tech'), findsNothing);
    await _settleToast(tester);
  });

  testWidgets('erro na ação: o sheet fica aberto com a mensagem', (
    tester,
  ) async {
    commitments.failMutation = true;
    await openFriday(tester);
    await tester.tap(find.bySemanticsLabel('Opções de Estágio na Lumen Tech'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não vai ter nesse dia'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não deu pra salvar agora. Tenta de novo.'),
      findsOneWidget,
    );
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Horário liberado'), findsNothing);
  });
}
