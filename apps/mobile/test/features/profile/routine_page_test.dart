import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oitenta/core/routes/app_routes.dart';
import 'package:oitenta/features/profile/presentation/profile_pages.dart';
import 'package:oitenta/features/profile/presentation/routine_suggestion_pages.dart';
import 'package:oitenta/features/scheduling/domain/availability.dart';

import '../../helpers/test_app.dart';

AvailabilityWindow w(int day, int start, int end) => AvailabilityWindow(
  weekday: day,
  startMinute: start * 60,
  endMinute: end * 60,
);

void main() {
  testWidgets(
    'abre com a rotina salva, salva a grade, mostra o toast e volta ao Perfil',
    (tester) async {
      // Exemplo: 18:00–23:00 todos os dias → 18h e 20h de cada dia (28h).
      final deps = await pumpApp(tester, location: AppRoutes.profileRoutine);
      expect(find.byType(RoutinePage), findsOneWidget);
      expect(find.text('28h livres por semana'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Seg 8h'));
      await tester.pump();
      expect(find.text('30h livres por semana'), findsOneWidget);

      await tester.tap(find.text('Salvar e recalcular plano'));
      await tester.pumpAndSettle();
      expect(find.text('Plano recalculado'), findsOneWidget);
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(RoutinePage), findsNothing);

      final saved = (await deps.scheduling.getAvailability())!;
      expect(saved.windows, [
        w(0, 8, 10),
        w(0, 18, 22),
        for (var d = 1; d < 7; d++) w(d, 18, 22),
      ]);
      expect(saved.dailyLimitMinutes, 240);
      await tester.pump(const Duration(seconds: 3)); // o toast some
    },
  );

  testWidgets('aberta por cima do Perfil, salvar volta com pop', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.profile);
    GoRouter.of(
      tester.element(find.byType(ProfilePage)),
    ).push(AppRoutes.profileRoutine);
    await tester.pumpAndSettle();
    expect(find.byType(RoutinePage), findsOneWidget);

    await tester.tap(find.text('Salvar e recalcular plano'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutinePage), findsNothing);
    expect(find.byType(ProfilePage), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('voltar sem salvar não grava nada', (tester) async {
    final deps = await pumpApp(tester, location: AppRoutes.profileRoutine);
    await tester.tap(find.bySemanticsLabel('Seg 8h'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    final saved = (await deps.scheduling.getAvailability())!;
    expect(saved.windows, hasLength(7));
  });
}
