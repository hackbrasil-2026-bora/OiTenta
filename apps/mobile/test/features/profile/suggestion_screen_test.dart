import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/profile/presentation/suggestion_controller.dart';
import 'package:oitenta/features/profile/presentation/suggestion_screen.dart';

import '../../helpers/test_app.dart';
import 'suggestion_fakes.dart';

Widget host(
  SuggestionController c, {
  VoidCallback? onSend,
  VoidCallback? onBack,
}) => themed(
  ListenableBuilder(
    listenable: c,
    builder: (_, _) => SuggestionScreen(
      state: c,
      onBack: onBack ?? () {},
      onText: c.setText,
      onSend: onSend ?? () {},
    ),
  ),
);

void main() {
  testWidgets('textos do design (M29)', (tester) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      host(SuggestionController(FakeFeedbackRepository())),
    );
    expect(find.text('Enviar sugestão'), findsOneWidget);
    expect(
      find.text('Achou algo estranho ou teve uma ideia? Conta pra gente.'),
      findsOneWidget,
    );
    expect(find.text('O QUE PODEMOS MELHORAR?'), findsOneWidget);
    expect(
      find.text('Ex.: queria poder mudar a cor dos objetivos'),
      findsOneWidget,
    );
    expect(find.text('Anexar print (opcional)'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
    expect(find.text('Prefere e-mail? Escreve pra gente:'), findsOneWidget);
    expect(find.text('contato@bora.app'), findsOneWidget);
  });

  testWidgets('o campo é multilinha', (tester) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      host(SuggestionController(FakeFeedbackRepository())),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, isNull);
    expect(field.keyboardType, TextInputType.multiline);
  });

  testWidgets('"Anexar print (opcional)" aparece desabilitado (MP9)', (
    tester,
  ) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      host(SuggestionController(FakeFeedbackRepository())),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Anexar print (opcional)')),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
  });

  testWidgets('"Enviar" fica desabilitado sem texto e envia com texto', (
    tester,
  ) async {
    await usePhoneSize(tester);
    final c = SuggestionController(FakeFeedbackRepository());
    var sends = 0;
    await tester.pumpWidget(host(c, onSend: () => sends++));
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    expect(sends, 0);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    expect(sends, 0);

    await tester.enterText(find.byType(TextField), 'Queria tema roxo');
    await tester.pump();
    expect(c.text, 'Queria tema roxo');
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    expect(sends, 1);
  });

  testWidgets('o erro do envio aparece na tela', (tester) async {
    await usePhoneSize(tester);
    final repo = FakeFeedbackRepository()..error = NetworkFailure('x');
    final c = SuggestionController(repo)..setText('ideia');
    await tester.pumpWidget(host(c, onSend: c.send));
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não deu pra enviar agora. Tenta de novo?'),
      findsOneWidget,
    );
  });

  testWidgets('o botão voltar chama onBack', (tester) async {
    await usePhoneSize(tester);
    var backs = 0;
    await tester.pumpWidget(
      host(
        SuggestionController(FakeFeedbackRepository()),
        onBack: () => backs++,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Voltar'));
    expect(backs, 1);
  });
}
