import 'package:flutter/foundation.dart';

import '../../../core/errors/app_errors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/session_store.dart';

/// Apagar conta (AT9, sem design): `DELETE /auth/me` com a senha. Apaga de
/// verdade a conta e todos os dados; depois, a sessão é limpa.
class DeleteAccountController extends ChangeNotifier {
  DeleteAccountController(this._auth, this._session);

  final AuthRepository _auth;
  final SessionStore _session;
  bool _disposed = false;

  String password = '';
  bool deleting = false;
  String? error;

  bool get canDelete => !deleting && password.isNotEmpty;

  void setPassword(String v) {
    password = v;
    error = null;
    notifyListeners();
  }

  Future<bool> delete() async {
    if (!canDelete) return false;
    deleting = true;
    error = null;
    notifyListeners();
    try {
      await _auth.deleteAccount(currentPassword: password);
      _session.clear();
      return true;
    } on ApiFailure catch (e) {
      // 403: "Senha atual incorreta." ou "A conta demo não pode ser apagada."
      error = e.statusCode == 403
          ? e.message
          : 'Não deu pra apagar a conta. Tenta de novo?';
      return false;
    } catch (_) {
      error = 'Não deu pra apagar a conta. Tenta de novo?';
      return false;
    } finally {
      deleting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
