import '../../../core/errors/app_errors.dart';
import '../../../core/format/bora_format.dart';
import '../../../core/sample/bora_sample_data.dart';
import '../domain/commitment.dart';
import 'commitments_repository.dart';

/// Compromissos de exemplo (os do protótipo, `cpDefaults`), em memória, com a
/// mesma regra do backend: série semanal + exceções por dia (MC1, MC12).
class SampleCommitmentsRepository implements CommitmentsRepository {
  SampleCommitmentsRepository({DateTime? today})
    : _items = _defaults(today ?? BoraSample.today);

  final List<Commitment> _items;
  int _next = 1;

  static List<Commitment> _defaults(DateTime today) {
    final t = DateTime(today.year, today.month, today.day);
    String at(int days) => BoraFormat.dateKey(t.add(Duration(days: days)));
    final since = at(0);
    return [
      Commitment(
        id: 'ed',
        title: 'Aula de Estruturas de Dados',
        category: CommitmentCategory.aula,
        startDate: since,
        startMinute: 480,
        endMinute: 580,
        recurrence: const CommitmentRecurrence(
          weekdays: [0, 2],
          endDate: '2025-12-12',
        ),
      ),
      Commitment(
        id: 'est',
        title: 'Estágio na Lumen Tech',
        category: CommitmentCategory.trabalho,
        startDate: since,
        startMinute: 780,
        endMinute: 930,
        recurrence: const CommitmentRecurrence(weekdays: [0, 2, 4]),
        exceptions: [
          CommitmentException(
            date: at(6),
            type: CommitmentExceptionType.moved,
            newDate: at(6),
            startMinute: 840,
            endMinute: 1020,
          ),
        ],
      ),
      Commitment(
        id: 'violao',
        title: 'Aula de violão',
        category: CommitmentCategory.pessoal,
        startDate: since,
        startMinute: 1140,
        endMinute: 1200,
        recurrence: const CommitmentRecurrence(weekdays: [1]),
      ),
      Commitment(
        id: 'acad',
        title: 'Academia',
        category: CommitmentCategory.saude,
        startDate: since,
        startMinute: 390,
        endMinute: 450,
        recurrence: const CommitmentRecurrence(weekdays: [0, 2, 4]),
        exceptions: [
          CommitmentException(
            date: at(1),
            type: CommitmentExceptionType.cancelled,
          ),
        ],
      ),
      Commitment(
        id: 'dent',
        title: 'Consulta no dentista',
        category: CommitmentCategory.pessoal,
        startDate: at(5),
        startMinute: 480,
        endMinute: 540,
        recurrence: null,
      ),
    ];
  }

  static DateTime _parse(String date) => DateTime.parse(date);

  static String _key(DateTime d) => BoraFormat.dateKey(d);

  static String _shift(String date, int days) =>
      _key(_parse(date).add(Duration(days: days)));

  /// 0 = segunda … 6 = domingo.
  static int _weekday(String date) => _parse(date).weekday - 1;

  static bool _occursOn(Commitment c, String date) {
    final r = c.recurrence;
    if (r == null) return date == c.startDate;
    if (date.compareTo(c.startDate) < 0) return false;
    if (r.endDate != null && date.compareTo(r.endDate!) > 0) return false;
    return r.weekdays.contains(_weekday(date));
  }

  @override
  Future<List<CommitmentOccurrence>> listOccurrences(
    String from,
    String to,
  ) async {
    final out = <CommitmentOccurrence>[];
    CommitmentOccurrence occ(
      Commitment c,
      String date,
      String original,
      int start,
      int end,
      OccurrenceStatus status,
    ) => CommitmentOccurrence(
      commitmentId: c.id,
      title: c.title,
      category: c.category,
      date: date,
      originalDate: original,
      startMinute: start,
      endMinute: end,
      status: status,
      recurrence: c.recurrence,
    );
    for (final c in _items) {
      for (var d = from; d.compareTo(to) <= 0; d = _shift(d, 1)) {
        if (!_occursOn(c, d)) continue;
        final e = c.exceptionOn(d);
        if (e == null) {
          out.add(
            occ(c, d, d, c.startMinute, c.endMinute, OccurrenceStatus.normal),
          );
        } else if (e.type == CommitmentExceptionType.cancelled) {
          out.add(
            occ(
              c,
              d,
              d,
              c.startMinute,
              c.endMinute,
              OccurrenceStatus.cancelled,
            ),
          );
        }
      }
      for (final e in c.exceptions) {
        if (e.type != CommitmentExceptionType.moved) continue;
        final d = e.newDate!;
        if (d.compareTo(from) < 0 || d.compareTo(to) > 0) continue;
        out.add(
          occ(
            c,
            d,
            e.date,
            e.startMinute!,
            e.endMinute!,
            OccurrenceStatus.moved,
          ),
        );
      }
    }
    out.sort(
      (a, b) => a.date != b.date
          ? a.date.compareTo(b.date)
          : a.startMinute.compareTo(b.startMinute),
    );
    return out;
  }

  @override
  Future<Commitment> create(NewCommitment n) async {
    final c = Commitment(
      id: 'compromisso-${_next++}',
      title: n.title,
      category: n.category,
      startDate: n.startDate,
      startMinute: n.startMinute,
      endMinute: n.endMinute,
      recurrence: n.recurrence,
    );
    _items.add(c);
    return c;
  }

  @override
  Future<Commitment> get(String id) async => _items[_indexOf(id)];

  Commitment _apply(Commitment c, CommitmentChange ch, {String? id}) =>
      Commitment(
        id: id ?? c.id,
        title: ch.title ?? c.title,
        category: ch.category ?? c.category,
        startDate: ch.startDate ?? c.startDate,
        startMinute: ch.startMinute ?? c.startMinute,
        endMinute: ch.endMinute ?? c.endMinute,
        recurrence: ch.recurrence ?? c.recurrence,
        exceptions: c.exceptions,
      );

  /// A série que termina no dia anterior a [date], ou `null` se ficar vazia.
  Commitment? _endingBefore(Commitment c, String date) {
    if (c.recurrence == null || date.compareTo(c.startDate) <= 0) return null;
    return Commitment(
      id: c.id,
      title: c.title,
      category: c.category,
      startDate: c.startDate,
      startMinute: c.startMinute,
      endMinute: c.endMinute,
      recurrence: CommitmentRecurrence(
        weekdays: c.recurrence!.weekdays,
        endDate: _shift(date, -1),
      ),
      exceptions: [
        for (final e in c.exceptions)
          if (e.date.compareTo(date) < 0) e,
      ],
    );
  }

  @override
  Future<Commitment> update(String id, CommitmentChange change) async {
    final i = _indexOf(id);
    final old = _items[i];
    if (change.scope == CommitmentScope.all) {
      return _items[i] = _apply(old, change);
    }
    final from = change.fromDate!;
    final next = Commitment(
      id: 'compromisso-${_next++}',
      title: change.title ?? old.title,
      category: change.category ?? old.category,
      startDate: from,
      startMinute: change.startMinute ?? old.startMinute,
      endMinute: change.endMinute ?? old.endMinute,
      recurrence: change.recurrence ?? old.recurrence,
      exceptions: [
        for (final e in old.exceptions)
          if (e.date.compareTo(from) >= 0) e,
      ],
    );
    final prev = _endingBefore(old, from);
    if (prev == null) {
      _items.removeAt(i);
    } else {
      _items[i] = prev;
    }
    _items.add(next);
    return next;
  }

  @override
  Future<void> delete(
    String id, {
    required CommitmentScope scope,
    String? fromDate,
  }) async {
    final i = _indexOf(id);
    final prev = scope == CommitmentScope.following
        ? _endingBefore(_items[i], fromDate!)
        : null;
    if (prev == null) {
      _items.removeAt(i);
    } else {
      _items[i] = prev;
    }
  }

  Commitment _withExceptions(Commitment c, List<CommitmentException> ex) =>
      Commitment(
        id: c.id,
        title: c.title,
        category: c.category,
        startDate: c.startDate,
        startMinute: c.startMinute,
        endMinute: c.endMinute,
        recurrence: c.recurrence,
        exceptions: ex,
      );

  @override
  Future<Commitment> setOccurrence(
    String id,
    String date,
    OccurrenceChange change,
  ) async {
    final i = _indexOf(id);
    final c = _items[i];
    if (!_occursOn(c, date)) {
      throw ValidationFailure('Esse dia não é uma ocorrência do compromisso.');
    }
    final e = CommitmentException(
      date: date,
      type: change.status == OccurrenceStatus.cancelled
          ? CommitmentExceptionType.cancelled
          : CommitmentExceptionType.moved,
      newDate: change.newDate,
      startMinute: change.startMinute,
      endMinute: change.endMinute,
    );
    return _items[i] = _withExceptions(c, [
      for (final x in c.exceptions)
        if (x.date != date) x,
      e,
    ]);
  }

  @override
  Future<Commitment> clearOccurrence(String id, String date) async {
    final i = _indexOf(id);
    final c = _items[i];
    if (c.exceptionOn(date) == null) {
      throw NotFoundFailure('Esse dia não tem alteração.');
    }
    return _items[i] = _withExceptions(c, [
      for (final x in c.exceptions)
        if (x.date != date) x,
    ]);
  }

  int _indexOf(String id) {
    final i = _items.indexWhere((c) => c.id == id);
    if (i < 0) throw NotFoundFailure('Compromisso não encontrado.');
    return i;
  }
}
