import '../../../core/http/api_client.dart';
import '../domain/single_task.dart';
import 'single_tasks_repository.dart';

/// Tarefas únicas no backend real (contrato §3, "Tarefas únicas").
class HttpSingleTasksRepository implements SingleTasksRepository {
  HttpSingleTasksRepository(this.api);

  final ApiClient api;

  static String _path(String id) => '/goals/${Uri.encodeComponent(id)}';

  @override
  Future<List<SingleTask>> list() async {
    final json =
        await api.get('/goals', query: {'kind': 'single'})
            as Map<String, dynamic>;
    return (json['goals'] as List)
        .map((g) => SingleTask.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SingleTask> create(NewSingleTask task) async {
    // `plannedDate: null` vai no corpo ("Sem data"); `deadline` nulo não vai.
    final body = task.toJson()..remove('deadline');
    final json = await api.post('/goals', body: body) as Map<String, dynamic>;
    final goal = json['goal'] as Map<String, dynamic>;
    return SingleTask(
      id: goal['id'] as String,
      title: goal['title'] as String,
      estimatedMinutes: task.estimatedMinutes,
      plannedDate: task.plannedDate,
      done: false,
    );
  }

  @override
  Future<void> setDone(String id, {required bool done}) =>
      api.patch('${_path(id)}/done', body: {'done': done});

  @override
  Future<void> delete(String id) => api.delete(_path(id));
}
