import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/goals/data/goals_repository.dart';
import 'package:oitenta/features/goals/data/sample_goals_repository.dart';
import 'package:oitenta/features/goals/domain/goal.dart';
import 'package:oitenta/features/goals/presentation/goals_controller.dart';

/// Lista fixa de `GET /goals` (o resto não é usado pela lista).
class _ListRepo implements GoalsRepository {
  _ListRepo(this.goals);

  final List<GoalSummary> goals;

  @override
  Future<List<GoalSummary>> listGoals() async => goals;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoalSummary _summary(String id, {String? kind}) => GoalSummary.fromJson({
  'id': id,
  'title': 'Objetivo $id',
  'deadline': null,
  'colorIndex': 1,
  'progressPct': 0,
  'done': 0,
  'total': 1,
  'status': 'active',
  'slackDays': null,
  'kind': ?kind,
});

void main() {
  test('lista os objetivos com %, meta e o subtítulo', () async {
    final c = GoalsController(SampleGoalsRepository());
    await c.load();
    expect(c.subtitle, '3 ativos · próxima entrega 20/11');
    expect(c.items.map((i) => i.percentLabel), ['62%', '25%', '10%']);
    expect(c.items.first.meta, 'Entrega 20/11 · folga de 2 dias');
    expect(c.items[1].meta, 'Entrega 27/11 · folga de 3 dias');
    expect(c.items[2].meta, 'Sem prazo');
    expect(c.items.first.id, 'goal-eng');
  });

  test('MC8: tarefa única (kind single) não aparece em Objetivos', () async {
    final c = GoalsController(
      _ListRepo([
        _summary('g1', kind: 'goal'),
        _summary('t1', kind: 'single'),
        _summary('g2'),
      ]),
    );
    await c.load();
    expect(c.items.map((i) => i.id), ['g1', 'g2']);
    expect(c.subtitle, '2 ativos');
  });

  test(
    'MC8: tarefa criada pelo "Preencher à mão" fica fora de Objetivos',
    () async {
      final repo = SampleGoalsRepository();
      await repo.createGoal(
        const NewGoal(
          title: 'Lavar a louça',
          deadline: null,
          kind: 'single',
          steps: [NewStep(title: 'Lavar a louça', estimatedMinutes: 15)],
        ),
      );
      expect((await repo.listGoals()).last.kind, 'single');
      final c = GoalsController(repo);
      await c.load();
      expect(c.items.map((i) => i.title), isNot(contains('Lavar a louça')));
      expect(c.items, hasLength(3));
    },
  );
}
