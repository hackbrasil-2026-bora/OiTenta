import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';
import 'package:oitenta/features/profile/presentation/edit_profile_controller.dart';

import '../auth/fake_auth_repository.dart';

const _ana = AuthUser(
  id: 'u1',
  name: 'Ana Souza',
  email: 'ana@bora.app',
  timezone: 'America/Sao_Paulo',
);

/// Editar perfil (AT3): nome e e-mail; o e-mail pede a senha atual.
void main() {
  late FakeAuthRepository auth;
  late SessionStore session;
  late EditProfileController c;

  setUp(() {
    auth = FakeAuthRepository();
    session = SessionStore()..save(const AuthSession(token: 't', user: _ana));
    c = EditProfileController(auth, session);
  });

  test('começa com o nome e o e-mail da sessão, sem poder salvar', () {
    expect(c.name, 'Ana Souza');
    expect(c.email, 'ana@bora.app');
    expect(c.emailChanged, isFalse);
    expect(c.canSave, isFalse, reason: 'nada mudou');
  });

  test('trocar só o nome salva sem senha e atualiza a sessão', () async {
    c.setName('Ana Clara');
    expect(c.canSave, isTrue);

    final ok = await c.save();

    expect(ok, isTrue);
    expect(auth.updateArgs.single, {
      'name': 'Ana Clara',
      'email': null,
      'currentPassword': null,
    });
    expect(session.user!.name, 'Ana Clara');
  });

  test('trocar o e-mail pede a senha atual antes de liberar', () {
    c.setEmail('ana.nova@bora.app');
    expect(c.emailChanged, isTrue);
    expect(c.canSave, isFalse, reason: 'falta a senha atual');

    c.setCurrentPassword('Senha@123');
    expect(c.canSave, isTrue);
  });

  test('o mesmo e-mail com maiúsculas e espaços não conta como troca', () {
    c.setEmail('  ANA@bora.app ');
    expect(c.emailChanged, isFalse);
  });

  test('trocar o e-mail manda o e-mail e a senha atual', () async {
    c.setEmail('ana.nova@bora.app');
    c.setCurrentPassword('Senha@123');

    await c.save();

    expect(auth.updateArgs.single, {
      'name': null,
      'email': 'ana.nova@bora.app',
      'currentPassword': 'Senha@123',
    });
    expect(session.user!.email, 'ana.nova@bora.app');
  });

  test('nome com menos de 2 letras ou e-mail sem @ não libera', () {
    c.setName('A');
    expect(c.canSave, isFalse);
    c.setName('Ana Clara');
    c.setEmail('ana.bora.app');
    c.setCurrentPassword('Senha@123');
    expect(c.canSave, isFalse);
  });

  test('senha atual errada (403) mostra a mensagem e não desloga', () async {
    auth.updateError = ApiFailure(403, 'Senha atual incorreta.');
    c.setEmail('ana.nova@bora.app');
    c.setCurrentPassword('errada');

    final ok = await c.save();

    expect(ok, isFalse);
    expect(c.error, 'Senha atual incorreta.');
    expect(session.user!.email, 'ana@bora.app');
    expect(session.token, 't');
  });

  test('e-mail de outra conta (409) explica', () async {
    auth.updateError = ConflictFailure('E-mail já cadastrado.');
    c.setEmail('bia@bora.app');
    c.setCurrentPassword('Senha@123');

    await c.save();

    expect(c.error, 'Esse e-mail já está em uso em outra conta.');
  });

  test('erro de validação (422) pede para conferir', () async {
    auth.updateError = ValidationFailure('Dados inválidos.');
    c.setName('Ana 123');

    await c.save();

    expect(c.error, 'Confira o nome e o e-mail.');
  });

  test('sem rede mostra a mensagem genérica', () async {
    auth.updateError = NetworkFailure('sem rede');
    c.setName('Ana Clara');

    await c.save();

    expect(c.error, 'Não deu pra salvar. Tenta de novo?');
  });

  test('editar limpa o erro anterior', () async {
    auth.updateError = NetworkFailure('sem rede');
    c.setName('Ana Clara');
    await c.save();

    c.setName('Ana Clara Souza');

    expect(c.error, isNull);
  });
}
