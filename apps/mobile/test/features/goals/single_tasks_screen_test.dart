import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

Future<void> _settleToast(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 3));

void main() {
  testWidgets('tela 53: título, campo e grupos com as tarefas', (tester) async {
    await pumpApp(tester, location: '/tarefas');
    expect(find.text('Tarefas únicas'), findsOneWidget);
    expect(
      find.text(
        'Coisas rápidas que não precisam virar objetivo. '
        'Eu encaixo nos seus horários livres.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ex.: Arrumar o guarda-roupa'), findsOneWidget);
    expect(find.bySemanticsLabel('Adicionar tarefa'), findsOneWidget);
    expect(find.text('QUANTO TEMPO LEVA?'), findsNothing);

    expect(find.text('HOJE'), findsOneWidget);
    expect(find.text('PRÓXIMOS DIAS'), findsOneWidget);
    expect(find.text('SEM DATA'), findsOneWidget);
    expect(find.text('FEITAS'), findsOneWidget);
    expect(find.text('1 tarefa'), findsNWidgets(3));
    expect(find.text('3 tarefas'), findsOneWidget);
    expect(find.text('Pagar a conta de luz'), findsOneWidget);
    expect(find.text('15 min · Hoje'), findsNWidgets(2)); // luz e RU (feita)
    expect(find.text('30 min · Sáb, 08/11/2025'), findsOneWidget);
    expect(find.text('1h · Ter, 11/11/2025'), findsOneWidget);
    expect(find.text('30 min · Sem data'), findsOneWidget);
    expect(find.bySemanticsLabel('Marcar como feita'), findsNWidgets(5));
    expect(find.bySemanticsLabel('Desmarcar'), findsOneWidget);
    expect(find.bySemanticsLabel('Excluir tarefa'), findsNWidgets(6));

    // Feita = riscada.
    final done = tester.widget<Text>(find.text('Renovar a carteirinha do RU'));
    expect(done.style!.decoration, TextDecoration.lineThrough);
    final open = tester.widget<Text>(find.text('Pagar a conta de luz'));
    expect(open.style!.decoration, TextDecoration.none);
  });

  testWidgets('tela 54: digitar abre o painel e adiciona para hoje', (
    tester,
  ) async {
    await pumpApp(tester, location: '/tarefas');
    await tester.enterText(find.byType(EditableText), 'Pagar o boleto');
    await tester.pumpAndSettle();
    expect(find.text('QUANTO TEMPO LEVA?'), findsOneWidget);
    expect(find.text('QUANDO?'), findsOneWidget);
    for (final l in ['15 min', '30 min', '1h', '2h']) {
      expect(find.text(l), findsOneWidget);
    }
    // "Hoje" também é o rótulo da tab bar.
    expect(find.text('Hoje'), findsNWidgets(2));
    for (final l in ['Amanhã', 'Sem data', 'Escolher dia']) {
      expect(find.text(l), findsOneWidget);
    }
    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar tarefa'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa anotada'), findsOneWidget);
    expect(find.text('Encaixei num horário livre de hoje.'), findsOneWidget);
    expect(find.text('Pagar o boleto'), findsOneWidget);
    expect(find.text('2 tarefas'), findsOneWidget);
    expect(find.text('15 min · Hoje'), findsNWidgets(3));
    expect(find.text('QUANTO TEMPO LEVA?'), findsNothing);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, isEmpty);
    await _settleToast(tester);
  });

  testWidgets('Sem data e Amanhã', (tester) async {
    await pumpApp(tester, location: '/tarefas');
    await tester.enterText(find.byType(EditableText), 'Comprar pilha');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sem data').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar tarefa'));
    await tester.pumpAndSettle();
    expect(find.text('Eu encaixo quando sobrar um tempinho.'), findsOneWidget);
    expect(find.text('30 min · Sem data'), findsNWidgets(2));
    await _settleToast(tester);

    await tester.enterText(find.byType(EditableText), 'Ligar pro banco');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amanhã'));
    await tester.pumpAndSettle();
    // O "+" ao lado do campo (o botão do painel tem o mesmo rótulo).
    await tester.tap(find.bySemanticsLabel('Adicionar tarefa').first);
    await tester.pumpAndSettle();
    expect(find.text('Encaixei num horário livre de amanhã.'), findsOneWidget);
    expect(find.text('30 min · Amanhã'), findsOneWidget);
    await _settleToast(tester);
  });

  testWidgets('"Escolher dia" abre o date picker e o chip mostra a data', (
    tester,
  ) async {
    await pumpApp(tester, location: '/tarefas');
    await tester.enterText(find.byType(EditableText), 'Pagar o boleto');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher dia'));
    await tester.pumpAndSettle();
    expect(find.text('Quando fazer'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Sáb, 08/11/2025'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher dia'), findsNothing);
    expect(find.text('Sáb, 08/11/2025'), findsOneWidget);
    await tester.tap(find.text('Adicionar tarefa'));
    await tester.pumpAndSettle();
    expect(
      find.text('Encaixei num horário livre de sáb, 08/11/2025.'),
      findsOneWidget,
    );
    expect(find.text('30 min · Sáb, 08/11/2025'), findsNWidgets(2));
    await _settleToast(tester);
  });

  testWidgets('marcar, desmarcar e excluir', (tester) async {
    await pumpApp(tester, location: '/tarefas');
    await tester.tap(find.bySemanticsLabel('Marcar como feita').first);
    await tester.pumpAndSettle();
    expect(find.text('Feito!'), findsOneWidget);
    expect(find.text('Uma coisa a menos na cabeça.'), findsOneWidget);
    expect(find.text('HOJE'), findsNothing);
    expect(find.text('2 tarefas'), findsOneWidget);
    await _settleToast(tester);

    await tester.tap(find.bySemanticsLabel('Desmarcar').first);
    await tester.pumpAndSettle();
    expect(find.text('Feito!'), findsNothing);
    expect(find.text('HOJE'), findsOneWidget);

    expect(find.text('Comprar presente da Júlia'), findsOneWidget);
    await tester.ensureVisible(find.bySemanticsLabel('Excluir tarefa').last);
    await tester.tap(find.bySemanticsLabel('Excluir tarefa').last);
    await tester.pumpAndSettle();
    expect(find.text('Renovar a carteirinha do RU'), findsNothing);
  });

  testWidgets('voltar sem histórico vai ao Hoje', (tester) async {
    await pumpApp(tester, location: '/tarefas');
    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefas únicas'), findsNothing);
    expect(find.text('SEU DIA'), findsOneWidget);
  });
}
