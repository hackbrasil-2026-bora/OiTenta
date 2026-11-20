import '../../../core/http/api_client.dart';
import '../domain/single_task.dart';
import 'single_tasks_repository.dart';

/// Tarefas únicas no backend real. Esqueleto do passo 0.6: o subagente M3
/// implementa cada método com testes.
class HttpSingleTasksRepository implements SingleTasksRepository {
  HttpSingleTasksRepository(this.api);

  final ApiClient api;

  @override
  Future<List<SingleTask>> list() => throw UnimplementedError();

  @override
  Future<SingleTask> create(NewSingleTask task) => throw UnimplementedError();

  @override
  Future<void> setDone(String id, {required bool done}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();
}
