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
  bool _disposed = false;

  static const defaultLimitHours = 4;

  RoutineGrid grid = RoutineGrid.empty();
  int limitHours = defaultLimitHours;
  bool loading = false;
  bool saving = false;
  String? error;

  /// Verdadeiro só quando o último `load()` terminou com sucesso. Sem isso a
  /// tela não mostra a rotina salva, e salvar a substituiria (MP11).
  bool loaded = false;

  /// A grade e o limite só mudam com a rotina carregada.
  bool get canEdit => loaded && !loading;

  /// O último `load()` falhou: a tela oferece "Tentar de novo".
  bool get loadFailed => !loading && !loaded && error != null;

  bool isFree(int day, int row) => grid.isFree(day, row);

  int get freeHours => grid.freeHours;

  /// Só depois de carregar; e o backend responde 422 sem janelas.
  bool get canSave => loaded && !loading && !saving && !grid.isEmpty;

  /// Sem disponibilidade (`null`): grade vazia e limite de 4h.
  Future<void> load() async {
    loading = true;
    loaded = false;
    error = null;
    notifyListeners();
    try {
      final a = await _repo.getAvailability();
      grid = a == null
          ? RoutineGrid.empty()
          : RoutineGrid.fromWindows(a.windows);
      limitHours = a == null
          ? defaultLimitHours
          : (a.dailyLimitMinutes / 60).round().clamp(1, 8);
      loaded = true;
    } catch (_) {
      grid = RoutineGrid.empty();
      error = 'Não deu pra carregar sua rotina. Tenta de novo?';
    } finally {
      loading = false;
      // A tela pode ter sido fechada durante a carga.
      if (!_disposed) notifyListeners();
    }
  }

  void toggle(int day, int row) {
    if (!canEdit) return;
    grid = grid.toggle(day, row);
    notifyListeners();
  }

  void setLimitHours(int hours) {
    if (!canEdit) return;
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
      // A tela pode ter sido fechada durante o envio.
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
