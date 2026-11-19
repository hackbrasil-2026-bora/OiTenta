import 'package:flutter/foundation.dart';

import '../../../core/errors/app_errors.dart';
import '../../scheduling/data/scheduling_repository.dart';
import '../data/auth_repository.dart';
import '../data/session_store.dart';
import '../domain/auth_rules.dart';
import '../domain/auth_user.dart';

/// Para onde ir depois do login (P12).
enum AfterLogin { today, onboarding }

/// Entrar (M33): e-mail e senha (`POST /auth/login`) e o botão de demo (MP5).
class LoginController extends ChangeNotifier {
  LoginController(this._auth, this._scheduling, this._session);

  final AuthRepository _auth;
  final SchedulingRepository _scheduling;
  final SessionStore _session;

  static const invalidCredentials = 'E-mail ou senha inválidos';
  static const offline = 'Não deu pra entrar agora. Tenta de novo?';

  String email = '';
  String password = '';

  /// Senha oculta (o olho alterna).
  bool obscure = true;
  bool busy = false;
  String? error;

  /// Como no protótipo: e-mail válido e senha de 6 ou mais caracteres.
  bool get canSubmit => AuthRules.isEmail(email) && password.length >= 6;

  /// Primeiro nome do usuário logado, para o toast "Oi de novo, {nome}!".
  String get firstName => AuthRules.firstNameOf(_session.user?.name ?? '');

  void setEmail(String value) {
    email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    password = value;
    notifyListeners();
  }

  void toggleObscure() {
    obscure = !obscure;
    notifyListeners();
  }

  /// `POST /auth/login` e, depois, a disponibilidade decide o destino (P12).
  Future<AfterLogin?> submit() async {
    if (busy || !canSubmit) return null;
    return _enter(
      () => _auth.login(email: email.trim(), password: password),
      onUnauthorized: invalidCredentials,
    );
  }

  /// `POST /auth/demo` e, se o usuário ainda não tem disponibilidade, onboarding.
  Future<AfterLogin?> enterDemo() async {
    if (busy) return null;
    return _enter(_auth.loginDemo, onUnauthorized: offline);
  }

  Future<AfterLogin?> _enter(
    Future<AuthSession> Function() login, {
    required String onUnauthorized,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final AuthSession session;
      try {
        session = await login();
      } on UnauthorizedFailure {
        error = onUnauthorized;
        return null;
      } catch (_) {
        error = offline;
        return null;
      }
      _session.save(session);
      try {
        final availability = await _scheduling.getAvailability();
        return availability == null ? AfterLogin.onboarding : AfterLogin.today;
      } catch (_) {
        // Sem saber o destino, a sessão não fica pela metade.
        _session.clear();
        error = offline;
        return null;
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
