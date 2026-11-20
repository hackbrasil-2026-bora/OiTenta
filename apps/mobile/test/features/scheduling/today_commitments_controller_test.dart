import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/goals/data/sample_goals_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_commitments_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/domain/plan.dart';
import 'package:oitenta/features/scheduling/presentation/today_controller.dart';

/// Compromissos de exemplo (hoje = qui 06/11/2025) que anotam cada
/// `GET …/occurrences` e podem falhar sob comando.
class _Commitments extends SampleCommitmentsRepository {
  final calls = <String>[];
  bool fail = false;

  @override
  Future<List<CommitmentOccurrence>> listOccurrences(String from, String to) {
    calls.add('$from..$to');
    if (fail) throw StateError('fora do ar');
    return super.listOccurrences(from, to);
  }
}

/// Plano que falha sob comando.
class _Scheduling extends SampleSchedulingRepository {
  bool fail = false;

  @override
  Future<DayPlan> getDayPlan(String date) {
    if (fail) throw StateError('fora do ar');
    return super.getDayPlan(date);
  }
}

void main() {
  late _Commitments commitments;
  late _Scheduling scheduling;

  /// Terça 11/11/2025: dentista 08:00, Lista 4 14:00, violão 19:00.
  Future<TodayController> at(DateTime now) async {
    final c = TodayController(
      scheduling,
      SampleGoalsRepository(),
      SampleGamificationRepository(),
      SessionStore(),
      FixedClock(now),
      commitments: commitments,
    );
    await c.load();
    return c;
  }

  setUp(() {
    commitments = _Commitments();
    scheduling = _Scheduling();
  });

  test('carrega as ocorrências do dia junto com o plano', () async {
    final c = await at(DateTime(2025, 11, 11, 9, 41));
    expect(commitments.calls, ['2025-11-11..2025-11-11']);
    expect(c.commitmentsError, isNull);
  });

  test(
    'a linha do tempo mistura etapas, tarefas leves e compromissos',
    () async {
      final c = await at(DateTime(2025, 11, 11, 9, 41));
      expect(c.items.map((i) => i.time), [
        '8:00',
        '11:30',
        '14:00',
        '16:00',
        '19:00',
      ]);
      expect(c.items.map((i) => i.isCommitment), [
        true,
        false,
        false,
        false,
        true,
      ]);
      expect(c.items.first.commitment!.title, 'Consulta no dentista');
      expect(c.items.first.commitment!.repetition, 'Só uma vez');
      expect(c.items.last.commitment!.repetition, 'Toda terça');
      expect(c.items[2].block!.title, 'Lista 4: frações parciais');
      // Compromisso não conta como etapa.
      expect(c.blockCount, 1);
    },
  );

  test('o compromisso cancelado aparece com "Não vai ter"', () async {
    final c = await at(DateTime(2025, 11, 7, 9, 41));
    final acad = c.items.first.commitment!;
    expect(acad.title, 'Academia');
    expect(acad.pill, 'Não vai ter');
  });

  test('erro nos compromissos não esconde as etapas', () async {
    commitments.fail = true;
    final c = await at(DateTime(2025, 11, 11, 9, 41));
    expect(c.error, isNull);
    expect(c.commitmentsError, 'Não deu pra carregar os compromissos.');
    expect(c.items.where((i) => i.isCommitment), isEmpty);
    expect(c.blockCount, 1);
  });

  test('erro no plano não esconde os compromissos', () async {
    scheduling.fail = true;
    final c = await at(DateTime(2025, 11, 11, 9, 41));
    expect(c.error, isNotNull);
    expect(c.items.where((i) => i.isCommitment).length, 2);
  });

  test('recarregar depois de uma ação mostra o estado novo', () async {
    final c = await at(DateTime(2025, 11, 11, 9, 41));
    await commitments.setOccurrence(
      'violao',
      '2025-11-11',
      const OccurrenceChange.cancel(),
    );
    commitments.fail = false;
    await c.load();
    expect(c.items.last.commitment!.cancelled, isTrue);
    // E o erro anterior some quando volta a funcionar.
    commitments.fail = true;
    await c.load();
    expect(c.commitmentsError, isNotNull);
    commitments.fail = false;
    await c.load();
    expect(c.commitmentsError, isNull);
  });
}
