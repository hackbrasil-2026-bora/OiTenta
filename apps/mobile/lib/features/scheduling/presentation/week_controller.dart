import 'package:flutter/foundation.dart';

import '../../../core/clock/clock.dart';
import '../../../core/format/bora_format.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/goal.dart';
import '../data/commitments_repository.dart';
import '../data/scheduling_repository.dart';
import '../domain/commitment.dart';
import '../domain/plan.dart';
import 'commitment_occurrence_view.dart';

/// Os dois calendários (M03/M19 e M21): Execução mostra os blocos das etapas;
/// Prazos mostra só o objetivo inteiro, na data do prazo final.
enum CalendarMode { execution, deadlines }

class WeekDayView {
  const WeekDayView({
    required this.date,
    required this.weekday,
    required this.number,
    required this.isToday,
    required this.colorIndexes,
  });

  final DateTime date;
  final String weekday;
  final int number;
  final bool isToday;
  final List<int> colorIndexes;
}

/// Dia da grade do mês (M20/M21). Dias de fora do mês aparecem apagados,
/// sem pontos e sem seleção.
class MonthDayView {
  const MonthDayView({
    required this.date,
    required this.weekday,
    required this.number,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.colorIndexes,
  });

  final DateTime date;
  final String weekday;
  final int number;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final List<int> colorIndexes;
}

class WeekBlockView {
  const WeekBlockView({
    required this.time,
    required this.goalTitle,
    required this.colorIndex,
    required this.title,
    required this.duration,
    required this.done,
    required this.pill,
  });

  final String time;
  final String goalTitle;
  final int colorIndex;
  final String title;
  final String duration;
  final bool done;
  final String? pill;
}

/// Entrega final de um objetivo no dia escolhido (Prazos, M21).
class DeadlineView {
  const DeadlineView({
    required this.goalId,
    required this.title,
    required this.colorIndex,
    required this.progress,
    required this.progressLabel,
  });

  final String goalId;
  final String title;
  final int colorIndex;

  /// De 0 a 1.
  final double progress;

  /// `62% concluído`.
  final String progressLabel;
}

/// Item da lista do dia (Execução): uma etapa ou um compromisso.
class WeekDayItem {
  const WeekDayItem.block(WeekBlockView this.block, {required this.time})
    : commitment = null;

  WeekDayItem.commitment(CommitmentOccurrenceView this.commitment)
    : block = null,
      time = commitment.time;

  final String time;
  final WeekBlockView? block;
  final CommitmentOccurrenceView? commitment;

  bool get isCommitment => commitment != null;
}

class LegendItem {
  const LegendItem({required this.colorIndex, required this.title});

  final int colorIndex;
  final String title;
}

/// Calendário (M03/M19 semana, M20 mês, M21 prazos): semana compacta que
/// expande para o mês, Execução/Prazos, legenda e lista do dia.
///
/// O mês é montado com as semanas que o cobrem (`GET /scheduling/plan/week`,
/// uma por segunda-feira); os prazos vêm de `GET /goals`.
class WeekController extends ChangeNotifier {
  WeekController(
    this._repo,
    this._clock, {
    GoalsRepository? goals,
    CommitmentsRepository? commitments,
  }) : _goalsRepo = goals,
       _commitmentsRepo = commitments;

  final SchedulingRepository _repo;
  final Clock _clock;

  /// Sem ele, Prazos fica vazio.
  final GoalsRepository? _goalsRepo;

  /// Sem ele, a lista do dia mostra só as etapas.
  final CommitmentsRepository? _commitmentsRepo;

  /// Objetivo `done` com prazo continua em Prazos (com 100%). [DECIDIR]: o
  /// protótipo não diz; trocar aqui se a decisão for escondê-los.
  static const showDoneGoalsInDeadlines = true;

  bool loading = true;
  String? error;

  /// Erro só dos compromissos: as etapas continuam na tela.
  String? commitmentsError;
  bool expanded = false;
  CalendarMode mode = CalendarMode.execution;

  final Map<String, WeekPlan> _weeks = {};

  /// Ocorrências por segunda-feira (`GET …/occurrences?from&to`).
  final Map<String, List<CommitmentOccurrence>> _occurrences = {};
  List<GoalSummary>? _goals;
  late DateTime _selected;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Não avisa depois do `dispose` (a tela pode sair durante um `await`).
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final now = _clock.now();
    _selected = DateTime(now.year, now.month, now.day);
    loading = true;
    _notify();
    try {
      await _ensureWeeks([_monday]);
    } catch (_) {
      error = 'Não deu pra carregar a semana.';
    } finally {
      loading = false;
      _notify();
    }
  }

  /// Uma chamada de semana por segunda-feira que ainda não foi carregada.
  Future<void> _ensureWeeks(List<DateTime> mondays) async {
    final missing = [
      for (final m in mondays)
        if (!_weeks.containsKey(BoraFormat.dateKey(m))) BoraFormat.dateKey(m),
    ];
    final plans = await Future.wait([
      for (final key in missing) _repo.getWeekPlan(key),
    ]);
    for (var i = 0; i < missing.length; i++) {
      _weeks[missing[i]] = plans[i];
    }
    await _ensureOccurrences(mondays);
  }

  /// Compromissos das semanas que faltam; o erro fica só em
  /// [commitmentsError].
  Future<void> _ensureOccurrences(List<DateTime> mondays) async {
    final repo = _commitmentsRepo;
    if (repo == null) return;
    final missing = [
      for (final m in mondays)
        if (!_occurrences.containsKey(BoraFormat.dateKey(m))) m,
    ];
    try {
      final lists = await Future.wait([
        for (final m in missing)
          repo.listOccurrences(
            BoraFormat.dateKey(m),
            BoraFormat.dateKey(DateTime(m.year, m.month, m.day + 6)),
          ),
      ]);
      for (var i = 0; i < missing.length; i++) {
        _occurrences[BoraFormat.dateKey(missing[i])] = lists[i];
      }
      commitmentsError = null;
    } catch (_) {
      commitmentsError = 'Não deu pra carregar os compromissos.';
    }
  }

  /// Depois de criar, editar ou excluir um compromisso: o backend recalcula
  /// o plano, então busca de novo as semanas visíveis e os compromissos.
  Future<void> reload() async {
    final mondays = expanded ? _monthMondays : [_monday];
    _weeks.clear();
    _occurrences.clear();
    await _guard(() => _ensureWeeks(mondays), expanded ? 'o mês' : 'a semana');
  }

  // --- Período visível ------------------------------------------------------

  DateTime get _monday => BoraFormat.mondayOf(_selected);

  DateTime get selectedDate => _selected;

  /// `YYYY-MM-DD` do dia escolhido ("+ Compromisso").
  String get selectedDateKey => BoraFormat.dateKey(_selected);

  /// Posição do dia escolhido na semana visível (0 = segunda).
  int get selectedIndex => _selected.weekday - 1;

  String get rangeLabel => BoraFormat.weekRange(_monday);

  /// `Semana` ou o nome do mês (`Novembro`).
  String get title => expanded
      ? BoraFormat.monthYear(_selected.year, _selected.month).split(' ').first
      : 'Semana';

  String get subtitle =>
      expanded ? 'Arraste pra cima pra voltar à semana' : rangeLabel;

  /// Segundas-feiras das semanas que cobrem o mês do dia escolhido.
  List<DateTime> get _monthMondays {
    final first = DateTime(_selected.year, _selected.month, 1);
    final last = DateTime(_selected.year, _selected.month + 1, 0);
    return [
      for (
        var m = BoraFormat.mondayOf(first);
        !m.isAfter(last);
        m = DateTime(m.year, m.month, m.day + 7)
      )
        m,
    ];
  }

  // --- Dados por dia --------------------------------------------------------

  List<PlanBlock> _blocksOn(DateTime d) {
    final week = _weeks[BoraFormat.dateKey(BoraFormat.mondayOf(d))];
    if (week == null) return const [];
    return week.days[d.weekday - 1].blocks;
  }

  /// Objetivos com prazo, pela data (objetivo sem prazo não entra).
  List<GoalSummary> get _deadlineGoals => [
    for (final g in _goals ?? const <GoalSummary>[])
      if (g.deadline != null &&
          (showDoneGoalsInDeadlines || g.status != 'done'))
        g,
  ]..sort((a, b) => a.deadline!.compareTo(b.deadline!));

  List<GoalSummary> _deadlinesOn(DateTime d) {
    final key = BoraFormat.dateKey(d);
    return [
      for (final g in _deadlineGoals)
        if (g.deadline == key) g,
    ];
  }

  /// Pontos do dia: objetivos com bloco (Execução) ou com prazo (Prazos).
  List<int> _colorsOn(DateTime d) {
    final source = mode == CalendarMode.execution
        ? _blocksOn(d).map((b) => b.colorIndex)
        : _deadlinesOn(d).map((g) => g.colorIndex);
    final colors = <int>[];
    for (final c in source) {
      if (!colors.contains(c)) colors.add(c);
    }
    return colors.take(4).toList();
  }

  List<WeekDayView> get days {
    final today = _clock.now();
    final monday = _monday;
    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = DateTime(monday.year, monday.month, monday.day + i);
          return WeekDayView(
            date: d,
            weekday: BoraFormat.weekdayShort(d),
            number: d.day,
            isToday: BoraFormat.sameDay(d, today),
            colorIndexes: _colorsOn(d),
          );
        }(),
    ];
  }

  List<List<MonthDayView>> get monthWeeks {
    final today = _clock.now();
    return [
      for (final m in _monthMondays)
        [
          for (var i = 0; i < 7; i++)
            () {
              final d = DateTime(m.year, m.month, m.day + i);
              final inMonth =
                  d.year == _selected.year && d.month == _selected.month;
              return MonthDayView(
                date: d,
                weekday: BoraFormat.weekdayShort(d),
                number: d.day,
                inMonth: inMonth,
                isToday: inMonth && BoraFormat.sameDay(d, today),
                isSelected: inMonth && BoraFormat.sameDay(d, _selected),
                colorIndexes: inMonth ? _colorsOn(d) : const [],
              );
            }(),
        ],
    ];
  }

  /// Execução: os objetivos com etapa no período visível (semana ou mês).
  /// Prazos: os objetivos com prazo, pela data.
  List<LegendItem> get legend {
    if (mode == CalendarMode.deadlines) {
      return [
        for (final g in _deadlineGoals)
          LegendItem(colorIndex: g.colorIndex, title: g.title),
      ];
    }
    final visible = expanded
        ? [
            for (final w in monthWeeks)
              for (final d in w)
                if (d.inMonth) d.date,
          ]
        : [for (final d in days) d.date];
    final map = <int, String>{};
    for (final d in visible) {
      for (final b in _blocksOn(d)) {
        map.putIfAbsent(b.colorIndex, () => b.goalTitle);
      }
    }
    final keys = map.keys.toList()..sort();
    return [for (final k in keys) LegendItem(colorIndex: k, title: map[k]!)];
  }

  String get dayLabel => BoraFormat.dayLabel(_selected, _clock.now());

  /// Blocos das etapas no dia escolhido (só em Execução).
  List<WeekBlockView> get dayBlocks => mode != CalendarMode.execution
      ? const []
      : [
          for (final b in _blocksOn(_selected))
            WeekBlockView(
              time: BoraFormat.clock(b.start),
              goalTitle: b.goalTitle,
              colorIndex: b.colorIndex,
              title: b.stepTitle,
              duration: BoraFormat.duration(b.minutes),
              done: b.status == 'done',
              pill: b.status == 'done'
                  ? 'Concluída'
                  : b.status == 'missed'
                  ? 'Reagendada'
                  : null,
            ),
        ];

  List<CommitmentOccurrence> _occurrencesOn(DateTime d) {
    final key = BoraFormat.dateKey(d);
    return [
      for (final o
          in _occurrences[BoraFormat.dateKey(BoraFormat.mondayOf(d))] ??
              const <CommitmentOccurrence>[])
        if (o.date == key) o,
    ];
  }

  /// Lista do dia em Execução: etapas e compromissos pela hora de início
  /// (`dayList` do protótipo; no empate, a etapa vem antes).
  List<WeekDayItem> get dayItems {
    if (mode != CalendarMode.execution) return const [];
    final blocks = _blocksOn(_selected);
    final views = dayBlocks;
    final keyed = <(int, int, WeekDayItem)>[
      for (var i = 0; i < blocks.length; i++)
        () {
          final l = blocks[i].start.toLocal();
          return (
            l.hour * 60 + l.minute,
            i,
            WeekDayItem.block(views[i], time: views[i].time),
          );
        }(),
      for (final (j, o) in _occurrencesOn(_selected).indexed)
        (
          o.startMinute,
          blocks.length + j,
          WeekDayItem.commitment(CommitmentOccurrenceView(o)),
        ),
    ];
    keyed.sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    return [for (final k in keyed) k.$3];
  }

  /// Entregas finais no dia escolhido (só em Prazos).
  List<DeadlineView> get dayDeadlines => mode != CalendarMode.deadlines
      ? const []
      : [
          for (final g in _deadlinesOn(_selected))
            DeadlineView(
              goalId: g.id,
              title: g.title,
              colorIndex: g.colorIndex,
              progress: g.progressPct / 100,
              progressLabel: '${g.progressPct}% concluído',
            ),
        ];

  // --- Ações ----------------------------------------------------------------

  /// Dia [i] (0 = segunda) da semana visível.
  void selectDay(int i) {
    final m = _monday;
    _selected = DateTime(m.year, m.month, m.day + i);
    _notify();
  }

  /// Dia da grade do mês; dia de fora do mês é ignorado.
  void selectDate(DateTime d) {
    final outOfMonth = d.year != _selected.year || d.month != _selected.month;
    if (expanded && outOfMonth) return;
    _selected = DateTime(d.year, d.month, d.day);
    _notify();
  }

  /// Arrastar para baixo: abre o mês e carrega as semanas que faltam.
  Future<void> expand() async {
    if (expanded) return;
    expanded = true;
    _notify();
    await _guard(() => _ensureWeeks(_monthMondays), 'o mês');
  }

  /// Arrastar para cima: volta para a semana do dia escolhido.
  Future<void> collapse() async {
    if (!expanded) return;
    expanded = false;
    _notify();
    await _guard(() => _ensureWeeks([_monday]), 'a semana');
  }

  Future<void> toggleExpanded() => expanded ? collapse() : expand();

  /// Troca Execução/Prazos; Prazos busca `GET /goals` na primeira vez.
  Future<void> setMode(CalendarMode m) async {
    mode = m;
    _notify();
    final repo = _goalsRepo;
    if (m == CalendarMode.deadlines && _goals == null && repo != null) {
      await _guard(() async => _goals = await repo.listGoals(), 'os prazos');
    }
  }

  Future<void> _guard(Future<void> Function() run, String what) async {
    try {
      await run();
      error = null;
    } catch (_) {
      error = 'Não deu pra carregar $what.';
    } finally {
      _notify();
    }
  }
}
