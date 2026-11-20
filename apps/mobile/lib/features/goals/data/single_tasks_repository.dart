import '../domain/single_task.dart';

/// Tarefas únicas (contrato §3, "Tarefas únicas"): objetivos `kind: single`.
abstract class SingleTasksRepository {
  /// `GET /goals?kind=single`.
  Future<List<SingleTask>> list();

  /// `POST /goals` com `kind: single` e `plannedDate`.
  Future<SingleTask> create(NewSingleTask task);

  /// `PATCH /goals/:goalId/done`.
  Future<void> setDone(String id, {required bool done});

  /// `DELETE /goals/:goalId`.
  Future<void> delete(String id);
}
