import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/core/sample/bora_sample_data.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';
import 'package:oitenta/features/activation/data/sample_activation_repository.dart';
import 'package:oitenta/features/auth/data/auth_repository.dart';
import 'package:oitenta/features/auth/data/sample_auth_repository.dart';
import 'package:oitenta/features/auth/presentation/login_screen.dart';
import 'package:oitenta/features/auth/presentation/register_screen.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/goals/data/sample_goals_repository.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';

import '../../helpers/test_app.dart';
import 'fake_auth_repository.dart';

const _demo = 'Entrar direto como Arthur (demo)';
const _strong = 'Senha@123';
const _onboarding = '1 de 6';
const _today = 'Bom dia, Arthur';

AppDependencies _deps({
  AuthRepository? auth,
  bool hasAvailability = true,
  bool showDemo = true,
}) => AppDependencies(
  auth: auth ?? SampleAuthRepository(),
  scheduling: SampleSchedulingRepository(hasAvailability: hasAvailability),
  goals: SampleGoalsRepository(),
  activation: SampleActivationRepository(),
  gamification: SampleGamificationRepository(),
  clock: FixedClock(BoraSample.today),
  showDemo: showDemo,
);

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login-email')),
    ' arthur@bora.app ',
  );
  await tester.enterText(find.byKey(const Key('login-password')), 'segredo');
  await tester.pump();
  await tester.tap(find.widgetWithText(PrimaryButton, 'Entrar'));
  await tester.pumpAndSettle();
}

/// Deixa o toast sumir (o timer dele não pode ficar pendente no fim do teste).
Future<void> _waitToast(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

void main() {
  group('demo (MP5)', () {
    testWidgets('o demo leva ao Hoje', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text(_demo));
      await tester.pumpAndSettle();
      expect(find.text(_today), findsOneWidget);
    });

    testWidgets('demo sem disponibilidade vai para o onboarding', (
      tester,
    ) async {
      await pumpApp(tester, deps: _deps(hasAvailability: false));
      await tester.tap(find.text(_demo));
      await tester.pumpAndSettle();
      expect(find.text(_onboarding), findsOneWidget);
    });

    testWidgets('o LoginPage esconde o demo quando showDemo é falso', (
      tester,
    ) async {
      await pumpApp(tester, deps: _deps(showDemo: false));
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(_demo), findsNothing);
    });
  });

  group('Entrar com e-mail e senha', () {
    testWidgets('com disponibilidade vai ao Hoje com o toast (P12)', (
      tester,
    ) async {
      await pumpApp(tester, deps: _deps());
      await _login(tester);
      expect(find.text(_today), findsOneWidget);
      expect(find.text('Oi de novo, Arthur!'), findsOneWidget);
      expect(
        find.text('Seu plano tá do jeitinho que você deixou.'),
        findsOneWidget,
      );
      await _waitToast(tester);
      expect(find.text('Oi de novo, Arthur!'), findsNothing);
    });

    testWidgets('sem disponibilidade vai ao onboarding (P12)', (tester) async {
      final deps = _deps(hasAvailability: false);
      await pumpApp(tester, deps: deps);
      await _login(tester);
      expect(find.text(_onboarding), findsOneWidget);
      expect(deps.session.user!.email, 'arthur@bora.app');
      await _waitToast(tester);
    });

    testWidgets('401 fica no Entrar com "E-mail ou senha inválidos"', (
      tester,
    ) async {
      final auth = FakeAuthRepository()
        ..loginError = UnauthorizedFailure('Credenciais inválidas.');
      final deps = _deps(auth: auth);
      await pumpApp(tester, deps: deps);
      await _login(tester);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('E-mail ou senha inválidos'), findsOneWidget);
      expect(deps.session.session, isNull);
    });

    testWidgets('o olho mostra e esconde a senha', (tester) async {
      await pumpApp(tester);
      bool obscured() => tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('login-password')),
              matching: find.byType(TextField),
            ),
          )
          .obscureText;
      expect(obscured(), isTrue);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Mostrar senha',
        ),
      );
      await tester.pump();
      expect(obscured(), isFalse);
    });
  });

  group('Criar conta', () {
    Future<void> openRegister(WidgetTester tester) async {
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    }

    testWidgets('cria, entra e cai no onboarding com o toast (4b)', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      final deps = _deps(auth: auth, hasAvailability: false);
      await pumpApp(tester, deps: deps);
      await openRegister(tester);

      await tester.enterText(
        find.byKey(const Key('register-name')),
        'Ana Souza',
      );
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'ana@bora.app',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        _strong,
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm')),
        _strong,
      );
      await tester.tap(
        find.text('Li e aceito os Termos de uso e a Política de privacidade'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'Criar conta'));
      await tester.pumpAndSettle();

      expect(auth.calls, ['register', 'login']);
      expect(deps.session.token, 'tok-login');
      expect(find.text(_onboarding), findsOneWidget);
      expect(find.text('Conta criada!'), findsOneWidget);
      expect(find.text('Bem-vindo ao Bora, Ana.'), findsOneWidget);
      await _waitToast(tester);
    });

    testWidgets('409 fica no Criar conta com a mensagem do backend', (
      tester,
    ) async {
      final auth = FakeAuthRepository()
        ..registerError = ConflictFailure('E-mail já cadastrado.');
      await pumpApp(tester, deps: _deps(auth: auth));
      await openRegister(tester);
      await tester.enterText(find.byKey(const Key('register-name')), 'Ana');
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'ana@bora.app',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        _strong,
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm')),
        _strong,
      );
      await tester.tap(
        find.text('Li e aceito os Termos de uso e a Política de privacidade'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'Criar conta'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('E-mail já cadastrado.'), findsOneWidget);
    });

    testWidgets('"Já tem conta? Entrar" volta ao Entrar', (tester) async {
      await pumpApp(tester);
      await openRegister(tester);
      await tester.tap(find.widgetWithText(TertiaryButton, 'Entrar'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    });

    testWidgets('o voltar do topo volta ao Entrar', (tester) async {
      await pumpApp(tester);
      await openRegister(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Voltar',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('aberto direto (sem pilha), "Entrar" vai para /entrar', (
      tester,
    ) async {
      await pumpApp(tester, location: '/cadastro');
      await tester.tap(find.widgetWithText(TertiaryButton, 'Entrar'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  testWidgets('Esqueci → placeholder → "Voltar pro login" → Entrar (MP4)', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    await tester.tap(find.text('Voltar pro login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
