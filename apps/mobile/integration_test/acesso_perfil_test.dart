// Rodada Acesso/Perfil/Jardim (19/11/2026): ponta a ponta no simulador iOS,
// contra o backend local real (`env/local-simulator.json`, DATA_SOURCE=http,
// SHOW_DEMO=true).
//
// Antes: backend no ar (porta 4000). Não depende do `db:reset-demo`: cria um
// usuário novo a cada execução (e-mail único).
//
// Percorre: Criar conta → onboarding → Hoje → Perfil (nome, e-mail, máximo
// por dia) → Redefinir rotina (salva no backend) → Modo escuro → Enviar
// sugestão → Jardim pelo Broto → "Trocar por 50" sem ação → reabrir o app →
// senha errada → login real.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:oitenta/app.dart';
import 'package:oitenta/core/config/app_config.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';
import 'package:oitenta/features/profile/data/sample_feedback_repository.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  String? reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Não apareceu a tempo: $finder${reason == null ? '' : ' ($reason)'}');
}

Future<void> tapFinder(WidgetTester tester, Finder f) async {
  await pumpUntil(tester, f);
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f.first);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> tapText(WidgetTester tester, String text) =>
    tapFinder(tester, find.text(text));

Future<void> tapLabel(WidgetTester tester, String label) =>
    tapFinder(tester, find.bySemanticsLabel(label));

Future<void> typeInto(WidgetTester tester, String key, String text) async {
  final f = find.byKey(Key(key));
  await pumpUntil(tester, f);
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('acesso e perfil: criar conta → onboarding → Perfil → rotina → '
      'tema → sugestão → Jardim → login real', (tester) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'e2e.$stamp@teste.local';
    const password = 'Senha@123';
    const suggestion = 'Queria poder mudar a cor dos objetivos';

    var deps = AppDependencies.fromConfig();
    expect(deps.showDemo, isTrue, reason: 'SHOW_DEMO=true no local-simulator');
    await tester.pumpWidget(BoraApp(deps: deps));
    await tester.pump();

    // --- Criar conta (M34/M35, MP1, MP2) -----------------------------------
    await tapFinder(tester, find.widgetWithText(TertiaryButton, 'Criar conta'));
    await pumpUntil(tester, find.text('Criar sua conta'));
    await typeInto(tester, 'register-name', 'Arthur');
    await typeInto(tester, 'register-email', email);
    await typeInto(tester, 'register-password', password);
    await typeInto(tester, 'register-confirm', password);
    expect(find.text('As senhas batem'), findsOneWidget);
    await tapText(
      tester,
      'Li e aceito os Termos de uso e a Política de privacidade',
    );
    await tapFinder(tester, find.widgetWithText(PrimaryButton, 'Criar conta'));

    // register → login → onboarding (4b), com o toast.
    await pumpUntil(tester, find.text('1 de 6'), reason: 'cadastro real');
    expect(find.text('Conta criada!'), findsOneWidget);
    expect(find.text('Bem-vindo ao Bora, Arthur.'), findsOneWidget);
    expect(deps.session.user?.name, 'Arthur');
    expect(deps.session.user?.email, email);

    // --- Onboarding: só a tarde de segunda e a noite de quarta -------------
    await tapText(tester, 'Continuar');
    await pumpUntil(tester, find.text('2 de 6'));
    await tapText(tester, 'Começar');
    await pumpUntil(tester, find.text('3 de 6'));
    await tapText(tester, 'Continuar');
    await pumpUntil(tester, find.text('4 de 6'));
    await tapLabel(tester, 'SEG Tarde');
    await tapLabel(tester, 'QUA Noite');
    await tapText(tester, 'Continuar');
    await pumpUntil(tester, find.text('5 de 6'));
    await tapText(tester, 'Continuar');
    await pumpUntil(tester, find.text('6 de 6'), reason: 'PUT availability');
    await tapText(tester, 'Ir para o Hoje');
    await pumpUntil(tester, find.text('Bom dia, Arthur'));

    // --- Perfil pela inicial (M26, MP6) ------------------------------------
    await tapLabel(tester, 'Perfil');
    await pumpUntil(tester, find.text('Lembrete da rampa'));
    await pumpUntil(tester, find.text(email), reason: 'GET /auth/me');
    expect(find.text('Arthur'), findsWidgets);
    await pumpUntil(tester, find.text('4h'), reason: 'GET availability');

    // --- Redefinir rotina (M27, MP11): a tela mostra o que o onboarding
    // gravou dentro de 8h–22h e salva no backend ----------------------------
    await tapText(tester, 'Redefinir minha rotina');
    await pumpUntil(tester, find.text('Salvar e recalcular plano'));
    // Seg 12–18 (onboarding) → células 12h, 14h, 16h; Qua 18–23 → 18h, 20h.
    await pumpUntil(tester, find.text('10h livres por semana'));
    await tapLabel(tester, 'Ter 8h');
    await tapLabel(tester, 'Ter 10h');
    expect(find.text('14h livres por semana'), findsOneWidget);
    await tapText(tester, 'Salvar e recalcular plano');
    await pumpUntil(tester, find.text('Plano recalculado'), reason: 'PUT');
    await pumpUntil(tester, find.text('Lembrete da rampa'));

    final res = await http.get(
      Uri.parse('${AppConfig.apiUrl}/scheduling/availability'),
      headers: {'Authorization': 'Bearer ${deps.session.token}'},
    );
    expect(res.statusCode, 200);
    final windows =
        (((jsonDecode(res.body) as Map<String, dynamic>)['availability']
                    as Map<String, dynamic>)['windows']
                as List)
            .cast<Map<String, dynamic>>()
            .map((w) => '${w['weekday']}:${w['startMinute']}-${w['endMinute']}')
            .toSet();
    expect(windows, {'0:720-1080', '1:480-720', '2:1080-1320'});

    // --- Modo escuro (MP7) --------------------------------------------------
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.light);
    await tapText(tester, 'Modo escuro');
    await tester.pump(const Duration(milliseconds: 400));
    expect(app().themeMode, ThemeMode.dark);
    expect(find.text('Tema atual: Escuro'), findsOneWidget);
    await tapText(tester, 'Modo escuro');
    await tester.pump(const Duration(milliseconds: 400));
    expect(app().themeMode, ThemeMode.light);

    // --- Enviar sugestão (M29, MP9: só exemplo) ----------------------------
    await tapText(tester, 'Enviar sugestão');
    await pumpUntil(tester, find.text('O QUE PODEMOS MELHORAR?'));
    await tester.enterText(find.byType(TextField).first, suggestion);
    await tester.pump(const Duration(milliseconds: 200));
    await tapFinder(tester, find.widgetWithText(PrimaryButton, 'Enviar'));
    await pumpUntil(tester, find.text('Sugestão enviada'));
    expect((deps.feedback as SampleFeedbackRepository).sent, [suggestion]);
    await pumpUntil(tester, find.text('Lembrete da rampa'));

    // --- Jardim pelo Broto (M39, MP10, MP13) --------------------------------
    await tapLabel(tester, 'Hoje');
    await pumpUntil(tester, find.text('Bom dia, Arthur'));
    await tapLabel(tester, 'Abrir Jardim');
    await pumpUntil(tester, find.text('Estágio Broto · Nível 7'));
    await tapText(tester, 'Trocar por 50');
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Protege 1 dia da sequência · você tem 1'),
      findsOneWidget,
    );

    // --- Reabrir o app (sessão só em memória) e entrar de verdade ----------
    deps = AppDependencies.fromConfig();
    await tester.pumpWidget(BoraApp(key: UniqueKey(), deps: deps));
    await pumpUntil(tester, find.text('Que bom te ver!'));
    expect(find.text('Entrar com Google'), findsNothing); // MP3
    expect(find.text('Entrar direto como Arthur (demo)'), findsOneWidget);

    await typeInto(tester, 'login-email', email);
    await typeInto(tester, 'login-password', 'Errada@123');
    await tapFinder(tester, find.widgetWithText(PrimaryButton, 'Entrar'));
    await pumpUntil(tester, find.text('E-mail ou senha inválidos'));
    expect(deps.session.token, isNull);

    await typeInto(tester, 'login-password', password);
    await tapFinder(tester, find.widgetWithText(PrimaryButton, 'Entrar'));
    // Já tem disponibilidade → Hoje (P12), com o toast.
    await pumpUntil(tester, find.text('Bom dia, Arthur'), reason: 'login');
    expect(find.text('Oi de novo, Arthur!'), findsOneWidget);
    expect(deps.session.user?.email, email);
  });
}
