import 'dart:async';

import 'package:oitenta/features/scheduling/data/commitments_repository.dart';
import 'package:oitenta/features/scheduling/data/scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/availability.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/domain/light_task.dart';
import 'package:oitenta/features/scheduling/domain/plan.dart';

/// Repositório de compromissos falso: grava as chamadas e responde com
/// [commitment] (ou lança [error]).
class FakeCommitmentsRepository implements CommitmentsRepository {
  FakeCommitmentsRepository({this.commitment, this.error});

  Commitment? commitment;
  Object? error;

  /// Quando não é `null`, as mutações esperam este completer.
  Completer<void>? gate;

  final List<String> calls = [];
  NewCommitment? created;
  CommitmentChange? change;
  OccurrenceChange? occurrence;
  String? occurrenceDate;
  CommitmentScope? deletedScope;

  Future<Commitment> _answer() async {
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return commitment ?? sampleCommitment();
  }

  @override
  Future<Commitment> create(NewCommitment c) {
    calls.add('create');
    created = c;
    return _answer();
  }

  @override
  Future<Commitment> get(String id) {
    calls.add('get:$id');
    return _answer();
  }

  @override
  Future<List<CommitmentOccurrence>> listOccurrences(String from, String to) =>
      throw UnimplementedError();

  @override
  Future<Commitment> update(String id, CommitmentChange c) {
    calls.add('update:$id');
    change = c;
    return _answer();
  }

  @override
  Future<void> delete(
    String id, {
    required CommitmentScope scope,
    String? fromDate,
  }) async {
    calls.add('delete:$id');
    deletedScope = scope;
    await _answer();
  }

  @override
  Future<Commitment> setOccurrence(String id, String date, OccurrenceChange c) {
    calls.add('setOccurrence:$id');
    occurrenceDate = date;
    occurrence = c;
    return _answer();
  }

  @override
  Future<Commitment> clearOccurrence(String id, String date) =>
      throw UnimplementedError();
}

/// Só o `getWeekPlan` importa para o formulário (aviso de conflito, MC5).
class FakeWeekPlanRepository implements SchedulingRepository {
  FakeWeekPlanRepository({Map<String, List<PlanBlock>>? weeks, this.fail})
    : weeks = weeks ?? {};

  final Map<String, List<PlanBlock>> weeks;
  bool? fail;
  final List<String> requested = [];

  @override
  Future<WeekPlan> getWeekPlan(String start) async {
    requested.add(start);
    if (fail == true) throw StateError('sem rede');
    final blocks = weeks[start] ?? const <PlanBlock>[];
    return WeekPlan(
      days: [
        DayPlan(date: start, blocks: blocks, usedMinutes: 0, limitMinutes: 240),
      ],
    );
  }

  @override
  Future<WeeklyAvailability?> getAvailability() => throw UnimplementedError();

  @override
  Future<SetAvailabilityResult> setAvailability(WeeklyAvailability a) =>
      throw UnimplementedError();

  @override
  Future<DayPlan> getDayPlan(String date) => throw UnimplementedError();

  @override
  Future<List<LightTask>> getLightTasks(String date) =>
      throw UnimplementedError();
}

/// Bloco planejado em [day] (local) das [startH]:[startM] por [minutes].
PlanBlock block(
  DateTime day,
  int startH,
  int startM,
  int minutes, {
  String title = 'Implementar Merge Sort',
  String status = 'planned',
}) {
  final start = DateTime(day.year, day.month, day.day, startH, startM);
  return PlanBlock(
    id: 'b-$title-${start.toIso8601String()}',
    start: start.toUtc(),
    end: start.add(Duration(minutes: minutes)).toUtc(),
    status: status,
    goalId: 'g1',
    goalTitle: 'Algoritmos',
    colorIndex: 0,
    stepId: 's1',
    stepTitle: title,
  );
}

/// Aula de violão, toda terça e quinta, 19:00–20:00, sem fim.
Commitment sampleCommitment({
  CommitmentRecurrence? recurrence = const CommitmentRecurrence(
    weekdays: [1, 3],
  ),
  String startDate = '2026-11-02',
  List<CommitmentException> exceptions = const [],
}) => Commitment(
  id: 'violao',
  title: 'Aula de violão',
  category: CommitmentCategory.pessoal,
  startDate: startDate,
  startMinute: 1140,
  endMinute: 1200,
  recurrence: recurrence,
  exceptions: exceptions,
);
