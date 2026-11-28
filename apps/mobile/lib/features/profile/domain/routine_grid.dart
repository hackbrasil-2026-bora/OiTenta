import '../../scheduling/domain/availability.dart';

/// Grade do "Redefinir minha rotina" (M27, MP11): 7 linhas de 2h
/// (8:00–22:00) × 7 dias (Seg … Dom = `weekday` 0 … 6). Imutável.
class RoutineGrid {
  RoutineGrid._(Set<(int, int)> cells) : _cells = Set.unmodifiable(cells);

  /// Nenhuma célula livre.
  RoutineGrid.empty() : this._({});

  /// Célula livre só se o intervalo inteiro dela couber numa janela salva
  /// (MP11): 09:00–11:00 não marca nada; 06:00–12:00 marca 8h e 10h.
  factory RoutineGrid.fromWindows(List<AvailabilityWindow> windows) =>
      RoutineGrid._({
        for (final w in windows)
          for (var r = 0; r < rowCount; r++)
            if (w.weekday >= 0 &&
                w.weekday < dayCount &&
                w.startMinute <= rowStartMinute(r) &&
                w.endMinute >= rowEndMinute(r))
              (w.weekday, r),
      });

  static const rowLabels = ['8h', '10h', '12h', '14h', '16h', '18h', '20h'];
  static const dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const rowCount = 7;
  static const dayCount = 7;
  static const _firstMinute = 8 * 60;
  static const _rowMinutes = 2 * 60;

  static int rowStartMinute(int row) => _firstMinute + row * _rowMinutes;

  static int rowEndMinute(int row) => rowStartMinute(row) + _rowMinutes;

  final Set<(int, int)> _cells;

  bool isFree(int day, int row) {
    _check(day, row);
    return _cells.contains((day, row));
  }

  /// Nova grade com a célula alternada.
  RoutineGrid toggle(int day, int row) {
    _check(day, row);
    final next = {..._cells};
    if (!next.remove((day, row))) next.add((day, row));
    return RoutineGrid._(next);
  }

  int get cellCount => _cells.length;

  bool get isEmpty => _cells.isEmpty;

  /// "{N}h livres por semana": 2h por célula.
  int get freeHours => cellCount * 2;

  /// Células vizinhas do mesmo dia viram uma janela só, em ordem de dia e
  /// hora. A grade substitui a disponibilidade inteira (MP11).
  List<AvailabilityWindow> toWindows() {
    final windows = <AvailabilityWindow>[];
    for (var d = 0; d < dayCount; d++) {
      int? start;
      for (var r = 0; r <= rowCount; r++) {
        final free = r < rowCount && _cells.contains((d, r));
        if (free) {
          start ??= r;
        } else if (start != null) {
          windows.add(
            AvailabilityWindow(
              weekday: d,
              startMinute: rowStartMinute(start),
              endMinute: rowStartMinute(r),
            ),
          );
          start = null;
        }
      }
    }
    return windows;
  }

  static void _check(int day, int row) {
    RangeError.checkValueInInterval(day, 0, dayCount - 1, 'day');
    RangeError.checkValueInInterval(row, 0, rowCount - 1, 'row');
  }

  @override
  bool operator ==(Object other) =>
      other is RoutineGrid &&
      other._cells.length == _cells.length &&
      other._cells.containsAll(_cells);

  @override
  int get hashCode => Object.hashAllUnordered(_cells);
}
