import '../domain/auth_user.dart';

/// `POST /auth/login`, `/auth/register`, `/auth/demo`, `GET /auth/me` e
/// `PATCH /auth/me` (contrato §1).
abstract class AuthRepository {
  Future<AuthSession> loginDemo();

  Future<AuthSession> login({required String email, required String password});

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String? timezone,
  });

  /// `GET /auth/me`: o usuário do token atual.
  Future<AuthUser> me();

  /// `PATCH /auth/me` (AT3): troca o nome e/ou o e-mail. Trocar o e-mail pede
  /// [currentPassword]; senha errada é `ApiFailure` 403 (não desloga) e e-mail
  /// de outra conta é `ConflictFailure`.
  Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
  });

  /// `PATCH /auth/me/password` (AT9). Senha atual errada é `ApiFailure` 403;
  /// senha nova fraca é `ValidationFailure`.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// `DELETE /auth/me` (AT9): apaga a conta e todos os dados dela. Senha
  /// errada, ou a conta demo, é `ApiFailure` 403.
  Future<void> deleteAccount({required String currentPassword});
}
