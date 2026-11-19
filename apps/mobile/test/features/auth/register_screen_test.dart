import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/theme/bora_colors.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/presentation/register_controller.dart';
import 'package:oitenta/features/auth/presentation/register_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../helpers/test_app.dart';
import 'fake_auth_repository.dart';

const _hint =
    'Mínimo de 8 caracteres, com maiúscula, minúscula, número e símbolo';
const _terms = 'Li e aceito os Termos de uso e a Política de privacidade';
const _strong = 'Senha@123';

final List<String> _taps = [];

/// Sobe o Criar conta isolado, ligado a um [RegisterController] com auth
/// falso (o mesmo papel do `RegisterPage`, sem rotas).
Future<RegisterController> _pump(
  WidgetTester tester, {
  void Function(RegisterController c)? setup,
}) async {
  await usePhoneSize(tester);
  _taps.clear();
  final c = RegisterController(FakeAuthRepository(), SessionStore());
  setup?.call(c);
  await tester.pumpWidget(
    themed(
      ListenableBuilder(
        listenable: c,
        builder: (_, _) => RegisterScreen(
          state: c,
          onName: c.setName,
          onEmail: c.setEmail,
          onPassword: c.setPassword,
          onConfirm: c.setConfirm,
          onToggleObscure: c.toggleObscure,
          onToggleTerms: c.toggleTerms,
          onSubmit: () => _taps.add('submit'),
          onBack: () => _taps.add('back'),
          onLogin: () => _taps.add('login'),
        ),
      ),
    ),
  );
  return c;
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

Icon _hintIcon(WidgetTester tester, String key) =>
    tester.widget<Icon>(find.byKey(Key(key)));

PrimaryButton _create(WidgetTester tester) => tester.widget<PrimaryButton>(
  find.widgetWithText(PrimaryButton, 'Criar conta'),
);

Finder _semantics(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

void main() {
  testWidgets('voltar, título, subtítulo, os 4 rótulos e os placeholders', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Criar sua conta'), findsOneWidget);
    expect(
      find.text('Leva menos de 1 minuto. Depois eu te ajudo a montar o plano.'),
      findsOneWidget,
    );
    for (final label in [
      'COMO QUER SER CHAMADO?',
      'E-MAIL',
      'SENHA',
      'CONFIRME SUA SENHA',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final hint in [
      'Ex.: Arthur',
      'seu@email.com',
      'Crie uma senha',
      'Digite a senha de novo',
    ]) {
      expect(find.text(hint), findsOneWidget, reason: hint);
    }
    await tester.tap(_semantics('Voltar'));
    expect(_taps, ['back']);
  });

  testWidgets('a dica da senha (MP1) fica verde quando a senha vale', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text(_hint), findsOneWidget);
    var icon = _hintIcon(tester, 'register-password-hint-icon');
    expect(icon.icon, PhosphorIconsRegular.circle);
    expect(icon.color, BoraColors.light.tx2);

    await _type(tester, 'register-password', '123456');
    icon = _hintIcon(tester, 'register-password-hint-icon');
    expect(icon.icon, PhosphorIconsRegular.circle);

    await _type(tester, 'register-password', _strong);
    icon = _hintIcon(tester, 'register-password-hint-icon');
    expect(icon.icon, PhosphorIconsFill.checkCircle);
    expect(icon.color, BoraColors.light.pri);
  });

  testWidgets('a confirmação só aparece preenchida, com as duas mensagens', (
    tester,
  ) async {
    await _pump(tester);
    await _type(tester, 'register-password', _strong);
    expect(find.text('As senhas batem'), findsNothing);
    expect(find.text('As senhas ainda não estão iguais'), findsNothing);

    await _type(tester, 'register-confirm', 'Senha@');
    expect(find.text('As senhas ainda não estão iguais'), findsOneWidget);
    var icon = _hintIcon(tester, 'register-confirm-hint-icon');
    expect(icon.icon, PhosphorIconsRegular.info);
    expect(icon.color, BoraColors.light.blue);

    await _type(tester, 'register-confirm', _strong);
    expect(find.text('As senhas batem'), findsOneWidget);
    icon = _hintIcon(tester, 'register-confirm-hint-icon');
    expect(icon.icon, PhosphorIconsFill.checkCircle);
    expect(icon.color, BoraColors.light.pri);
  });

  testWidgets('o olho alterna as duas senhas', (tester) async {
    await _pump(tester);
    List<bool> obscured() => [
      for (final k in ['register-password', 'register-confirm'])
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(Key(k)),
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
    ];
    expect(obscured(), [true, true]);
    await tester.tap(_semantics('Mostrar senha').first);
    await tester.pump();
    expect(obscured(), [false, false]);
    expect(_semantics('Esconder senha'), findsNWidgets(2));
  });

  testWidgets('a caixa dos termos alterna ao tocar no texto', (tester) async {
    final c = await _pump(tester);
    expect(find.text(_terms), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.check), findsNothing);
    await tester.tap(find.text(_terms));
    await tester.pump();
    expect(c.termsAccepted, isTrue);
    expect(find.byIcon(PhosphorIconsBold.check), findsOneWidget);
  });

  testWidgets('"Criar conta" desabilitado até tudo valer', (tester) async {
    await _pump(tester);
    expect(_create(tester).onPressed, isNull);
    await _type(tester, 'register-name', 'Arthur');
    await _type(tester, 'register-email', 'arthur@email.com');
    await _type(tester, 'register-password', _strong);
    await _type(tester, 'register-confirm', _strong);
    expect(_create(tester).onPressed, isNull, reason: 'sem os termos');

    await tester.tap(find.text(_terms));
    await tester.pump();
    expect(_create(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Criar conta'));
    expect(_taps, ['submit']);
  });

  testWidgets('"Criar conta" desabilitado enquanto cria (busy)', (
    tester,
  ) async {
    await _pump(
      tester,
      setup: (c) => c
        ..setName('Arthur')
        ..setEmail('arthur@email.com')
        ..setPassword(_strong)
        ..setConfirm(_strong)
        ..toggleTerms()
        ..busy = true,
    );
    expect(_create(tester).onPressed, isNull);
  });

  testWidgets('"Já tem conta? Entrar" avisa a página', (tester) async {
    await _pump(tester);
    expect(find.text('Já tem conta?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TertiaryButton, 'Entrar'));
    expect(_taps, ['login']);
  });

  testWidgets('o erro do backend aparece numa região viva', (tester) async {
    await _pump(tester, setup: (c) => c.error = 'E-mail já cadastrado.');
    expect(
      find.ancestor(
        of: find.text('E-mail já cadastrado.'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      ),
      findsOneWidget,
    );
  });
}
