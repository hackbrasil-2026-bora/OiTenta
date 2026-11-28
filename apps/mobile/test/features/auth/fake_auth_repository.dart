import 'dart:async';

import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/auth/data/auth_repository.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/availability.dart';

/// Auth falso para os controladores: grava as chamadas (na ordem) e falha
/// quando o teste mandar.
class FakeAuthRepository implements AuthRepository {
  /// Nome do usuário devolvido pelo `login` (o backend devolve o nome salvo).
  String loginName = 'Ana Souza';

  /// Erros a lançar em cada chamada (nulo = sucesso).
  Object? loginError;
  Object? registerError;
  Object? demoError;

  /// Segura o `login` até o teste completar (para testar o `busy`).
  Completer<void>? loginGate;

  /// Ordem das chamadas: `register`, `login`, `demo`, `me`.
  final List<String> calls = [];
  final List<Map<String, Object?>> loginArgs = [];
  final List<Map<String, Object?>> registerArgs = [];

  AuthUser _user(String name, String email) => AuthUser(
    id: 'u1',
    name: name,
    email: email,
    timezone: 'America/Sao_Paulo',
  );

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    calls.add('login');
    loginArgs.add({'email': email, 'password': password});
    if (loginGate != null) await loginGate!.future;
    if (loginError != null) throw loginError!;
    return AuthSession(token: 'tok-login', user: _user(loginName, email));
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String? timezone,
  }) async {
    calls.add('register');
    registerArgs.add({
      'name': name,
      'email': email,
      'password': password,
      'timezone': timezone,
    });
    if (registerError != null) throw registerError!;
    return _user(name, email);
  }

  @override
  Future<AuthSession> loginDemo() async {
    calls.add('demo');
    if (demoError != null) throw demoError!;
    return AuthSession(
      token: 'tok-demo',
      user: _user('Arthur', 'arthur@bora.app'),
    );
  }

  /// Erro a lançar no `updateProfile` (nulo = sucesso).
  Object? updateError;
  final List<Map<String, Object?>> updateArgs = [];

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
  }) async {
    calls.add('update');
    updateArgs.add({
      'name': name,
      'email': email,
      'currentPassword': currentPassword,
    });
    if (updateError != null) throw updateError!;
    return _user(name ?? loginName, email ?? 'ana@bora.app');
  }

  /// Erros de changePassword e deleteAccount (nulo = sucesso).
  Object? changePasswordError;
  Object? deleteError;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    calls.add('changePassword');
    if (changePasswordError != null) throw changePasswordError!;
  }

  @override
  Future<void> deleteAccount({required String currentPassword}) async {
    calls.add('deleteAccount');
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<AuthUser> me() async {
    calls.add('me');
    return _user(loginName, 'ana@bora.app');
  }
}

/// Disponibilidade que falha (rede) depois do login.
class FailingAvailabilityRepository extends SampleSchedulingRepository {
  @override
  Future<WeeklyAvailability?> getAvailability() async =>
      throw NetworkFailure('sem rede');
}
