import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/features/scheduling/data/sample_commitments_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/domain/plan.dart';
import 'package:oitenta/features/scheduling/presentation/week_controller.dart';

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

/// Plano de exemplo que anota as semanas pedidas.
class _Scheduling extends SampleSchedulingRepository {
  final starts = <String>[];

  @override
  Future<WeekPlan> getWeekPlan(String start) {
    starts.add(start);
    return super.getWeekPlan(start);
  }
}

void main() {
  late _Scheduling scheduling;
  late _Commitments commitments;
  late WeekController c;

  setUp(() async {
    scheduling = _Scheduling();
    commitments = _Commitments();
    c = WeekController(
      scheduling,
      FixedClock(DateTime(2025, 11, 6, 9, 41)),
      commitments: commitments,
    );
    await c.load();
  });

  test('carrega as ocorrências da semana junto com o plano', () {
    expect(commitments.calls, ['2025-11-03..2025-11-09']);
    expect(c.commitmentsError, isNull);
  });

  test('sexta: etapas e compromissos misturados pela hora', () {
    c.selectDay(4);
    final items = c.dayItems;
    expect(items.map((i) => i.time), ['6:30', '10:00', '13:00', '16:00']);
    expect(items.map((i) => i.isCommitment), [true, false, true, false]);
    expect(items[0].commitment!.title, 'Academia');
    expect(items[1].block!.title, 'Diagrama de classes');
    expect(items[2].commitment!.title, 'Estágio na Lumen Tech');
    expect(items[2].commitment!.repetition, 'Toda seg, qua e sex');
    expect(items[2].commitment!.hours, '13:00–15:30');
  });

  test('o compromisso cancelado continua na lista com "Não vai ter"', () {
    c.selectDay(4);
    final acad = c.dayItems.first.commitment!;
    expect(acad.cancelled, isTrue);
    expect(acad.pill, 'Não vai ter');
  });

  test('dia sem compromisso: só as etapas (igual a dayBlocks)', () {
    expect(
      c.dayItems.map((i) => i.block!.title),
      c.dayBlocks.map((b) => b.title),
    );
  });

  test('empate de horário: a etapa vem antes do compromisso', () async {
    final tie = WeekController(
      SampleSchedulingRepository(),
      FixedClock(DateTime(2025, 11, 6, 9, 41)),
      commitments: _TieCommitments(),
    );
    await tie.load();
    expect(tie.dayItems.map((i) => i.isCommitment), [
      false,
      true,
      false,
      false,
    ]);
    expect(tie.dayItems[1].commitment!.title, 'Reunião');
  });

  test('no modo Prazos não há compromissos', () async {
    await c.setMode(CalendarMode.deadlines);
    c.selectDay(4);
    expect(c.dayItems, isEmpty);
  });

  test('o mês carrega as ocorrências das semanas que faltam', () async {
    await c.expand();
    expect(commitments.calls, [
      '2025-11-03..2025-11-09',
      '2025-10-27..2025-11-02',
      '2025-11-10..2025-11-16',
      '2025-11-17..2025-11-23',
      '2025-11-24..2025-11-30',
    ]);
    c.selectDate(DateTime(2025, 11, 11));
    expect(c.dayItems.map((i) => i.time), ['8:00', '14:00', '19:00']);
    expect(c.dayItems.first.commitment!.repetition, 'Só uma vez');
    expect(c.dayItems.last.commitment!.repetition, 'Toda terça');
  });

  test('erro nos compromissos não esconde as etapas', () async {
    final failing = _Commitments()..fail = true;
    final w = WeekController(
      SampleSchedulingRepository(),
      FixedClock(DateTime(2025, 11, 6, 9, 41)),
      commitments: failing,
    );
    await w.load();
    expect(w.error, isNull);
    expect(w.commitmentsError, 'Não deu pra carregar os compromissos.');
    expect(w.dayItems.map((i) => i.block!.title), [
      'Diagrama de casos de uso',
      'Lista 3: integrais por partes',
      'README do projeto de Compiladores',
    ]);
  });

  test('reload: busca de novo o plano e os compromissos', () async {
    c.selectDay(4);
    await commitments.setOccurrence(
      'est',
      '2025-11-07',
      const OccurrenceChange.cancel(),
    );
    await c.reload();
    expect(scheduling.starts, ['2025-11-03', '2025-11-03']);
    expect(commitments.calls.length, 2);
    expect(c.dayItems[2].commitment!.cancelled, isTrue);
    // O dia escolhido continua o mesmo.
    expect(c.selectedIndex, 4);
  });

  test('reload no mês recarrega todas as semanas do mês', () async {
    await c.expand();
    commitments.calls.clear();
    await c.reload();
    expect(commitments.calls.length, 5);
  });

  test(
    'reload com erro nos compromissos mostra a mensagem; depois some',
    () async {
      commitments.fail = true;
      await c.reload();
      expect(c.commitmentsError, isNotNull);
      expect(c.dayBlocks, isNotEmpty);
      commitments.fail = false;
      await c.reload();
      expect(c.commitmentsError, isNull);
    },
  );

  test('sem repositório de compromissos: só as etapas', () async {
    final w = WeekController(
      SampleSchedulingRepository(),
      FixedClock(DateTime(2025, 11, 6, 9, 41)),
    );
    await w.load();
    w.selectDay(4);
    expect(w.dayItems.every((i) => !i.isCommitment), isTrue);
  });

  test('selectedDateKey: a data do dia escolhido (para o "+ Compromisso")', () {
    expect(c.selectedDateKey, '2025-11-06');
    c.selectDay(1);
    expect(c.selectedDateKey, '2025-11-04');
  });

  test(
    'erro no plano: mensagem da semana (os compromissos não carregam)',
    () async {
      final w = WeekController(
        _FailingScheduling(),
        FixedClock(DateTime(2025, 11, 6, 9, 41)),
        commitments: _Commitments(),
      );
      await w.load();
      expect(w.error, 'Não deu pra carregar a semana.');
      expect(w.loading, isFalse);
      expect(w.dayItems, isEmpty);
    },
  );

  test('descartado no meio do load/reload: não avisa ninguém', () async {
    final slow = _SlowScheduling();
    final w = WeekController(
      slow,
      FixedClock(DateTime(2025, 11, 6, 9, 41)),
      commitments: _Commitments(),
    );
    final loading = w.load();
    w.dispose();
    slow.hold.complete();
    await loading;

    final slow2 = _SlowScheduling();
    final w2 = WeekController(slow2, FixedClock(DateTime(2025, 11, 6, 9, 41)));
    slow2.hold.complete();
    await w2.load();
    slow2.hold = Completer<void>();
    final reloading = w2.reload();
    w2.dispose();
    slow2.hold.complete();
    await reloading;
  });
}

class _SlowScheduling extends SampleSchedulingRepository {
  Completer<void> hold = Completer<void>();

  @override
  Future<WeekPlan> getWeekPlan(String start) async {
    await hold.future;
    return super.getWeekPlan(start);
  }
}

class _FailingScheduling extends SampleSchedulingRepository {
  @override
  Future<WeekPlan> getWeekPlan(String start) async =>
      throw StateError('fora do ar');
}

/// Um compromisso às 10:00 na quinta 06/11, mesmo horário do "Diagrama".
class _TieCommitments extends SampleCommitmentsRepository {
  @override
  Future<List<CommitmentOccurrence>> listOccurrences(
    String from,
    String to,
  ) async => const [
    CommitmentOccurrence(
      commitmentId: 'r',
      title: 'Reunião',
      category: CommitmentCategory.trabalho,
      date: '2025-11-06',
      originalDate: '2025-11-06',
      startMinute: 600,
      endMinute: 660,
      status: OccurrenceStatus.normal,
      recurrence: null,
    ),
  ];
}
