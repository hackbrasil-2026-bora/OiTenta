/// Tarefa única (M53–M54): um objetivo `kind: 'single'` com 1 etapa e
/// `plannedDate` opcional (MC7). Feita = `status: 'done'` (MC10).
class SingleTask {
  const SingleTask({
    required this.id,
    required this.title,
    required this.estimatedMinutes,
    required this.plannedDate,
    required this.done,
  });

  final String id;
  final String title;
  final int estimatedMinutes;

  /// `YYYY-MM-DD` ou `null` ("Sem data").
  final String? plannedDate;
  final bool done;

  factory SingleTask.fromJson(Map<String, dynamic> json) => SingleTask(
    id: json['id'] as String,
    title: json['title'] as String,
    estimatedMinutes: json['estimatedMinutes'] as int,
    plannedDate: json['plannedDate'] as String?,
    done: json['status'] == 'done',
  );

  SingleTask copyWith({bool? done}) => SingleTask(
    id: id,
    title: title,
    estimatedMinutes: estimatedMinutes,
    plannedDate: plannedDate,
    done: done ?? this.done,
  );
}

/// Corpo do `POST /goals` de uma tarefa única.
class NewSingleTask {
  const NewSingleTask({
    required this.title,
    required this.estimatedMinutes,
    required this.plannedDate,
  });

  final String title;
  final int estimatedMinutes;
  final String? plannedDate;

  Map<String, dynamic> toJson() => {
    'title': title,
    'kind': 'single',
    'deadline': null,
    'plannedDate': plannedDate,
    'steps': [
      {'title': title, 'estimatedMinutes': estimatedMinutes, 'microSteps': []},
    ],
  };
}
