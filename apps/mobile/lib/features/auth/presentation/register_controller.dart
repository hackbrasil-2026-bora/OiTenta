import 'package:flutter/foundation.dart';

import '../../../core/errors/app_errors.dart';
import '../data/auth_repository.dart';
import '../data/session_store.dart';
import '../domain/auth_rules.dart';

/// Criar conta (M34): `POST /auth/register` e, em seguida, `POST /auth/login`
/// (o cadastro não devolve token), como o web.
class RegisterController extends ChangeNotifier {
  RegisterController(this._auth, this._session);

  final AuthRepository _auth;
  final SessionStore _session;

  static const offline = 'Não deu pra criar sua conta agora. Tenta de novo?';
  static const createdButNotLogged =
      'Sua conta foi criada, mas não deu pra entrar agora. Tenta pelo login.';

  String name = '';
  String email = '';
  String password = '';
  String confirm = '';
  bool termsAccepted = false;

  /// As duas senhas ocultas (o olho de qualquer uma alterna as duas, como no
  /// protótipo).
  bool obscure = true;
  bool busy = false;
  String? error;

  bool get nameOk => AuthRules.isDisplayName(name);
  bool get emailOk => AuthRules.isEmail(email);
  bool get passwordOk => AuthRules.isStrongPassword(password);

  /// A dica da confirmação só aparece com o campo preenchido.
  bool get confirmVisible => confirm.isNotEmpty;
  bool get confirmOk => passwordOk && confirm == password;
  String get confirmText =>
      confirmOk ? 'As senhas batem' : 'As senhas ainda não estão iguais';

  bool get canSubmit => nameOk && emailOk && confirmOk && termsAccepted;

  /// Primeiro nome digitado, para o toast "Bem-vindo ao Bora, {nome}.".
  String get firstName => AuthRules.firstNameOf(name);

  void setName(String value) => _set(() => name = value);
  void setEmail(String value) => _set(() => email = value);
  void setPassword(String value) => _set(() => password = value);
  void setConfirm(String value) => _set(() => confirm = value);
  void toggleTerms() => _set(() => termsAccepted = !termsAccepted);
  void toggleObscure() => _set(() => obscure = !obscure);

  void _set(void Function() change) {
    change();
    notifyListeners();
  }

  /// Cria a conta sem fuso (vale `America/Sao_Paulo`, P1), entra e salva a
  /// sessão. Devolve `true` no sucesso.
  Future<bool> submit() async {
    if (busy || !canSubmit) return false;
    busy = true;
    error = null;
    notifyListeners();
    final mail = email.trim();
    try {
      try {
        await _auth.register(
          name: name.trim(),
          email: mail,
          password: password,
        );
      } on ConflictFailure catch (e) {
        error = e.message;
        return false;
      } on ValidationFailure catch (e) {
        error = '${e.message}';
        return false;
      } catch (_) {
        error = offline;
        return false;
      }
      try {
        _session.save(await _auth.login(email: mail, password: password));
        return true;
      } catch (_) {
        error = createdButNotLogged;
        return false;
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
