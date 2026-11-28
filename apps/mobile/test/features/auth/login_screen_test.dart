import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';
import 'package:oitenta/core/widgets/broto.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/presentation/login_controller.dart';
import 'package:oitenta/features/auth/presentation/login_screen.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';

import '../../helpers/test_app.dart';
import 'fake_auth_repository.dart';

const _demo = 'Entrar direto como Arthur (demo)';

/// Ações que a tela avisou.
final List<String> _taps = [];

/// Sobe o Entrar isolado, ligado a um [LoginController] com auth falso
/// (o mesmo papel do `LoginPage`, sem rotas).
Future<LoginController> _pump(
  WidgetTester tester, {
  bool showDemo = true,
  void Function(LoginController c)? setup,
}) async {
  await usePhoneSize(tester);
  _taps.clear();
  final c = LoginController(
    FakeAuthRepository(),
    SampleSchedulingRepository(),
    SessionStore(),
  );
  setup?.call(c);
  await tester.pumpWidget(
    themed(
      ListenableBuilder(
        listenable: c,
        builder: (_, _) => LoginScreen(
          state: c,
          showDemo: showDemo,
          onEmail: c.setEmail,
          onPassword: c.setPassword,
          onToggleObscure: c.toggleObscure,
          onSubmit: () => _taps.add('submit'),
          onForgot: () => _taps.add('forgot'),
          onRegister: () => _taps.add('register'),
          onDemo: () => _taps.add('demo'),
        ),
      ),
    ),
  );
  return c;
}

Finder _semantics(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

TextField _passwordField(WidgetTester tester) => tester.widget<TextField>(
  find.descendant(
    of: find.byKey(const Key('login-password')),
    matching: find.byType(TextField),
  ),
);

PrimaryButton _enter(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Entrar'));

void main() {
  testWidgets('mostra o Broto, os títulos, os rótulos e os placeholders', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(Broto), findsOneWidget);
    expect(find.text('Que bom te ver!'), findsOneWidget);
    expect(find.text('Entra aí pra continuar de onde parou.'), findsOneWidget);
    expect(find.text('E-MAIL'), findsOneWidget);
    expect(find.text('SENHA'), findsOneWidget);
    expect(find.text('seu@email.com'), findsOneWidget);
    expect(find.text('Sua senha'), findsOneWidget);
    expect(find.text('Ainda não tem conta?'), findsOneWidget);
  });

  testWidgets('"Entrar" fica desabilitado até e-mail e senha valerem', (
    tester,
  ) async {
    await _pump(tester);
    expect(_enter(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('login-email')), 'ana@bora');
    await tester.enterText(find.byKey(const Key('login-password')), 'segredo');
    await tester.pump();
    expect(_enter(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana@bora.app',
    );
    await tester.pump();
    expect(_enter(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Entrar'));
    expect(_taps, ['submit']);
  });

  testWidgets('"concluir" do teclado na senha entra só com os dados válidos', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byKey(const Key('login-password')), 'segredo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(_taps, isEmpty);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana@bora.app',
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('login-password')), 'segredo');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(_taps, ['submit']);
  });

  testWidgets('"Entrar" fica desabilitado enquanto entra (busy)', (
    tester,
  ) async {
    await _pump(
      tester,
      setup: (c) => c
        ..setEmail('ana@bora.app')
        ..setPassword('segredo')
        ..busy = true,
    );
    expect(_enter(tester).onPressed, isNull);
  });

  testWidgets('o olho alterna o texto oculto e o rótulo de acessibilidade', (
    tester,
  ) async {
    await _pump(tester);
    expect(_passwordField(tester).obscureText, isTrue);
    expect(_semantics('Mostrar senha'), findsOneWidget);

    await tester.tap(_semantics('Mostrar senha'));
    await tester.pump();
    expect(_passwordField(tester).obscureText, isFalse);
    expect(_semantics('Esconder senha'), findsOneWidget);

    await tester.tap(_semantics('Esconder senha'));
    await tester.pump();
    expect(_passwordField(tester).obscureText, isTrue);
  });

  testWidgets('"Esqueci minha senha" e "Criar conta" avisam a página', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.tap(find.text('Criar conta'));
    expect(_taps, ['forgot', 'register']);
  });

  testWidgets('o erro aparece numa região viva (Semantics.liveRegion)', (
    tester,
  ) async {
    await _pump(tester, setup: (c) => c.error = 'E-mail ou senha inválidos');
    expect(
      find.ancestor(
        of: find.text('E-mail ou senha inválidos'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sem erro, nada de região viva', (tester) async {
    await _pump(tester);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
      findsNothing,
    );
  });

  testWidgets('"Entrar com Google" e o divisor "ou" não aparecem (MP3)', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Entrar com Google'), findsNothing);
    expect(find.text('ou'), findsNothing);
  });

  testWidgets('com showDemo, o botão de demo aparece e avisa a página (MP5)', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.widgetWithText(TertiaryButton, _demo), findsOneWidget);
    await tester.tap(find.text(_demo));
    expect(_taps, ['demo']);
  });

  testWidgets('sem showDemo, o botão de demo não aparece (MP5)', (
    tester,
  ) async {
    await _pump(tester, showDemo: false);
    expect(find.text(_demo), findsNothing);
  });
}
