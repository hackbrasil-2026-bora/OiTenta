import '../../../core/errors/app_errors.dart';
import '../../../core/format/bora_format.dart';
import '../../../core/sample/bora_sample_data.dart';
import '../domain/single_task.dart';
import 'single_tasks_repository.dart';

/// Tarefas únicas de exemplo (as do protótipo, `uniVals`), em memória.
class SampleSingleTasksRepository implements SingleTasksRepository {
  SampleSingleTasksRepository({DateTime? today})
    : _tasks = _defaults(today ?? BoraSample.today);

  final List<SingleTask> _tasks;
  int _next = 1;

  static List<SingleTask> _defaults(DateTime today) {
    String at(int days) =>
        BoraFormat.dateKey(DateTime(today.year, today.month, today.day + days));
    return [
      SingleTask(
        id: 'luz',
        title: 'Pagar a conta de luz',
        estimatedMinutes: 15,
        plannedDate: at(0),
        done: false,
      ),
      SingleTask(
        id: 'ru',
        title: 'Renovar a carteirinha do RU',
        estimatedMinutes: 15,
        plannedDate: at(0),
        done: true,
      ),
      SingleTask(
        id: 'note',
        title: 'Levar o notebook na assistência',
        estimatedMinutes: 30,
        plannedDate: at(2),
        done: false,
      ),
      SingleTask(
        id: 'livro',
        title: 'Devolver livro na biblioteca',
        estimatedMinutes: 15,
        plannedDate: at(3),
        done: false,
      ),
      SingleTask(
        id: 'guarda',
        title: 'Arrumar o guarda-roupa',
        estimatedMinutes: 60,
        plannedDate: at(5),
        done: false,
      ),
      const SingleTask(
        id: 'presente',
        title: 'Comprar presente da Júlia',
        estimatedMinutes: 30,
        plannedDate: null,
        done: false,
      ),
    ];
  }

  @override
  Future<List<SingleTask>> list() async => List.unmodifiable(_tasks);

  @override
  Future<SingleTask> create(NewSingleTask task) async {
    final created = SingleTask(
      id: 'tarefa-${_next++}',
      title: task.title,
      estimatedMinutes: task.estimatedMinutes,
      plannedDate: task.plannedDate,
      done: false,
    );
    _tasks.insert(0, created);
    return created;
  }

  @override
  Future<void> setDone(String id, {required bool done}) async {
    final i = _indexOf(id);
    _tasks[i] = _tasks[i].copyWith(done: done);
  }

  @override
  Future<void> delete(String id) async => _tasks.removeAt(_indexOf(id));

  int _indexOf(String id) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i < 0) throw NotFoundFailure('Tarefa não encontrada.');
    return i;
  }
}
