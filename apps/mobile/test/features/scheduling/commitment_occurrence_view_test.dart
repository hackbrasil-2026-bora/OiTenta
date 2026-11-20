import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_occurrence_view.dart';

CommitmentOccurrence _occ({
  OccurrenceStatus status = OccurrenceStatus.normal,
  CommitmentRecurrence? recurrence = const CommitmentRecurrence(weekdays: [1]),
  int start = 480,
  int end = 580,
}) => CommitmentOccurrence(
  commitmentId: 'ed',
  title: 'Aula de Estruturas de Dados',
  category: CommitmentCategory.aula,
  date: '2025-11-11',
  originalDate: '2025-11-11',
  startMinute: start,
  endMinute: end,
  status: status,
  recurrence: recurrence,
);

void main() {
  group('repetitionLabel (cpRepTxt do protótipo)', () {
    String label(List<int>? days) => commitmentRepetitionLabel(
      days == null ? null : CommitmentRecurrence(weekdays: days),
    );

    test('sem recorrência: "Só uma vez"', () {
      expect(label(null), 'Só uma vez');
    });

    test('um dia: "Toda terça"; sábado e domingo no masculino', () {
      expect(label([0]), 'Toda segunda');
      expect(label([1]), 'Toda terça');
      expect(label([4]), 'Toda sexta');
      expect(label([5]), 'Todo sábado');
      expect(label([6]), 'Todo domingo');
    });

    test('vários dias, em ordem: "Toda seg, qua e sex"', () {
      expect(label([4, 0, 2]), 'Toda seg, qua e sex');
      expect(label([5, 6]), 'Toda sáb e dom');
      expect(label([1, 3]), 'Toda ter e qui');
    });
  });

  test('horário em HH:MM 24 h', () {
    expect(commitmentClock(0), '00:00');
    expect(commitmentClock(480), '08:00');
    expect(commitmentClock(1170), '19:30');
  });

  test('cartão: hora sem zero, faixa, repetição e sem pílula', () {
    final v = CommitmentOccurrenceView(_occ());
    expect(v.time, '8:00');
    expect(v.startMinute, 480);
    expect(v.hours, '08:00–09:40');
    expect(v.title, 'Aula de Estruturas de Dados');
    expect(v.category, CommitmentCategory.aula);
    expect(v.repetition, 'Toda terça');
    expect(v.isRecurring, isTrue);
    expect(v.cancelled, isFalse);
    expect(v.moved, isFalse);
    expect(v.pill, isNull);
  });

  test('cancelado: pílula "Não vai ter"; movido: "Horário alterado"', () {
    final off = CommitmentOccurrenceView(
      _occ(status: OccurrenceStatus.cancelled),
    );
    expect(off.cancelled, isTrue);
    expect(off.pill, 'Não vai ter');
    final moved = CommitmentOccurrenceView(
      _occ(status: OccurrenceStatus.moved, start: 840, end: 1020),
    );
    expect(moved.moved, isTrue);
    expect(moved.pill, 'Horário alterado');
    expect(moved.time, '14:00');
    expect(moved.hours, '14:00–17:00');
  });

  test('único: "Só uma vez" e não recorrente', () {
    final v = CommitmentOccurrenceView(_occ(recurrence: null));
    expect(v.repetition, 'Só uma vez');
    expect(v.isRecurring, isFalse);
  });
}
