/// Compromissos (contrato §5b, decisões MC1–MC6 e MC12).
///
/// Datas locais como `YYYY-MM-DD`; horários em minutos desde 00:00
/// (múltiplos de 5, MC2); `weekday` 0 = segunda … 6 = domingo.
library;

/// O "Tipo" do formulário (M46).
enum CommitmentCategory {
  aula('Aula'),
  trabalho('Trabalho'),
  saude('Saúde'),
  pessoal('Pessoal');

  const CommitmentCategory(this.label);

  final String label;

  static CommitmentCategory fromName(String name) => values.firstWhere(
    (c) => c.name == name,
    orElse: () => throw ArgumentError.value(name, 'category'),
  );
}

/// Recorrência semanal: dias da semana e, opcionalmente, o último dia.
class CommitmentRecurrence {
  const CommitmentRecurrence({required this.weekdays, this.endDate});

  final List<int> weekdays;
  final String? endDate;

  factory CommitmentRecurrence.fromJson(Map<String, dynamic> json) =>
      CommitmentRecurrence(
        weekdays: [for (final w in json['weekdays'] as List) w as int],
        endDate: json['endDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'weekdays': weekdays,
    if (endDate != null) 'endDate': endDate,
  };
}

enum CommitmentExceptionType { cancelled, moved }

/// Exceção de um dia da série (MC1): "Não vai ter" ou "Horário alterado".
class CommitmentException {
  const CommitmentException({
    required this.date,
    required this.type,
    this.newDate,
    this.startMinute,
    this.endMinute,
  });

  final String date;
  final CommitmentExceptionType type;
  final String? newDate;
  final int? startMinute;
  final int? endMinute;

  factory CommitmentException.fromJson(Map<String, dynamic> json) =>
      CommitmentException(
        date: json['date'] as String,
        type: CommitmentExceptionType.values.byName(json['type'] as String),
        newDate: json['newDate'] as String?,
        startMinute: json['startMinute'] as int?,
        endMinute: json['endMinute'] as int?,
      );
}

/// A série (ou o compromisso único) com as exceções.
class Commitment {
  const Commitment({
    required this.id,
    required this.title,
    required this.category,
    required this.startDate,
    required this.startMinute,
    required this.endMinute,
    required this.recurrence,
    this.exceptions = const [],
  });

  final String id;
  final String title;
  final CommitmentCategory category;
  final String startDate;
  final int startMinute;
  final int endMinute;
  final CommitmentRecurrence? recurrence;
  final List<CommitmentException> exceptions;

  bool get isRecurring => recurrence != null;

  CommitmentException? exceptionOn(String date) {
    for (final e in exceptions) {
      if (e.date == date) return e;
    }
    return null;
  }

  factory Commitment.fromJson(Map<String, dynamic> json) => Commitment(
    id: json['id'] as String,
    title: json['title'] as String,
    category: CommitmentCategory.fromName(json['category'] as String),
    startDate: json['startDate'] as String,
    startMinute: json['startMinute'] as int,
    endMinute: json['endMinute'] as int,
    recurrence: json['recurrence'] == null
        ? null
        : CommitmentRecurrence.fromJson(
            json['recurrence'] as Map<String, dynamic>,
          ),
    exceptions: [
      for (final e in (json['exceptions'] as List? ?? const []))
        CommitmentException.fromJson(e as Map<String, dynamic>),
    ],
  );
}

enum OccurrenceStatus { normal, cancelled, moved }

/// Uma ocorrência num dia (`GET /scheduling/commitments/occurrences`).
class CommitmentOccurrence {
  const CommitmentOccurrence({
    required this.commitmentId,
    required this.title,
    required this.category,
    required this.date,
    required this.originalDate,
    required this.startMinute,
    required this.endMinute,
    required this.status,
    required this.recurrence,
  });

  final String commitmentId;
  final String title;
  final CommitmentCategory category;
  final String date;
  final String originalDate;
  final int startMinute;
  final int endMinute;
  final OccurrenceStatus status;
  final CommitmentRecurrence? recurrence;

  bool get isRecurring => recurrence != null;
  bool get isCancelled => status == OccurrenceStatus.cancelled;
  bool get isMoved => status == OccurrenceStatus.moved;

  factory CommitmentOccurrence.fromJson(Map<String, dynamic> json) =>
      CommitmentOccurrence(
        commitmentId: json['commitmentId'] as String,
        title: json['title'] as String,
        category: CommitmentCategory.fromName(json['category'] as String),
        date: json['date'] as String,
        originalDate: json['originalDate'] as String,
        startMinute: json['startMinute'] as int,
        endMinute: json['endMinute'] as int,
        status: OccurrenceStatus.values.byName(json['status'] as String),
        recurrence: json['recurrence'] == null
            ? null
            : CommitmentRecurrence.fromJson(
                json['recurrence'] as Map<String, dynamic>,
              ),
      );
}

/// Corpo do `POST /scheduling/commitments`.
class NewCommitment {
  const NewCommitment({
    required this.title,
    required this.category,
    required this.startDate,
    required this.startMinute,
    required this.endMinute,
    required this.recurrence,
  });

  final String title;
  final CommitmentCategory category;
  final String startDate;
  final int startMinute;
  final int endMinute;
  final CommitmentRecurrence? recurrence;

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category.name,
    'startDate': startDate,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'recurrence': recurrence?.toJson(),
  };
}

/// Escopo de edição/exclusão da série ("Todas as semanas" ou "Desse dia em
/// diante"); "Só nesse dia" é uma exceção ([OccurrenceChange]).
enum CommitmentScope { all, following }

/// Corpo do `PATCH /scheduling/commitments/:id` (só o que mudou).
class CommitmentChange {
  const CommitmentChange({
    required this.scope,
    this.fromDate,
    this.title,
    this.category,
    this.startDate,
    this.startMinute,
    this.endMinute,
    this.recurrence,
  });

  final CommitmentScope scope;
  final String? fromDate;
  final String? title;
  final CommitmentCategory? category;
  final String? startDate;
  final int? startMinute;
  final int? endMinute;
  final CommitmentRecurrence? recurrence;

  Map<String, dynamic> toJson() => {
    'scope': scope.name,
    'fromDate': ?fromDate,
    'title': ?title,
    'category': ?category?.name,
    'startDate': ?startDate,
    'startMinute': ?startMinute,
    'endMinute': ?endMinute,
    'recurrence': ?recurrence?.toJson(),
  };
}

/// Corpo do `PUT /scheduling/commitments/:id/occurrences/:date`.
class OccurrenceChange {
  const OccurrenceChange.cancel()
    : status = OccurrenceStatus.cancelled,
      newDate = null,
      startMinute = null,
      endMinute = null;

  const OccurrenceChange.move({
    required String this.newDate,
    required int this.startMinute,
    required int this.endMinute,
  }) : status = OccurrenceStatus.moved;

  final OccurrenceStatus status;
  final String? newDate;
  final int? startMinute;
  final int? endMinute;

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'newDate': ?newDate,
    'startMinute': ?startMinute,
    'endMinute': ?endMinute,
  };
}
