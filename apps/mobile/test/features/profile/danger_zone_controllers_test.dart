import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';
import 'package:oitenta/features/profile/presentation/change_password_controller.dart';
import 'package:oitenta/features/profile/presentation/delete_account_controller.dart';

import '../auth/fake_auth_repository.dart';

const _ana = AuthUser(
  id: 'u1',
  name: 'Ana Souza',
  email: 'ana@bora.app',
  timezone: 'America/Sao_Paulo',
);

/// Zona de risco (AT9): trocar senha e apagar conta.
void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  group('ChangePasswordController', () {
    late ChangePasswordController c;
    setUp(() => c = ChangePasswordController(auth));

    test('só libera com a atual, a nova forte e a confirmação igual', () {
      expect(c.canSave, isFalse);
      c.setCurrent('Senha@123');
      c.setNew('fraca');
      c.setConfirm('fraca');
      expect(c.newIsStrong, isFalse);
      expect(c.canSave, isFalse);
      c.setNew('Nova@4567');
      expect(c.canSave, isFalse, reason: 'confirmação diferente');
      expect(c.confirmMismatch, isTrue);
      c.setConfirm('Nova@4567');
      expect(c.canSave, isTrue);
    });

    test('salvar chama o backend', () async {
      c
        ..setCurrent('Senha@123')
        ..setNew('Nova@4567')
        ..setConfirm('Nova@4567');
      expect(await c.save(), isTrue);
      expect(auth.calls, ['changePassword']);
    });

    test('senha atual errada (403) explica', () async {
      auth.changePasswordError = ApiFailure(403, 'Senha atual incorreta.');
      c
        ..setCurrent('errada')
        ..setNew('Nova@4567')
        ..setConfirm('Nova@4567');
      expect(await c.save(), isFalse);
      expect(c.error, 'Senha atual incorreta.');
    });

    test('sem rede: mensagem genérica', () async {
      auth.changePasswordError = NetworkFailure('sem rede');
      c
        ..setCurrent('Senha@123')
        ..setNew('Nova@4567')
        ..setConfirm('Nova@4567');
      await c.save();
      expect(c.error, 'Não deu pra trocar a senha. Tenta de novo?');
    });
  });

  group('DeleteAccountController', () {
    late SessionStore session;
    late DeleteAccountController c;
    setUp(() {
      session = SessionStore()..save(const AuthSession(token: 't', user: _ana));
      c = DeleteAccountController(auth, session);
    });

    test('só libera com a senha', () {
      expect(c.canDelete, isFalse);
      c.setPassword('Senha@123');
      expect(c.canDelete, isTrue);
    });

    test('apagar chama o backend e limpa a sessão', () async {
      c.setPassword('Senha@123');
      expect(await c.delete(), isTrue);
      expect(auth.calls, ['deleteAccount']);
      expect(session.session, isNull);
    });

    test(
      '403 mostra a mensagem do backend (senha errada ou conta demo)',
      () async {
        auth.deleteError = ApiFailure(
          403,
          'A conta demo não pode ser apagada.',
        );
        c.setPassword('Senha@123');
        expect(await c.delete(), isFalse);
        expect(c.error, 'A conta demo não pode ser apagada.');
        expect(session.token, 't', reason: 'continua logado');
      },
    );

    test('sem rede: mensagem genérica', () async {
      auth.deleteError = NetworkFailure('sem rede');
      c.setPassword('Senha@123');
      await c.delete();
      expect(c.error, 'Não deu pra apagar a conta. Tenta de novo?');
    });
  });
}
