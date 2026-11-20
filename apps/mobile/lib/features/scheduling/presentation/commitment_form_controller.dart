import 'package:flutter/foundation.dart';

import '../../../core/clock/clock.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_errors.dart';
import '../../../core/format/bora_format.dart';
import '../data/commitments_repository.dart';
import '../data/scheduling_repository.dart';
import '../domain/commitment.dart';
import '../domain/plan.dart';

/// Como o formulário foi aberto (M46, M47, M52).
class CommitmentFormArgs {
  const CommitmentFormArgs({this.date, this.scope, this.occurrenceDate});

  /// Dia escolhido na Semana ("+ Compromisso" abre "Só uma vez" nesse dia).
  final String? date;

  /// Escopo da edição; `null` com [occurrenceDate] = "Só nesse dia".
  final CommitmentScope? scope;

  /// A ocorrência tocada (Editar "Só nesse dia" ou "Desse dia em diante").
  final String? occurrenceDate;
}

/// Novo, editar todas as semanas, desse dia em diante (MC12) ou só nesse dia.
enum CommitmentFormMode { create, editAll, editFollowing, editOnly }

/// "Repete?": "Toda semana" ou "Só uma vez".
enum CommitmentRepeat { weekly, once }

/// "Até quando?": "Sem fim", "Fim do semestre" (MC3) ou "Escolher data".
enum CommitmentUntil { none, semester, date }

enum CommitmentToastKind { saved, recalculated, deleted }

/// O toast que a página mostra depois de salvar ou excluir (`cpSalvar`).
class CommitmentFormToast {
  const CommitmentFormToast(this.kind, this.title, this.subtitle);

  final CommitmentToastKind kind;
  final String title;
  final String subtitle;
}

/// Letras e nomes dos dias (0 = segunda … 6 = domingo).
const commitmentWeekdayLetters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
const commitmentWeekdayNames = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// Formulário Novo/Editar compromisso (M46, M47, M52; `cpBlank`, `cpEdit`,
/// `cpOk`, `cpSalvar`, `conflito` do protótipo).
class CommitmentFormController extends ChangeNotifier {
  CommitmentFormController({
    required CommitmentsRepository commitments,
    required SchedulingRepository scheduling,
    required Clock clock,
    this.commitmentId,
    this.args = const CommitmentFormArgs(),
    String semesterEnd = AppConfig.semesterEnd,
  }) : _commitments = commitments,
       _scheduling = scheduling,
       _semesterEnd = BoraFormat.parseDateKey(semesterEnd),
       mode = _modeOf(commitmentId, args) {
    final now = clock.now();
    _today = DateTime(now.year, now.month, now.day);
    loaded = mode == CommitmentFormMode.create;
    final day = args.date == null ? null : BoraFormat.parseDateKey(args.date!);
    if (day != null) {
      repeat = CommitmentRepeat.once;
      date = day;
    }
    weekdays = {(day ?? _today).weekday - 1};
  }

  static CommitmentFormMode _modeOf(String? id, CommitmentFormArgs a) {
    if (id == null) return CommitmentFormMode.create;
    if (a.scope == CommitmentScope.following && a.occurrenceDate != null) {
      return CommitmentFormMode.editFollowing;
    }
    if (a.scope == null && a.occurrenceDate != null) {
      return CommitmentFormMode.editOnly;
    }
    return CommitmentFormMode.editAll;
  }

  final CommitmentsRepository _commitments;
  final SchedulingRepository _scheduling;
  final DateTime _semesterEnd;
  late final DateTime _today;
  bool _disposed = false;

  final String? commitmentId;
  final CommitmentFormArgs args;
  final CommitmentFormMode mode;

  String title = '';
  CommitmentCategory category = CommitmentCategory.aula;
  CommitmentRepeat repeat = CommitmentRepeat.weekly;
  late Set<int> weekdays;
  DateTime? date;
  int startMinute = 19 * 60;
  int endMinute = 21 * 60;
  CommitmentUntil until = CommitmentUntil.none;
  DateTime? untilDate;

  bool loading = false;
  late bool loaded;
  bool busy = false;
  String? error;

  /// Blocos do plano por semana (`YYYY-MM-DD` da segunda), para o conflito.
  final Map<String, List<PlanBlock>> _weeks = {};

  DateTime? get _occurrence => args.occurrenceDate == null
      ? null
      : BoraFormat.parseDateKey(args.occurrenceDate!);

  // ---------------------------------------------------------------- textos

  String get heading => mode == CommitmentFormMode.create
      ? 'Novo compromisso'
      : 'Editar compromisso';

  /// `cpSubTxt`.
  String get subtitle => switch (mode) {
    CommitmentFormMode.create =>
      'Me conta quando você tá ocupado pra eu não marcar etapa por cima.',
    CommitmentFormMode.editOnly =>
      'Mudando só ${BoraFormat.fullDate(_occurrence!)}. As outras semanas continuam iguais.',
    CommitmentFormMode.editFollowing =>
      'Vale a partir de ${BoraFormat.fullDate(_occurrence!)}. Antes disso fica como era.',
    CommitmentFormMode.editAll =>
      isWeekly ? 'Vale pra todas as semanas.' : 'Me conta o que mudou.',
  };

  /// `cpSalvarTxt`.
  String get saveLabel => switch (mode) {
    CommitmentFormMode.create => 'Salvar compromisso',
    CommitmentFormMode.editOnly => 'Salvar só nesse dia',
    _ => 'Salvar alterações',
  };

  /// `cpShowNome`, `cpSoNome`, `cpShowRep`, `cpPodeExcluir`.
  bool get showName => mode != CommitmentFormMode.editOnly;
  bool get showFixedName => mode == CommitmentFormMode.editOnly;
  bool get showRepeat =>
      mode == CommitmentFormMode.create || mode == CommitmentFormMode.editAll;
  bool get canDelete => mode == CommitmentFormMode.editAll && loaded;

  bool get isWeekly => repeat == CommitmentRepeat.weekly;

  bool get loadFailed => !loading && !loaded && error != null;

  String get dateText =>
      date == null ? 'Escolher data' : BoraFormat.fullDate(date!);

  /// `ateTxt`.
  String get untilText => switch (until) {
    CommitmentUntil.semester =>
      'Para de repetir depois de ${BoraFormat.dayMonth(_semesterEnd)}, no fim do semestre.',
    CommitmentUntil.date when untilDate != null =>
      'Para de repetir depois de ${BoraFormat.fullDate(untilDate!)}.',
    CommitmentUntil.date => 'Escolha o último dia.',
    CommitmentUntil.none => 'Repete até você mudar ou excluir.',
  };

  /// Rótulo do chip "Escolher data" (`Até dd/mm` com a data escolhida).
  String get untilDateLabel =>
      until == CommitmentUntil.date && untilDate != null
      ? 'Até ${BoraFormat.dayMonth(untilDate!)}'
      : 'Escolher data';

  // -------------------------------------------------------------- validação

  /// `horaOk`.
  bool get timeOk => startMinute < endMinute;

  /// `cpOk`.
  bool get _valid =>
      title.trim().length >= 2 &&
      timeOk &&
      (isWeekly
          ? weekdays.isNotEmpty &&
                (until != CommitmentUntil.date || untilDate != null)
          : date != null);

  bool get canSave => loaded && !busy && _valid;

  // --------------------------------------------------------------- conflito

  /// O dia de referência do conflito: a data (único) ou a ocorrência / hoje.
  DateTime? get _refDay => isWeekly ? (_occurrence ?? _today) : date;

  /// A primeira etapa planejada que se sobrepõe ao horário (MC5): no semanal,
  /// em qualquer dia marcado da semana do dia de referência e da seguinte, a
  /// partir dele; no único, na data.
  PlanBlock? get conflict {
    final ref = _refDay;
    if (!timeOk || ref == null) return null;
    final limit = _addDays(BoraFormat.mondayOf(ref), 14);
    final blocks = [for (final w in _weeks.values) ...w]
      ..sort((a, b) => a.start.compareTo(b.start));
    for (final b in blocks) {
      if (b.status != 'planned') continue;
      final s = b.start.toLocal();
      final day = DateTime(s.year, s.month, s.day);
      if (isWeekly) {
        if (day.isBefore(ref) || !day.isBefore(limit)) continue;
        if (!weekdays.contains(day.weekday - 1)) continue;
        if (untilDate != null && day.isAfter(untilDate!)) continue;
      } else if (day != ref) {
        continue;
      }
      final e = b.end.toLocal();
      final bs = s.hour * 60 + s.minute;
      final be = BoraFormat.sameDay(e, s) ? e.hour * 60 + e.minute : 24 * 60;
      if (startMinute < be && endMinute > bs) return b;
    }
    return null;
  }

  /// `Bate com "{etapa}" (dd/mm · HHh)`.
  String? get conflictTitle {
    final b = conflict;
    if (b == null) return null;
    return 'Bate com "${b.stepTitle}" (${BoraFormat.dayMonth(b.start.toLocal())} · ${BoraFormat.hour(b.start)})';
  }

  static DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  Future<void> _refreshBlocks() async {
    final ref = _refDay;
    if (ref == null) return;
    final monday = BoraFormat.mondayOf(ref);
    for (final m in [monday, _addDays(monday, 7)]) {
      final key = BoraFormat.dateKey(m);
      if (_weeks.containsKey(key)) continue;
      try {
        final w = await _scheduling.getWeekPlan(key);
        _weeks[key] = [for (final d in w.days) ...d.blocks];
      } catch (_) {
        // Sem os blocos, sem aviso: o backend recalcula ao salvar.
      }
    }
    _notify();
  }

  // ------------------------------------------------------------------ carga

  /// No editar, lê o compromisso (`cpEdit`); depois busca os blocos.
  Future<void> load() async {
    if (mode != CommitmentFormMode.create) {
      loading = true;
      error = null;
      _notify();
      try {
        _fill(await _commitments.get(commitmentId!));
        loaded = true;
      } catch (e) {
        error = _message(
          e,
          'Não deu pra carregar o compromisso. Tenta de novo?',
        );
      } finally {
        loading = false;
        _notify();
      }
      if (!loaded) return;
    }
    await _refreshBlocks();
  }

  void _fill(Commitment cp) {
    title = cp.title;
    category = cp.category;
    startMinute = cp.startMinute;
    endMinute = cp.endMinute;
    final rec = cp.recurrence;
    if (rec != null) {
      repeat = CommitmentRepeat.weekly;
      weekdays = {...rec.weekdays};
      final end = rec.endDate;
      untilDate = end == null ? null : BoraFormat.parseDateKey(end);
      until = end == null
          ? CommitmentUntil.none
          : (untilDate == _semesterEnd
                ? CommitmentUntil.semester
                : CommitmentUntil.date);
    } else {
      repeat = CommitmentRepeat.once;
      date = BoraFormat.parseDateKey(cp.startDate);
      weekdays = {date!.weekday - 1};
    }
    if (mode == CommitmentFormMode.editOnly) {
      final occ = args.occurrenceDate!;
      final ex = cp.exceptionOn(occ);
      repeat = CommitmentRepeat.once;
      if (ex != null && ex.type == CommitmentExceptionType.moved) {
        date = BoraFormat.parseDateKey(ex.newDate ?? occ);
        startMinute = ex.startMinute ?? startMinute;
        endMinute = ex.endMinute ?? endMinute;
      } else {
        date = BoraFormat.parseDateKey(occ);
      }
    }
  }

  // ---------------------------------------------------------------- edição

  void setTitle(String v) {
    title = v;
    _notify();
  }

  void setCategory(CommitmentCategory v) {
    category = v;
    _notify();
  }

  Future<void> setRepeat(CommitmentRepeat v) {
    repeat = v;
    _notify();
    return _refreshBlocks();
  }

  void toggleWeekday(int w) {
    weekdays = weekdays.contains(w)
        ? ({...weekdays}..remove(w))
        : {...weekdays, w};
    _notify();
  }

  /// "Sem fim" limpa a data; "Fim do semestre" usa o `SEMESTER_END`;
  /// "Escolher data" espera o [setUntilDate].
  void chooseUntil(CommitmentUntil v) {
    switch (v) {
      case CommitmentUntil.none:
        untilDate = null;
      case CommitmentUntil.semester:
        untilDate = _semesterEnd;
      case CommitmentUntil.date:
        if (until != CommitmentUntil.date) untilDate = null;
    }
    until = v;
    _notify();
  }

  void setUntilDate(DateTime d) {
    until = CommitmentUntil.date;
    untilDate = d;
    _notify();
  }

  Future<void> setDate(DateTime d) {
    date = DateTime(d.year, d.month, d.day);
    _notify();
    return _refreshBlocks();
  }

  void setStart(int minute) {
    startMinute = minute;
    _notify();
  }

  void setEnd(int minute) {
    endMinute = minute;
    _notify();
  }

  // ----------------------------------------------------------------- salvar

  CommitmentRecurrence get _recurrence => CommitmentRecurrence(
    weekdays: weekdays.toList()..sort(),
    endDate: untilDate == null ? null : BoraFormat.dateKey(untilDate!),
  );

  /// Salva conforme o modo (contrato §5b) e devolve o toast (`cpSalvar`).
  Future<CommitmentFormToast?> save() async {
    if (!canSave) return null;
    final hit = conflict;
    busy = true;
    error = null;
    _notify();
    try {
      final toast = await _persist();
      return hit == null
          ? toast
          : CommitmentFormToast(
              CommitmentToastKind.recalculated,
              'Plano recalculado',
              'Mudei "${hit.stepTitle}" pra outro horário.',
            );
    } catch (e) {
      error = _message(e, 'Não deu pra salvar o compromisso. Tenta de novo?');
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<CommitmentFormToast> _persist() async {
    final name = title.trim();
    switch (mode) {
      case CommitmentFormMode.create:
        await _commitments.create(
          NewCommitment(
            title: name,
            category: category,
            startDate: BoraFormat.dateKey(isWeekly ? _today : date!),
            startMinute: startMinute,
            endMinute: endMinute,
            recurrence: isWeekly ? _recurrence : null,
          ),
        );
        return const CommitmentFormToast(
          CommitmentToastKind.saved,
          'Compromisso salvo',
          'Não vou marcar etapas nesse horário.',
        );
      case CommitmentFormMode.editOnly:
        await _commitments.setOccurrence(
          commitmentId!,
          args.occurrenceDate!,
          OccurrenceChange.move(
            newDate: BoraFormat.dateKey(date!),
            startMinute: startMinute,
            endMinute: endMinute,
          ),
        );
        return const CommitmentFormToast(
          CommitmentToastKind.saved,
          'Só esse dia mudou',
          'As outras semanas continuam iguais.',
        );
      case CommitmentFormMode.editFollowing:
        await _commitments.update(
          commitmentId!,
          CommitmentChange(
            scope: CommitmentScope.following,
            fromDate: args.occurrenceDate,
            title: name,
            category: category,
            startMinute: startMinute,
            endMinute: endMinute,
            recurrence: _recurrence,
          ),
        );
        return CommitmentFormToast(
          CommitmentToastKind.saved,
          'Mudança salva',
          'Vale a partir de ${BoraFormat.dayMonth(_occurrence!)}.',
        );
      case CommitmentFormMode.editAll:
        await _commitments.update(
          commitmentId!,
          CommitmentChange(
            scope: CommitmentScope.all,
            title: name,
            category: category,
            startDate: isWeekly ? null : BoraFormat.dateKey(date!),
            startMinute: startMinute,
            endMinute: endMinute,
            recurrence: isWeekly ? _recurrence : null,
          ),
        );
        return CommitmentFormToast(
          CommitmentToastKind.saved,
          'Compromisso atualizado',
          isWeekly
              ? 'Vale pra todas as semanas.'
              : 'Recalculei seu plano em volta dele.',
        );
    }
  }

  /// "Excluir compromisso" (só em "todas as semanas"): `DELETE ?scope=all`.
  Future<CommitmentFormToast?> delete() async {
    if (!canDelete || busy) return null;
    busy = true;
    error = null;
    _notify();
    try {
      await _commitments.delete(commitmentId!, scope: CommitmentScope.all);
      return const CommitmentFormToast(
        CommitmentToastKind.deleted,
        'Compromisso excluído',
        'Liberei esses horários pro seu plano.',
      );
    } catch (e) {
      error = _message(e, 'Não deu pra excluir o compromisso. Tenta de novo?');
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }

  /// 400/422 e 404 mostram a mensagem do backend; o resto, [fallback].
  static String _message(Object e, String fallback) => switch (e) {
    ValidationFailure(:final message) => '$message',
    NotFoundFailure(:final message) => message,
    _ => fallback,
  };

  void _notify() {
    // A tela pode ter sido fechada durante uma chamada.
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
