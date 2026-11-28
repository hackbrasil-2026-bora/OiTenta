import 'package:flutter/foundation.dart';

import '../../auth/data/session_store.dart';
import '../data/gamification_repository.dart';
import '../domain/gamification.dart';
import '../domain/garden.dart';

/// Jardim (M04). Só leitura: "Trocar por 50" não tem ação (MP13).
class GardenController extends ChangeNotifier {
  GardenController(this._repo, this._session);

  final GamificationRepository _repo;
  final SessionStore _session;

  bool loading = true;
  String? error;
  Garden? garden;

  /// Números da barra do topo.
  GamificationSnapshot? gamification;

  String get userName => _session.user?.name ?? '';

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      gamification = await _repo.getSnapshot();
      garden = await _repo.getGarden();
    } catch (_) {
      error = 'Não deu pra carregar o seu jardim.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
