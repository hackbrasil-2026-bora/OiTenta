import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/goals/data/goals_repository.dart';
import 'package:oitenta/features/goals/data/sample_goals_repository.dart';
import 'package:oitenta/features/goals/domain/goal.dart';
import 'package:oitenta/features/goals/presentation/manual_task_controller.dart';

void main() {
  late SampleGoalsRepository repo;
  late ManualTaskController c;
  setUp(() {
    repo = SampleGoalsRepository();
    c = ManualTaskController(repo);
  });

  test('padrão: 1h, sem prazo, IA encaixa; não salva sem título', () {
    expect(c.durationChoice, '1h');
    expect(c.deadline, isNull);
    expect(c.letAiSchedule, isTrue);
    expect(c.canSave, isFalse);
  });

  test('personalizado aceita só múltiplos de 15 (P5)', () {
    c.setTitle('Revisar');
    c.chooseDuration('Personalizado');
    expect(c.showCustom, isTrue);
    c.setCustom('20');
    expect(c.canSave, isFalse);
    c.setCustom('45');
    expect(c.minutes, 45);
    expect(c.canSave, isTrue);
  });

  test('salvar cria uma tarefa única (kind single) com 1 etapa', () async {
    c.setTitle('Revisar o relatório de Algoritmos');
    c.chooseDuration('1h30');
    c.setDeadline(DateTime(2025, 11, 20));
    expect(await c.save(), isNotNull);
    final list = await repo.listGoals();
    expect(list.last.title, 'Revisar o relatório de Algoritmos');
    expect(list.last.total, 1);
    final d = await repo.getGoal(list.last.id);
    expect(d.steps.single.estimatedMinutes, 90);
  });

  test('a data escolhida vai como plannedDate, sem prazo (MC7, MC8)', () async {
    final spy = _SpyGoals();
    final m = ManualTaskController(spy);
    m.setTitle('Pagar a conta');
    m.chooseDuration('15 min');
    m.setDeadline(DateTime(2025, 11, 20));
    await m.save();
    final body = spy.sent!.toJson();
    expect(body['deadline'], isNull);
    expect(body['plannedDate'], '2025-11-20');
    expect(body['kind'], 'single');
  });

  test('sem data: plannedDate nulo (vai pra "Sem data")', () async {
    final spy = _SpyGoals();
    final m = ManualTaskController(spy);
    m.setTitle('Comprar presente');
    await m.save();
    final body = spy.sent!.toJson();
    expect(body['deadline'], isNull);
    expect(body['plannedDate'], isNull);
  });
}

class _SpyGoals extends SampleGoalsRepository implements GoalsRepository {
  NewGoal? sent;

  @override
  Future<CreateGoalResult> createGoal(NewGoal goal) {
    sent = goal;
    return super.createGoal(goal);
  }
}
