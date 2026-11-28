import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/goals/domain/single_task.dart';

/// Tarefa única (MC7, MC8) × item de `GET /goals?kind=single`.
void main() {
  test('fromJson de um item de GET /goals', () {
    final t = SingleTask.fromJson({
      'id': 'g1',
      'title': 'Pagar a conta de luz',
      'kind': 'single',
      'deadline': null,
      'plannedDate': '2025-11-06',
      'estimatedMinutes': 15,
      'status': 'active',
      'progressPct': 0,
      'done': 0,
      'total': 1,
    });
    expect(t.id, 'g1');
    expect(t.title, 'Pagar a conta de luz');
    expect(t.estimatedMinutes, 15);
    expect(t.plannedDate, '2025-11-06');
    expect(t.done, isFalse);
  });

  test('status done = feita; sem data = plannedDate nulo', () {
    final t = SingleTask.fromJson({
      'id': 'g2',
      'title': 'Comprar presente',
      'kind': 'single',
      'plannedDate': null,
      'estimatedMinutes': 30,
      'status': 'done',
    });
    expect(t.done, isTrue);
    expect(t.plannedDate, isNull);
  });

  test('copyWith troca só o done', () {
    const t = SingleTask(
      id: 'g',
      title: 'x',
      estimatedMinutes: 60,
      plannedDate: null,
      done: false,
    );
    final d = t.copyWith(done: true);
    expect(d.done, isTrue);
    expect(d.id, 'g');
    expect(d.estimatedMinutes, 60);
  });

  test('NewSingleTask.toJson monta o POST /goals de kind single', () {
    const n = NewSingleTask(
      title: 'Pagar a conta',
      estimatedMinutes: 15,
      plannedDate: '2025-11-06',
    );
    expect(n.toJson(), {
      'title': 'Pagar a conta',
      'kind': 'single',
      'deadline': null,
      'plannedDate': '2025-11-06',
      'steps': [
        {'title': 'Pagar a conta', 'estimatedMinutes': 15, 'microSteps': []},
      ],
    });
  });
}
