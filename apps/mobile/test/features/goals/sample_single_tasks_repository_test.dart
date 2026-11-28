import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/goals/data/sample_single_tasks_repository.dart';
import 'package:oitenta/features/goals/domain/single_task.dart';

/// Tarefas únicas de exemplo (protótipo `uniVals`, hoje = 06/11/2025).
void main() {
  late SampleSingleTasksRepository repo;
  setUp(() => repo = SampleSingleTasksRepository());

  test('as 6 tarefas do protótipo', () async {
    final all = await repo.list();
    expect(all, hasLength(6));
    expect(all.first.title, 'Pagar a conta de luz');
    expect(all.first.plannedDate, '2025-11-06');
    expect(all.where((t) => t.done).single.id, 'ru');
    expect(all.last.plannedDate, isNull);
  });

  test('criar põe no topo', () async {
    final t = await repo.create(
      const NewSingleTask(
        title: 'Pagar boleto',
        estimatedMinutes: 15,
        plannedDate: null,
      ),
    );
    expect((await repo.list()).first.id, t.id);
    expect(t.done, isFalse);
  });

  test('marcar, desmarcar e excluir', () async {
    await repo.setDone('luz', done: true);
    expect((await repo.list()).firstWhere((t) => t.id == 'luz').done, isTrue);
    await repo.setDone('luz', done: false);
    expect((await repo.list()).firstWhere((t) => t.id == 'luz').done, isFalse);
    await repo.delete('luz');
    expect((await repo.list()).any((t) => t.id == 'luz'), isFalse);
  });

  test('id inexistente → NotFoundFailure', () async {
    expect(
      () => repo.setDone('x', done: true),
      throwsA(isA<NotFoundFailure>()),
    );
    expect(() => repo.delete('x'), throwsA(isA<NotFoundFailure>()));
  });
}
