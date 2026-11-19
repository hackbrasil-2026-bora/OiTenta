import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/core/routes/app_routes.dart';
import 'package:oitenta/core/sample/bora_sample_data.dart';
import 'package:oitenta/features/activation/data/sample_activation_repository.dart';
import 'package:oitenta/features/auth/data/sample_auth_repository.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/gamification/presentation/garden_pages.dart';
import 'package:oitenta/features/goals/data/sample_goals_repository.dart';
import 'package:oitenta/features/profile/presentation/language_sheet.dart';
import 'package:oitenta/features/profile/presentation/profile_pages.dart';
import 'package:oitenta/features/profile/presentation/routine_suggestion_pages.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/availability.dart';
import 'package:oitenta/features/scheduling/presentation/scheduling_pages.dart';

import '../../helpers/test_app.dart';

/// Conta as leituras da disponibilidade (para ver o recarregamento).
class _CountingScheduling extends SampleSchedulingRepository {
  int availabilityCalls = 0;

  @override
  Future<WeeklyAvailability?> getAvailability() {
    availabilityCalls++;
    return super.getAvailability();
  }
}

AppDependencies _deps(_CountingScheduling scheduling) => AppDependencies(
  auth: SampleAuthRepository(),
  scheduling: scheduling,
  goals: SampleGoalsRepository(),
  activation: SampleActivationRepository(),
  gamification: SampleGamificationRepository(),
  clock: FixedClock(BoraSample.today),
);

/// Perfil ligado ao app: tema real, navegação e sheet de idioma.
void main() {
  MaterialApp app(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp));

  testWidgets('abre com os dados do usuário e o limite do backend', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.profile);
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Arthur'), findsOneWidget);
    expect(find.text('arthur@bora.app'), findsOneWidget);
    expect(find.text('4h'), findsOneWidget);
  });

  testWidgets('tocar "Modo escuro" troca o ThemeMode do app (MP7)', (
    tester,
  ) async {
    final deps = await pumpApp(tester, location: AppRoutes.profile);
    expect(app(tester).themeMode, ThemeMode.light);
    await tester.tap(find.text('Modo escuro'));
    await tester.pumpAndSettle();
    expect(app(tester).themeMode, ThemeMode.dark);
    expect(deps.theme.isDark, isTrue);
    expect(find.text('Tema atual: Escuro'), findsOneWidget);
    await tester.tap(find.text('Modo escuro'));
    await tester.pumpAndSettle();
    expect(app(tester).themeMode, ThemeMode.light);
    expect(find.text('Tema atual: Claro'), findsOneWidget);
  });

  testWidgets('Idioma abre o sheet; escolher outro fecha e muda a linha', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.profile);
    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageSheet), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageSheet), findsNothing);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Português (Brasil)'), findsNothing);
  });

  testWidgets('fechar o sheet sem escolher mantém o idioma', (tester) async {
    await pumpApp(tester, location: AppRoutes.profile);
    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageSheet), findsNothing);
    expect(find.text('Português (Brasil)'), findsOneWidget);
  });

  testWidgets('voltar sem histórico vai para o Jardim', (tester) async {
    await pumpApp(tester, location: AppRoutes.profile);
    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(GardenPage), findsOneWidget);
    expect(find.byType(ProfilePage), findsNothing);
  });

  testWidgets('voltar com histórico volta para a tela anterior', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.today);
    await tester.tap(find.bySemanticsLabel('Perfil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsNothing);
    expect(find.byType(TodayPage), findsOneWidget);
  });

  testWidgets('Enviar sugestão abre a tela de sugestão', (tester) async {
    await pumpApp(tester, location: AppRoutes.profile);
    await tester.tap(find.text('Enviar sugestão'));
    await tester.pumpAndSettle();
    expect(find.byType(SuggestionPage), findsOneWidget);
  });

  testWidgets('Redefinir rotina abre a rotina e, ao voltar, recarrega', (
    tester,
  ) async {
    final scheduling = _CountingScheduling();
    await pumpApp(tester, location: AppRoutes.profile, deps: _deps(scheduling));
    expect(scheduling.availabilityCalls, 1);
    await tester.tap(find.text('Redefinir minha rotina'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutinePage), findsOneWidget);
    await scheduling.setAvailability(
      const WeeklyAvailability(
        windows: [
          AvailabilityWindow(weekday: 0, startMinute: 1080, endMinute: 1380),
        ],
        dailyLimitMinutes: 180,
      ),
    );
    GoRouter.of(tester.element(find.byType(RoutinePage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(scheduling.availabilityCalls, 2);
    expect(find.text('3h'), findsOneWidget);
  });
}
