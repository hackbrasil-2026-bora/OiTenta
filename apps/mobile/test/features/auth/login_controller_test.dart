import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/auth/data/sample_auth_repository.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/presentation/login_controller.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/data/scheduling_repository.dart';

import 'fake_auth_repository.dart';

const _invalid = 'E-mail ou senha inválidos';
const _offline = 'Não deu pra entrar agora. Tenta de novo?';

void main() {
  late FakeAuthRepository auth;
  late SessionStore session;

  LoginController make({SchedulingRepository? scheduling}) => LoginController(
    auth,
    scheduling ?? SampleSchedulingRepository(),
    session,
  );

  /// Controlador com e-mail e senha válidos.
  LoginController filled({SchedulingRepository? scheduling}) =>
      make(scheduling: scheduling)
        ..setEmail('ana@bora.app')
        ..setPassword('segredo');

  setUp(() {
    auth = FakeAuthRepository();
    session = SessionStore();
  });

  group('canSubmit', () {
    for (final email in ['a@b', 'arthur', '']) {
      test('falso com e-mail inválido "$email"', () {
        final c = make()
          ..setEmail(email)
          ..setPassword('segredo');
        expect(c.canSubmit, isFalse);
      });
    }

    test('falso com senha de 5 caracteres', () {
      final c = make()
        ..setEmail('ana@bora.app')
        ..setPassword('12345');
      expect(c.canSubmit, isFalse);
    });

    test('verdadeiro com e-mail válido e senha de 6 caracteres', () {
      expect(filled().canSubmit, isTrue);
    });

    test('apara o e-mail antes de validar', () {
      final c = make()
        ..setEmail('  ana@bora.app  ')
        ..setPassword('segredo');
      expect(c.canSubmit, isTrue);
    });
  });

  test('setEmail e setPassword guardam o texto e avisam os ouvintes', () {
    final c = make();
    var n = 0;
    c.addListener(() => n++);
    c
      ..setEmail('x')
      ..setPassword('y');
    expect(c.email, 'x');
    expect(c.password, 'y');
    expect(n, 2);
  });

  test('toggleObscure troca obscure e avisa os ouvintes', () {
    final c = make();
    var n = 0;
    c.addListener(() => n++);
    expect(c.obscure, isTrue);
    c.toggleObscure();
    expect(c.obscure, isFalse);
    expect(n, 1);
  });

  group('submit', () {
    test('envia o e-mail aparado e a senha como digitada', () async {
      final c = make()
        ..setEmail('  ana@bora.app ')
        ..setPassword(' segredo ');
      await c.submit();
      expect(auth.loginArgs.single, {
        'email': 'ana@bora.app',
        'password': ' segredo ',
      });
    });

    test(
      'sucesso salva a sessão e, com disponibilidade, vai ao Hoje',
      () async {
        final c = filled();
        expect(await c.submit(), AfterLogin.today);
        expect(session.token, 'tok-login');
        expect(c.busy, isFalse);
        expect(c.error, isNull);
      },
    );

    test('sem disponibilidade (null) vai ao onboarding (P12)', () async {
      final c = filled(
        scheduling: SampleSchedulingRepository(hasAvailability: false),
      );
      expect(await c.submit(), AfterLogin.onboarding);
    });

    test('firstName vem do usuário da sessão ("Ana Souza" → "Ana")', () async {
      final c = filled();
      await c.submit();
      expect(c.firstName, 'Ana');
    });

    test('firstName sem sessão é vazio', () {
      expect(make().firstName, '');
    });

    test(
      '401 mostra "E-mail ou senha inválidos" e não salva a sessão',
      () async {
        auth.loginError = UnauthorizedFailure('Credenciais inválidas.');
        final c = filled();
        expect(await c.submit(), isNull);
        expect(c.error, _invalid);
        expect(session.session, isNull);
        expect(c.busy, isFalse);
      },
    );

    test('falha de rede mostra a mensagem de tentar de novo', () async {
      auth.loginError = NetworkFailure('sem rede');
      final c = filled();
      expect(await c.submit(), isNull);
      expect(c.error, _offline);
      expect(session.session, isNull);
    });

    test('outro erro do backend (500) mostra a mesma mensagem', () async {
      auth.loginError = ApiFailure(500, 'Erro interno.');
      final c = filled();
      await c.submit();
      expect(c.error, _offline);
    });

    test(
      'se a disponibilidade falhar depois do login, mostra o erro e desfaz a sessão',
      () async {
        final c = filled(scheduling: FailingAvailabilityRepository());
        expect(await c.submit(), isNull);
        expect(c.error, _offline);
        expect(session.session, isNull);
        expect(c.busy, isFalse);
      },
    );

    test('nova tentativa limpa o erro anterior', () async {
      auth.loginError = UnauthorizedFailure('x');
      final c = filled();
      await c.submit();
      auth.loginError = null;
      await c.submit();
      expect(c.error, isNull);
    });

    test('enquanto busy, um segundo submit é ignorado', () async {
      auth.loginGate = Completer<void>();
      final c = filled();
      final first = c.submit();
      expect(c.busy, isTrue);
      expect(await c.submit(), isNull);
      auth.loginGate!.complete();
      expect(await first, AfterLogin.today);
      expect(auth.calls, ['login']);
    });

    test('com canSubmit falso não chama o repositório', () async {
      final c = make()
        ..setEmail('arthur')
        ..setPassword('segredo');
      expect(await c.submit(), isNull);
      expect(auth.calls, isEmpty);
    });
  });

  group('enterDemo', () {
    test('demo com disponibilidade salva a sessão e vai para o Hoje', () async {
      final session = SessionStore();
      final c = LoginController(
        SampleAuthRepository(),
        SampleSchedulingRepository(),
        session,
      );
      final next = await c.enterDemo();
      expect(next, AfterLogin.today);
      expect(session.user!.name, 'Arthur');
      expect(c.busy, isFalse);
    });

    test('demo sem disponibilidade vai para o onboarding (P12)', () async {
      final c = LoginController(
        SampleAuthRepository(),
        SampleSchedulingRepository(hasAvailability: false),
        SessionStore(),
      );
      expect(await c.enterDemo(), AfterLogin.onboarding);
    });

    test('demo com erro mostra a mensagem e não salva a sessão', () async {
      auth.demoError = NetworkFailure('sem rede');
      final c = make();
      expect(await c.enterDemo(), isNull);
      expect(c.error, _offline);
      expect(session.session, isNull);
      expect(c.busy, isFalse);
    });

    test('demo enquanto busy é ignorado', () async {
      auth.loginGate = Completer<void>();
      final c = filled();
      final first = c.submit();
      expect(await c.enterDemo(), isNull);
      auth.loginGate!.complete();
      await first;
      expect(auth.calls, ['login']);
    });
  });
}
