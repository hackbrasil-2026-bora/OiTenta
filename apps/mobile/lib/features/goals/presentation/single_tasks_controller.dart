import 'package:flutter/foundation.dart';

import '../../../core/clock/clock.dart';
import '../../../core/format/bora_format.dart';
import '../data/single_tasks_repository.dart';
import '../domain/single_task.dart';

/// "Quando?" do painel de adicionar (Hoje, Amanhã, Sem data, Escolher dia).
enum SingleTaskWhen { today, tomorrow, none, day }

/// Item da lista (`itemOf` do protótipo).
class SingleTaskItemView {
  const SingleTaskItemView({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.done,
  });

  final String id;
  final String title;

  /// `15 min · Hoje`, `30 min · Sáb, 08/11/2025`, `30 min · Sem data`.
  final String subtitle;
  final bool done;

  /// Rótulo da caixa de marcar.
  String get toggleLabel => done ? 'Desmarcar' : 'Marcar como feita';
}

/// Grupo da lista (`tuGroups`): Hoje, Próximos dias, Sem data, Feitas.
class SingleTaskGroupView {
  const SingleTaskGroupView({required this.title, required this.items});

  final String title;
  final List<SingleTaskItemView> items;

  String get count =>
      items.length == 1 ? '1 tarefa' : '${items.length} tarefas';
}

/// Toast que a página mostra depois de uma ação.
class SingleTaskToast {
  const SingleTaskToast(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

/// Tarefas únicas (M53–M54).
class SingleTasksController extends ChangeNotifier {
  SingleTasksController(this._repo, this._clock);

  final SingleTasksRepository _repo;
  final Clock _clock;
  bool _disposed = false;

  bool loading = true;
  bool busy = false;
  String? error;
  List<SingleTask> _tasks = const [];

  /// Campo "Ex.: Arrumar o guarda-roupa".
  String text = '';
  int minutes = _defaultMinutes;
  SingleTaskWhen when = SingleTaskWhen.today;

  /// Dia do "Escolher dia".
  DateTime? day;

  static const _defaultMinutes = 30;

  /// "Quanto tempo leva?" (minutos).
  List<int> get durations => const [15, 30, 60, 120];

  /// `15 min`, `30 min`, `1h`, `2h`.
  static String durationLabel(int minutes) => BoraFormat.duration(minutes);

  DateTime get _today {
    final n = _clock.now();
    return DateTime(n.year, n.month, n.day);
  }

  int _diff(DateTime d) => DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(_today.year, _today.month, _today.day)).inDays;

  /// `whenTxt` do protótipo: Hoje, Amanhã, `Sáb, 08/11/2025` ou Sem data.
  String _whenText(DateTime? d) {
    if (d == null) return 'Sem data';
    return switch (_diff(d)) {
      0 => 'Hoje',
      1 => 'Amanhã',
      _ => BoraFormat.fullDate(d),
    };
  }

  static DateTime? _date(SingleTask t) =>
      t.plannedDate == null ? null : BoraFormat.parseDateKey(t.plannedDate!);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    _notify();
    await _fetch();
    loading = false;
    _notify();
  }

  Future<void> _fetch() async {
    try {
      _tasks = await _repo.list();
      error = null;
    } catch (_) {
      error = 'Não deu pra carregar suas tarefas.';
    }
  }

  List<SingleTaskGroupView> get groups {
    SingleTaskItemView item(SingleTask t) => SingleTaskItemView(
      id: t.id,
      title: t.title,
      subtitle: '${durationLabel(t.estimatedMinutes)} · ${_whenText(_date(t))}',
      done: t.done,
    );
    final open = _tasks.where((t) => !t.done).toList();
    final upcoming = [
      for (var i = 0; i < open.length; i++)
        if (_date(open[i]) != null && _diff(_date(open[i])!) > 0) (i, open[i]),
    ];
    // Ordena pela data mantendo a ordem original no empate.
    upcoming.sort((a, b) {
      final byDate = a.$2.plannedDate!.compareTo(b.$2.plannedDate!);
      return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
    });
    final all = [
      SingleTaskGroupView(
        title: 'Hoje',
        items: [
          for (final t in open)
            if (_date(t) != null && _diff(_date(t)!) <= 0) item(t),
        ],
      ),
      SingleTaskGroupView(
        title: 'Próximos dias',
        items: [for (final (_, t) in upcoming) item(t)],
      ),
      SingleTaskGroupView(
        title: 'Sem data',
        items: [
          for (final t in open)
            if (t.plannedDate == null) item(t),
        ],
      ),
      SingleTaskGroupView(
        title: 'Feitas',
        items: [
          for (final t in _tasks)
            if (t.done) item(t),
        ],
      ),
    ];
    return [
      for (final g in all)
        if (g.items.isNotEmpty) g,
    ];
  }

  /// O painel aparece quando o campo tem texto.
  bool get panelOpen => text.trim().isNotEmpty;

  bool get canAdd =>
      !busy &&
      text.trim().length >= 2 &&
      (when != SingleTaskWhen.day || day != null);

  /// Chip "Escolher dia": mostra a data escolhida quando está selecionado.
  String get dayChipLabel => when == SingleTaskWhen.day && day != null
      ? BoraFormat.fullDate(day!)
      : 'Escolher dia';

  void setText(String v) {
    text = v;
    _notify();
  }

  void setMinutes(int m) {
    minutes = m;
    _notify();
  }

  void setWhen(SingleTaskWhen w) {
    when = w;
    _notify();
  }

  /// Dia escolhido no date picker do "Escolher dia".
  void setDay(DateTime d) {
    day = DateTime(d.year, d.month, d.day);
    when = SingleTaskWhen.day;
    _notify();
  }

  DateTime? get _plannedDay => switch (when) {
    SingleTaskWhen.today => _today,
    SingleTaskWhen.tomorrow => DateTime(
      _today.year,
      _today.month,
      _today.day + 1,
    ),
    SingleTaskWhen.none => null,
    SingleTaskWhen.day => day,
  };

  Future<SingleTaskToast?> add() async {
    if (!canAdd) return null;
    final planned = _plannedDay;
    final ok = await _run(
      () => _repo.create(
        NewSingleTask(
          title: text.trim(),
          estimatedMinutes: minutes,
          plannedDate: planned == null ? null : BoraFormat.dateKey(planned),
        ),
      ),
      'Não deu pra salvar a tarefa.',
    );
    if (!ok) return null;
    text = '';
    minutes = _defaultMinutes;
    when = SingleTaskWhen.today;
    day = null;
    _notify();
    return SingleTaskToast(
      'Tarefa anotada',
      planned == null
          ? 'Eu encaixo quando sobrar um tempinho.'
          : 'Encaixei num horário livre de ${_whenText(planned).toLowerCase()}.',
    );
  }

  /// Marca ou desmarca. Só marcar devolve o toast "Feito!".
  Future<SingleTaskToast?> toggle(String id) async {
    if (busy) return null;
    final task = _tasks.where((t) => t.id == id).firstOrNull;
    if (task == null) return null;
    final done = !task.done;
    final ok = await _run(
      () => _repo.setDone(id, done: done),
      'Não deu pra atualizar a tarefa.',
    );
    if (!ok || !done) return null;
    return const SingleTaskToast('Feito!', 'Uma coisa a menos na cabeça.');
  }

  Future<void> remove(String id) async {
    if (busy) return;
    await _run(() => _repo.delete(id), 'Não deu pra atualizar a tarefa.');
  }

  /// Roda a ação com `busy` e recarrega a lista quando dá certo.
  Future<bool> _run(Future<void> Function() action, String failure) async {
    busy = true;
    error = null;
    _notify();
    try {
      await action();
    } catch (_) {
      error = failure;
      busy = false;
      _notify();
      return false;
    }
    await _fetch();
    busy = false;
    _notify();
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
