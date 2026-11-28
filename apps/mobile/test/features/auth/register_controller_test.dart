import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/presentation/register_controller.dart';

import 'fake_auth_repository.dart';

const _strong = 'Senha@123';

void main() {
  late FakeAuthRepository auth;
  late SessionStore session;

  RegisterController make() => RegisterController(auth, session);

  /// Formulário todo válido, com os termos aceitos.
  RegisterController filled() => make()
    ..setName('  Ana Souza ')
    ..setEmail(' ana@bora.app ')
    ..setPassword(_strong)
    ..setConfirm(_strong)
    ..toggleTerms();

  setUp(() {
    auth = FakeAuthRepository();
    session = SessionStore();
  });

  group('nameOk (MP2)', () {
    test('"Arthur" (uma palavra) vale', () {
      expect((make()..setName('Arthur')).nameOk, isTrue);
    });
    test('2 caracteres depois de aparar valem', () {
      expect((make()..setName('  Al ')).nameOk, isTrue);
    });
    test('1 caractere depois de aparar não vale', () {
      expect((make()..setName('  A  ')).nameOk, isFalse);
    });
    test('com número não vale', () {
      expect((make()..setName('Arthur2')).nameOk, isFalse);
    });
  });

  group('emailOk', () {
    test('e-mail válido aparado', () {
      expect((make()..setEmail(' ana@bora.app ')).emailOk, isTrue);
    });
    test('e-mail inválido', () {
      expect((make()..setEmail('ana@bora')).emailOk, isFalse);
    });
  });

  group('passwordOk (MP1)', () {
    test('8+ com maiúscula, minúscula, número e símbolo vale', () {
      expect((make()..setPassword(_strong)).passwordOk, isTrue);
    });
    test('6 caracteres simples não valem', () {
      expect((make()..setPassword('123456')).passwordOk, isFalse);
    });
    test('sem símbolo não vale', () {
      expect((make()..setPassword('Senha1234')).passwordOk, isFalse);
    });
  });

  group('confirmação', () {
    test('confirmVisible só com a confirmação preenchida', () {
      final c = make()..setPassword(_strong);
      expect(c.confirmVisible, isFalse);
      c.setConfirm('S');
      expect(c.confirmVisible, isTrue);
    });

    test('senhas iguais e válidas: confirmOk e "As senhas batem"', () {
      final c = make()
        ..setPassword(_strong)
        ..setConfirm(_strong);
      expect(c.confirmOk, isTrue);
      expect(c.confirmText, 'As senhas batem');
    });

    test('senhas diferentes: "As senhas ainda não estão iguais"', () {
      final c = make()
        ..setPassword(_strong)
        ..setConfirm('Senha@124');
      expect(c.confirmOk, isFalse);
      expect(c.confirmText, 'As senhas ainda não estão iguais');
    });

    test('iguais mas fracas não batem (exige passwordOk)', () {
      final c = make()
        ..setPassword('123456')
        ..setConfirm('123456');
      expect(c.confirmOk, isFalse);
      expect(c.confirmText, 'As senhas ainda não estão iguais');
    });
  });

  test('toggleTerms e toggleObscure alternam e avisam os ouvintes', () {
    final c = make();
    var n = 0;
    c.addListener(() => n++);
    expect(c.termsAccepted, isFalse);
    expect(c.obscure, isTrue);
    c
      ..toggleTerms()
      ..toggleObscure();
    expect(c.termsAccepted, isTrue);
    expect(c.obscure, isFalse);
    expect(n, 2);
  });

  test('os setters guardam o texto e avisam os ouvintes', () {
    final c = make();
    var n = 0;
    c.addListener(() => n++);
    c
      ..setName('a')
      ..setEmail('b')
      ..setPassword('c')
      ..setConfirm('d');
    expect([c.name, c.email, c.password, c.confirm], ['a', 'b', 'c', 'd']);
    expect(n, 4);
  });

  group('canSubmit', () {
    test('verdadeiro com tudo válido e termos aceitos', () {
      expect(filled().canSubmit, isTrue);
    });
    test('falso sem os termos', () {
      expect((filled()..toggleTerms()).canSubmit, isFalse);
    });
    test('falso com nome inválido', () {
      expect((filled()..setName('A')).canSubmit, isFalse);
    });
    test('falso com e-mail inválido', () {
      expect((filled()..setEmail('ana')).canSubmit, isFalse);
    });
    test('falso com a confirmação diferente', () {
      expect((filled()..setConfirm('Senha@999')).canSubmit, isFalse);
    });
  });

  test('firstName: "Ana Souza" → "Ana" (toast de boas-vindas)', () {
    expect(filled().firstName, 'Ana');
  });

  group('submit', () {
    test(
      'register (nome e e-mail aparados, sem fuso) → login → sessão salva',
      () async {
        final c = filled();
        expect(await c.submit(), isTrue);
        expect(auth.calls, ['register', 'login']);
        expect(auth.registerArgs.single, {
          'name': 'Ana Souza',
          'email': 'ana@bora.app',
          'password': _strong,
          'timezone': null,
        });
        expect(auth.loginArgs.single, {
          'email': 'ana@bora.app',
          'password': _strong,
        });
        expect(session.token, 'tok-login');
        expect(c.busy, isFalse);
        expect(c.error, isNull);
      },
    );

    test('409 mostra a message do backend e não salva a sessão', () async {
      auth.registerError = ConflictFailure('E-mail já cadastrado.');
      final c = filled();
      expect(await c.submit(), isFalse);
      expect(c.error, 'E-mail já cadastrado.');
      expect(auth.calls, ['register']);
      expect(session.session, isNull);
      expect(c.busy, isFalse);
    });

    test('422 mostra a message do backend e não salva a sessão', () async {
      auth.registerError = ValidationFailure('Nome inválido.');
      final c = filled();
      expect(await c.submit(), isFalse);
      expect(c.error, 'Nome inválido.');
      expect(session.session, isNull);
    });

    test('falha de rede no register mostra a mensagem genérica', () async {
      auth.registerError = NetworkFailure('sem rede');
      final c = filled();
      expect(await c.submit(), isFalse);
      expect(c.error, 'Não deu pra criar sua conta agora. Tenta de novo?');
      expect(session.session, isNull);
    });

    test(
      'register ok e login com erro: mensagem e nenhuma sessão salva',
      () async {
        auth.loginError = NetworkFailure('sem rede');
        final c = filled();
        expect(await c.submit(), isFalse);
        expect(auth.calls, ['register', 'login']);
        expect(
          c.error,
          'Sua conta foi criada, mas não deu pra entrar agora. Tenta pelo login.',
        );
        expect(session.session, isNull);
        expect(c.busy, isFalse);
      },
    );

    test('com canSubmit falso não chama o repositório', () async {
      final c = filled()..toggleTerms();
      expect(await c.submit(), isFalse);
      expect(auth.calls, isEmpty);
    });

    test('enquanto busy, um segundo submit é ignorado', () async {
      auth.loginGate = Completer();
      final c = filled();
      final first = c.submit();
      expect(c.busy, isTrue);
      expect(await c.submit(), isFalse);
      auth.loginGate!.complete();
      expect(await first, isTrue);
      expect(auth.calls, ['register', 'login']);
    });

    test('nova tentativa limpa o erro anterior', () async {
      auth.registerError = ConflictFailure('E-mail já cadastrado.');
      final c = filled();
      await c.submit();
      auth.registerError = null;
      await c.submit();
      expect(c.error, isNull);
    });
  });
}
