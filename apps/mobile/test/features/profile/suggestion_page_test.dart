import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oitenta/core/routes/app_routes.dart';
import 'package:oitenta/features/profile/data/sample_feedback_repository.dart';
import 'package:oitenta/features/profile/presentation/profile_pages.dart';
import 'package:oitenta/features/profile/presentation/routine_suggestion_pages.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets(
    'envia o texto aparado ao repositório de exemplo, mostra o toast e volta',
    (tester) async {
      final deps = await pumpApp(tester, location: AppRoutes.profileSuggestion);
      expect(find.byType(SuggestionPage), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '  Queria tema roxo  ');
      await tester.pump();
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Sugestão enviada'), findsOneWidget);
      expect(find.text('Valeu! A gente lê tudo.'), findsOneWidget);
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(SuggestionPage), findsNothing);
      expect((deps.feedback as SampleFeedbackRepository).sent, [
        'Queria tema roxo',
      ]);
      await tester.pump(const Duration(seconds: 3)); // o toast some
    },
  );

  testWidgets('aberta por cima do Perfil, enviar volta com pop', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.profile);
    GoRouter.of(
      tester.element(find.byType(ProfilePage)),
    ).push(AppRoutes.profileSuggestion);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'ideia');
    await tester.pump();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.byType(SuggestionPage), findsNothing);
    expect(find.byType(ProfilePage), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('voltar sem enviar não grava nada', (tester) async {
    final deps = await pumpApp(tester, location: AppRoutes.profileSuggestion);
    await tester.enterText(find.byType(EditableText), 'ideia');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect((deps.feedback as SampleFeedbackRepository).sent, isEmpty);
  });
}
