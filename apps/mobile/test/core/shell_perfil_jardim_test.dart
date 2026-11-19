import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/config/app_config.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/core/routes/app_router.dart';
import 'package:oitenta/core/routes/app_routes.dart';
import 'package:oitenta/core/theme/theme_controller.dart';
import 'package:oitenta/core/widgets/app_shell.dart';
import 'package:oitenta/features/auth/presentation/auth_pages.dart';
import 'package:oitenta/features/gamification/domain/gamification.dart';
import 'package:oitenta/features/gamification/presentation/garden_pages.dart';
import 'package:oitenta/features/gamification/presentation/home_top_bar.dart';
import 'package:oitenta/features/profile/data/sample_feedback_repository.dart';
import 'package:oitenta/features/profile/presentation/profile_pages.dart';
import 'package:oitenta/features/profile/presentation/routine_suggestion_pages.dart';

import '../helpers/test_app.dart';

/// Esqueleto da rodada Acesso/Perfil/Jardim (passo 0.6 do plano):
/// rotas, aba ativa, topo compartilhado, tema e `SHOW_DEMO`.
void main() {
  group('rotas novas', () {
    testWidgets('/perfil abre o Perfil dentro do shell', (tester) async {
      await pumpApp(tester, location: AppRoutes.profile);
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(BoraTabBar), findsOneWidget);
    });

    testWidgets('/perfil/rotina abre Redefinir rotina', (tester) async {
      await pumpApp(tester, location: AppRoutes.profileRoutine);
      expect(find.byType(RoutinePage), findsOneWidget);
    });

    testWidgets('/perfil/sugestao abre Enviar sugestão', (tester) async {
      await pumpApp(tester, location: AppRoutes.profileSuggestion);
      expect(find.byType(SuggestionPage), findsOneWidget);
    });

    testWidgets('/entrar/esqueci abre o placeholder fora do shell', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.forgotPassword);
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(BoraTabBar), findsNothing);
    });

    testWidgets('/jardim abre a GardenPage', (tester) async {
      await pumpApp(tester, location: AppRoutes.garden);
      expect(find.byType(GardenPage), findsOneWidget);
    });
  });

  group('aba ativa (MP10: o Perfil pertence ao grupo do Jardim)', () {
    test('perfil e subtelas marcam a aba Jardim', () {
      expect(tabFor(AppRoutes.profile), AppTab.garden);
      expect(tabFor(AppRoutes.profileRoutine), AppTab.garden);
      expect(tabFor(AppRoutes.profileSuggestion), AppTab.garden);
    });

    test('as abas antigas continuam iguais', () {
      expect(tabFor(AppRoutes.today), AppTab.today);
      expect(tabFor(AppRoutes.goals), AppTab.goals);
      expect(tabFor(AppRoutes.week), AppTab.week);
      expect(tabFor(AppRoutes.garden), AppTab.garden);
      expect(tabFor(AppRoutes.ramp), AppTab.today);
    });
  });

  group('topo do Hoje', () {
    testWidgets('a inicial abre o Perfil', (tester) async {
      await pumpApp(tester, location: AppRoutes.today);
      await tester.tap(find.bySemanticsLabel('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('o Broto abre o Jardim', (tester) async {
      await pumpApp(tester, location: AppRoutes.today);
      await tester.tap(find.bySemanticsLabel('Abrir Jardim'));
      await tester.pumpAndSettle();
      expect(find.byType(GardenPage), findsOneWidget);
    });
  });

  group('HomeTopBar', () {
    const g = GamificationSnapshot(
      streak: 6,
      drops: 340,
      level: 7,
      xp: 230,
      levelXp: 300,
    );

    testWidgets('mostra o Broto, a barra e a inicial, e avisa os toques', (
      tester,
    ) async {
      var broto = 0, perfil = 0;
      await tester.pumpWidget(
        themed(
          HomeTopBar(
            gamification: g,
            userName: 'arthur',
            onBroto: () => broto++,
            onProfile: () => perfil++,
          ),
        ),
      );
      expect(find.text('340'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Abrir Jardim'));
      await tester.tap(find.bySemanticsLabel('Perfil'));
      expect(broto, 1);
      expect(perfil, 1);
    });

    testWidgets('sem nome e sem gamificação, o botão fica sem letra', (
      tester,
    ) async {
      await tester.pumpWidget(
        themed(
          HomeTopBar(
            gamification: null,
            userName: '',
            onBroto: () {},
            onProfile: () {},
          ),
        ),
      );
      expect(find.text('A'), findsNothing);
      expect(find.text('340'), findsNothing);
      expect(find.bySemanticsLabel('Perfil'), findsOneWidget);
    });
  });

  group('ThemeController (MP7, só em memória)', () {
    test('começa claro', () {
      final t = ThemeController();
      expect(t.mode, ThemeMode.light);
      expect(t.isDark, isFalse);
    });

    test('toggle troca e avisa os ouvintes', () {
      final t = ThemeController();
      var n = 0;
      t.addListener(() => n++);
      t.toggle();
      expect(t.mode, ThemeMode.dark);
      expect(t.isDark, isTrue);
      t.toggle();
      expect(t.mode, ThemeMode.light);
      expect(n, 2);
    });

    testWidgets('o app segue o modo do controlador', (tester) async {
      final deps = await pumpApp(tester, location: AppRoutes.today);
      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.light);
      deps.theme.toggle();
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.dark);
      expect(app().darkTheme, isNotNull);
    });
  });

  group('SHOW_DEMO (MP5)', () {
    test('sem a variável, o demo fica escondido', () {
      expect(AppConfig.showDemo, isFalse);
    });

    test('dados de exemplo mostram o demo por padrão; http segue o pedido', () {
      expect(AppDependencies.sample().showDemo, isTrue);
      expect(AppDependencies.http(showDemo: false).showDemo, isFalse);
      expect(AppDependencies.http(showDemo: true).showDemo, isTrue);
    });

    test('a sugestão usa o repositório de exemplo nos dois modos (MP9)', () {
      expect(
        AppDependencies.sample().feedback,
        isA<SampleFeedbackRepository>(),
      );
      expect(
        AppDependencies.http(showDemo: false).feedback,
        isA<SampleFeedbackRepository>(),
      );
    });
  });
}
