import 'dart:async';

import 'package:oitenta/features/scheduling/data/scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/availability.dart';
import 'package:oitenta/features/scheduling/domain/light_task.dart';
import 'package:oitenta/features/scheduling/domain/plan.dart';

/// Repositório falso: devolve/grava o que o teste mandar, ou falha.
class FakeSchedulingRepository implements SchedulingRepository {
  FakeSchedulingRepository({this.availability});

  WeeklyAvailability? availability;
  Object? getError;
  Object? setError;
  Completer<void>? gate;

  /// Segura o `getAvailability` até o teste liberar.
  Completer<void>? getGate;
  final List<WeeklyAvailability> saved = [];

  @override
  Future<WeeklyAvailability?> getAvailability() async {
    if (getGate != null) await getGate!.future;
    if (getError != null) throw getError!;
    return availability;
  }

  @override
  Future<SetAvailabilityResult> setAvailability(WeeklyAvailability a) async {
    saved.add(a);
    if (gate != null) await gate!.future;
    if (setError != null) throw setError!;
    return SetAvailabilityResult(
      availability: a,
      plan: const PlanSummary(totalMinutes: 0, days: 0, goals: []),
    );
  }

  @override
  Future<DayPlan> getDayPlan(String date) => throw UnimplementedError();

  @override
  Future<WeekPlan> getWeekPlan(String start) => throw UnimplementedError();

  @override
  Future<List<LightTask>> getLightTasks(String date) =>
      throw UnimplementedError();
}
