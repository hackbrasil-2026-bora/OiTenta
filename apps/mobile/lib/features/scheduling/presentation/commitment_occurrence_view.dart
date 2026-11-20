import '../domain/commitment.dart';

const _weekdayLong = [
  'segunda',
  'terça',
  'quarta',
  'quinta',
  'sexta',
  'sábado',
  'domingo',
];
const _weekdayShort = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

/// Texto da repetição, como o `cpRepTxt` do protótipo: "Só uma vez",
/// "Toda terça", "Todo sábado", "Toda seg, qua e sex".
String commitmentRepetitionLabel(CommitmentRecurrence? recurrence) {
  if (recurrence == null) return 'Só uma vez';
  final days = [...recurrence.weekdays]..sort();
  if (days.length == 1) {
    final d = days.single;
    return '${d >= 5 ? 'Todo' : 'Toda'} ${_weekdayLong[d]}';
  }
  final names = [for (final d in days) _weekdayShort[d]];
  return 'Toda ${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
}

/// `08:00` (minutos desde 00:00, 24 h).
String commitmentClock(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

/// Ocorrência pronta para o cartão (Semana e Hoje).
class CommitmentOccurrenceView {
  const CommitmentOccurrenceView(this.occurrence);

  final CommitmentOccurrence occurrence;

  int get startMinute => occurrence.startMinute;

  /// Hora da coluna da esquerda, sem zero à esquerda (`8:00`).
  String get time {
    final t = commitmentClock(occurrence.startMinute);
    return t.startsWith('0') ? t.substring(1) : t;
  }

  /// `08:00–09:00`.
  String get hours =>
      '${commitmentClock(occurrence.startMinute)}–'
      '${commitmentClock(occurrence.endMinute)}';

  String get title => occurrence.title;

  CommitmentCategory get category => occurrence.category;

  String get repetition => commitmentRepetitionLabel(occurrence.recurrence);

  bool get isRecurring => occurrence.isRecurring;

  bool get cancelled => occurrence.isCancelled;

  bool get moved => occurrence.isMoved;

  /// "Não vai ter" (cancelado) ou "Horário alterado" (movido).
  String? get pill => cancelled
      ? 'Não vai ter'
      : moved
      ? 'Horário alterado'
      : null;
}
