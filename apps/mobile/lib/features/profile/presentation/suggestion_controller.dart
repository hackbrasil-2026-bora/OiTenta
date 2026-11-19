import 'package:flutter/foundation.dart';

import '../data/feedback_repository.dart';

/// Enviar sugestão (M29). Só visual nesta fase (MP9): o repositório de
/// exemplo guarda o texto em memória.
class SuggestionController extends ChangeNotifier {
  SuggestionController(this._repo);

  final FeedbackRepository _repo;

  String text = '';
  bool busy = false;
  String? error;

  bool get canSend => text.trim().isNotEmpty && !busy;

  void setText(String value) {
    text = value;
    notifyListeners();
  }

  /// Envia o texto aparado. Não envia duas vezes enquanto [busy].
  Future<bool> send() async {
    if (!canSend) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _repo.send(text.trim());
      return true;
    } catch (_) {
      error = 'Não deu pra enviar agora. Tenta de novo?';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
