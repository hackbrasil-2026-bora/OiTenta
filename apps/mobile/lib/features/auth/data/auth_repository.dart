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
}
