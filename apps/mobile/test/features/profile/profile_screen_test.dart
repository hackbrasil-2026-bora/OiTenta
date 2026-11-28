import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/theme/theme_controller.dart';
import 'package:oitenta/core/widgets/bora_widgets.dart';
import 'package:oitenta/features/auth/data/sample_auth_repository.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/profile/presentation/profile_controller.dart';
import 'package:oitenta/features/profile/presentation/profile_screen.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';

import '../../helpers/test_app.dart';

/// Perfil (M26): a tela só mostra o estado do [ProfileController] e avisa
/// os toques pelos callbacks.
void main() {
  late ProfileController state;
  late Map<String, int> taps;

  Future<void> pump(WidgetTester tester) async {
    await usePhoneSize(tester);
    taps = {};
    void tap(String k) => taps[k] = (taps[k] ?? 0) + 1;
    await tester.pumpWidget(
      themed(
        ListenableBuilder(
          listenable: state,
          builder: (_, _) => ProfileScreen(
            state: state,
            onBack: () => tap('back'),
            onToggleDark: () => tap('dark'),
            onToggleBlockApps: () => tap('block'),
            onRoutine: () => tap('routine'),
            onLanguage: () => tap('language'),
            onSuggestion: () => tap('suggestion'),
            onEditProfile: () => tap('edit'),
            onToggleDailyEmail: () => tap('email'),
            onDailyLimit: () => tap('limit'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    state = ProfileController(
      SampleAuthRepository(),
      SampleSchedulingRepository(),
      SessionStore(),
      ThemeController(),
    );
    await state.load();
  });

  testWidgets('avatar com a inicial, o nome e o e-mail', (tester) async {
    await pump(tester);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Arthur'), findsOneWidget);
    expect(find.text('arthur@bora.app'), findsOneWidget);
  });

  testWidgets('seção Preferências com os valores do design', (tester) async {
    await pump(tester);
    expect(find.text('PREFERÊNCIAS'), findsOneWidget);
    expect(find.text('Modo escuro'), findsOneWidget);
    expect(find.text('Tema atual: Claro'), findsOneWidget);
    expect(find.text('Bloquear apps durante o foco'), findsOneWidget);
    expect(find.text('Máximo por dia'), findsOneWidget);
    expect(find.text('4h'), findsOneWidget);
    expect(find.text('Lembrete da rampa'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
    expect(find.text('E-mail diário'), findsOneWidget);
    // Modo escuro desligado; bloquear apps ligado (como no design); e-mail
    // diário ligado (AT4).
    expect(
      tester.widgetList<BoraSwitch>(find.byType(BoraSwitch)).map((s) => s.on),
      [false, true, true],
    );
  });

  testWidgets('seção Configurações com Idioma em Português (Brasil)', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('CONFIGURAÇÕES'), findsOneWidget);
    expect(find.text('Redefinir minha rotina'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Português (Brasil)'), findsOneWidget);
    expect(find.text('Enviar sugestão'), findsOneWidget);
  });

  testWidgets('não existe "Sair da conta" (MP12)', (tester) async {
    await pump(tester);
    expect(find.text('Sair da conta'), findsNothing);
  });

  testWidgets('cada linha avisa o seu toque', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Modo escuro'));
    await tester.tap(find.text('Bloquear apps durante o foco'));
    await tester.tap(find.text('Redefinir minha rotina'));
    await tester.tap(find.text('Idioma'));
    await tester.tap(find.text('Enviar sugestão'));
    await tester.tap(find.bySemanticsLabel('Voltar'));
    expect(taps, {
      'dark': 1,
      'block': 1,
      'routine': 1,
      'language': 1,
      'suggestion': 1,
      'back': 1,
    });
  });

  testWidgets('os interruptores e o tema seguem o controlador', (tester) async {
    await pump(tester);
    state.toggleDark();
    state.toggleBlockApps();
    state.toggleDailyEmail();
    state.selectLanguage('es');
    await tester.pumpAndSettle();
    expect(find.text('Tema atual: Escuro'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(
      tester.widgetList<BoraSwitch>(find.byType(BoraSwitch)).map((s) => s.on),
      [true, false, false],
    );
  });

  testWidgets('mostra o erro de carga, quando houver', (tester) async {
    state = ProfileController(
      SampleAuthRepository(),
      SampleSchedulingRepository(),
      SessionStore(),
      ThemeController(),
    );
    state.error = 'Não deu pra carregar o máximo por dia.';
    await pump(tester);
    expect(find.text('Não deu pra carregar o máximo por dia.'), findsOneWidget);
  });

  group('AT3–AT5 (28/11/2026)', () {
    testWidgets('tocar no nome ou em "Editar perfil" abre a edição', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Arthur'));
      await tester.ensureVisible(find.text('Editar perfil'));
      await tester.tap(find.text('Editar perfil'));
      expect(taps['edit'], 2);
    });

    testWidgets('"E-mail diário" alterna pelo interruptor', (tester) async {
      await pump(tester);
      await tester.ensureVisible(find.text('E-mail diário'));
      await tester.tap(find.text('E-mail diário'));
      expect(taps['email'], 1);
    });

    testWidgets('tocar em "Máximo por dia" abre o seletor', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Máximo por dia'));
      expect(taps['limit'], 1);
    });
  });
}
