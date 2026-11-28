import 'package:flutter/foundation.dart';

import '../../../core/errors/app_errors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/session_store.dart';

/// Editar perfil (AT3, sem design): troca o nome e/ou o e-mail com
/// `PATCH /auth/me`. Trocar o e-mail pede a senha atual. O id não muda.
class EditProfileController extends ChangeNotifier {
  EditProfileController(this._auth, this._session)
    : _originalName = _session.user?.name ?? '',
      _originalEmail = _session.user?.email ?? '',
      name = _session.user?.name ?? '',
      email = _session.user?.email ?? '';

  final AuthRepository _auth;
  final SessionStore _session;
  final String _originalName;
  final String _originalEmail;
  bool _disposed = false;

  String name;
  String email;
  String currentPassword = '';
  bool saving = false;
  String? error;

  static String _normalize(String email) => email.trim().toLowerCase();

  bool get nameChanged => name.trim() != _originalName.trim();

  bool get emailChanged => _normalize(email) != _normalize(_originalEmail);

  bool get _nameValid => name.trim().length >= 2;

  bool get _emailValid {
    final e = _normalize(email);
    final at = e.indexOf('@');
    return at > 0 && at < e.length - 1;
  }

  bool get canSave =>
      !saving &&
      (nameChanged || emailChanged) &&
      _nameValid &&
      _emailValid &&
      (!emailChanged || currentPassword.isNotEmpty);

  void setName(String value) => _edit(() => name = value);

  void setEmail(String value) => _edit(() => email = value);

  void setCurrentPassword(String value) => _edit(() => currentPassword = value);

  void _edit(VoidCallback change) {
    change();
    error = null;
    notifyListeners();
  }

  /// Grava e atualiza a sessão (o nome novo aparece no app todo).
  Future<bool> save() async {
    if (!canSave) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final user = await _auth.updateProfile(
        name: nameChanged ? name.trim() : null,
        email: emailChanged ? _normalize(email) : null,
        currentPassword: emailChanged ? currentPassword : null,
      );
      _session.updateUser(user);
      return true;
    } on ConflictFailure {
      error = 'Esse e-mail já está em uso em outra conta.';
      return false;
    } on ApiFailure catch (e) {
      error = e.statusCode == 403
          ? 'Senha atual incorreta.'
          : 'Não deu pra salvar. Tenta de novo?';
      return false;
    } on ValidationFailure {
      error = 'Confira o nome e o e-mail.';
      return false;
    } catch (_) {
      error = 'Não deu pra salvar. Tenta de novo?';
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
