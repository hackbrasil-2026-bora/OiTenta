import 'package:flutter/foundation.dart';

import '../../../core/errors/app_errors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_rules.dart';

/// Trocar senha (AT9, sem design): `PATCH /auth/me/password` com a senha
/// atual, a nova (forte, como no cadastro) e a confirmação.
class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController(this._auth);

  final AuthRepository _auth;
  bool _disposed = false;

  String current = '';
  String newPassword = '';
  String confirm = '';
  bool saving = false;
  String? error;

  bool get newIsStrong => AuthRules.isStrongPassword(newPassword);

  bool get confirmMismatch => confirm.isNotEmpty && confirm != newPassword;

  bool get canSave =>
      !saving && current.isNotEmpty && newIsStrong && confirm == newPassword;

  void setCurrent(String v) => _edit(() => current = v);

  void setNew(String v) => _edit(() => newPassword = v);

  void setConfirm(String v) => _edit(() => confirm = v);

  void _edit(VoidCallback change) {
    change();
    error = null;
    notifyListeners();
  }

  Future<bool> save() async {
    if (!canSave) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _auth.changePassword(
        currentPassword: current,
        newPassword: newPassword,
      );
      return true;
    } on ApiFailure catch (e) {
      error = e.statusCode == 403
          ? 'Senha atual incorreta.'
          : 'Não deu pra trocar a senha. Tenta de novo?';
      return false;
    } on ValidationFailure {
      error =
          'A senha nova precisa de 8 caracteres, com maiúscula, '
          'minúscula, número e símbolo.';
      return false;
    } catch (_) {
      error = 'Não deu pra trocar a senha. Tenta de novo?';
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
