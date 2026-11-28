import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/features/activation/data/sample_activation_repository.dart';
import 'package:oitenta/features/auth/data/sample_auth_repository.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/goals/data/sample_goals_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_commitments_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_form_pages.dart';

import '../../helpers/test_app.dart';

class _Commitments extends SampleCommitmentsRepository {
  int reads = 0;
  bool fail = false;

  @override
  Future<List<CommitmentOccurrence>> listOccurrences(String from, String to) {
    reads++;
    if (fail) throw StateError('fora do ar');
    return super.listOccurrences(from, to);
  }
}

/// Hoje = terça 11/11/2025: dentista 08:00 e violão 19:00 (C6 = b).
AppDependencies _deps(_Commitments commitments) => AppDependencies(
  auth: SampleAuthRepository(),
  scheduling: SampleSchedulingRepository(),
  goals: SampleGoalsRepository(),
  activation: SampleActivationRepository(),
  gamification: SampleGamificationRepository(),
  clock: FixedClock(DateTime(2025, 11, 11, 9, 41)),
  commitments: commitments,
);

void main() {
  late _Commitments commitments;

  setUp(() => commitments = _Commitments());

  testWidgets('Hoje mostra os compromissos do dia na linha do tempo', (
    tester,
  ) async {
    await pumpApp(tester, location: '/hoje', deps: _deps(commitments));
    expect(find.text('Consulta no dentista'), findsOneWidget);
    expect(find.text('Compromisso · Só uma vez'), findsOneWidget);
    expect(find.text('08:00–09:00'), findsOneWidget);
    expect(find.text('8:00'), findsOneWidget);
    await tester.ensureVisible(find.text('Aula de violão'));
    expect(find.text('Compromisso · Toda terça'), findsOneWidget);
    expect(find.text('Lista 4: frações parciais'), findsOneWidget);
  });

  testWidgets('tocar abre o mesmo sheet; a ação recarrega o Hoje', (
    tester,
  ) async {
    await pumpApp(tester, location: '/hoje', deps: _deps(commitments));
    final violao = find.bySemanticsLabel('Opções de Aula de violão');
    await tester.ensureVisible(violao);
    await tester.tap(violao);
    await tester.pumpAndSettle();
    expect(find.text('Ter, 11/11/2025 · 19:00–20:00'), findsOneWidget);

    await tester.tap(find.text('Não vai ter nesse dia'));
    await tester.pumpAndSettle();
    expect(find.text('Horário liberado'), findsOneWidget);
    expect(find.text('Não vai ter'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Editar no Hoje abre o formulário e recarrega ao voltar', (
    tester,
  ) async {
    await pumpApp(tester, location: '/hoje', deps: _deps(commitments));
    await tester.tap(find.bySemanticsLabel('Opções de Consulta no dentista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    final page = tester.widget<CommitmentFormPage>(
      find.byType(CommitmentFormPage),
    );
    expect(page.commitmentId, 'dent');
    expect(page.args.scope, CommitmentScope.all);

    final before = commitments.reads;
    GoRouter.of(tester.element(find.byType(CommitmentFormPage))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Vamos começar?'), findsOneWidget);
    expect(commitments.reads, greaterThan(before));
  });

  testWidgets('erro nos compromissos: mensagem curta e as etapas ficam', (
    tester,
  ) async {
    commitments.fail = true;
    await pumpApp(tester, location: '/hoje', deps: _deps(commitments));
    expect(find.text('Não deu pra carregar os compromissos.'), findsOneWidget);
    expect(find.text('Lista 4: frações parciais'), findsOneWidget);
  });
}
