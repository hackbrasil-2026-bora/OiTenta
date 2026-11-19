import 'package:flutter/foundation.dart';

import '../../../core/errors/app_errors.dart';
import '../../scheduling/data/scheduling_repository.dart';
import '../../scheduling/domain/availability.dart';
import '../domain/routine_grid.dart';

/// Redefinir minha rotina (M27): lê e grava a disponibilidade
/// (`GET`/`PUT /scheduling/availability`; o PUT já recalcula o plano).
class RoutineController extends ChangeNotifier {
  RoutineController(this._repo);

  final SchedulingRepository _repo;

  static const defaultLimitHours = 4;

  RoutineGrid grid = RoutineGrid.empty();
  int limitHours = defaultLimitHours;
  bool loading = false;
  bool saving = false;
  String? error;

  bool isFree(int day, int row) => grid.isFree(day, row);

  int get freeHours => grid.freeHours;

  /// O backend responde 422 sem janelas: sem células, não dá pra salvar.
  bool get canSave => !grid.isEmpty && !saving;

  /// Sem disponibilidade (`null`): grade vazia e limite de 4h.
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final a = await _repo.getAvailability();
      if (a != null) {
        grid = RoutineGrid.fromWindows(a.windows);
        limitHours = (a.dailyLimitMinutes / 60).round().clamp(1, 8);
      }
    } catch (_) {
      error = 'Não deu pra carregar sua rotina. Tenta de novo?';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void toggle(int day, int row) {
    grid = grid.toggle(day, row);
    notifyListeners();
  }

  void setLimitHours(int hours) {
    limitHours = hours.clamp(1, 8);
    notifyListeners();
  }

  /// Grava a grade inteira (substitui a disponibilidade, MP11) e o limite.
  Future<bool> save() async {
    if (!canSave) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repo.setAvailability(
        WeeklyAvailability(
          windows: grid.toWindows(),
          dailyLimitMinutes: limitHours * 60,
        ),
      );
      return true;
    } on ValidationFailure catch (e) {
      error = '${e.message}';
      return false;
    } catch (_) {
      error = 'Não deu pra salvar sua rotina. Tenta de novo?';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
