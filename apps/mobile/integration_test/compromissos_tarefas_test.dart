// Rodada de compromissos e tarefas únicas (20/11/2026): ponta a ponta no
// simulador iOS, contra o backend local real (`env/local-simulator.json`).
//
// Antes: backend no ar (porta 4000), com o build desta rodada. Cria um usuário
// novo a cada execução (não depende do `db:reset-demo`).
//
// O onboarding marca só as noites (18–23) dos 7 dias, para o primeiro bloco
// cair hoje às 18:00 e o horário padrão do formulário (19:00–21:00) bater com
// ele. **Rode antes de cerca de 17:30**, senão não sobra noite hoje.
//
// O seletor de hora do iOS (CupertinoDatePicker) não é girado aqui: os
// compromissos usam o horário padrão; o dia "movido" é criado pela API e o
// teste confere a tela.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:oitenta/app.dart';
import 'package:oitenta/core/config/app_config.dart';
import 'package:oitenta/core/di/app_dependencies.dart';
import 'package:oitenta/core/format/bora_format.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';

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

Future<void> pumpGone(WidgetTester tester, Finder finder) async {
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Não sumiu a tempo: $finder');
}

Future<void> tapFinder(WidgetTester tester, Finder f) async {
  await pumpUntil(tester, f);
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f.first);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> tapText(WidgetTester tester, String text) =>
    tapFinder(tester, find.text(text));

Future<void> tapLabel(WidgetTester tester, String label) =>
    tapFinder(tester, find.bySemanticsLabel(label));

Future<void> typeInto(WidgetTester tester, Finder f, String text) async {
  await pumpUntil(tester, f);
  await tester.ensureVisible(f.first);
  await tester.enterText(f.first, text);
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compromissos na Semana e no Hoje, e tarefas únicas', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = BoraFormat.dateKey(now);
    final in7 = BoraFormat.dateKey(DateTime(now.year, now.month, now.day + 7));
    final stamp = now.millisecondsSinceEpoch;
    final email = 'e2e.cp.$stamp@teste.local';
    const password = 'Senha@123';

    final deps = AppDependencies.fromConfig();
    await tester.pumpWidget(BoraApp(deps: deps));
    await tester.pump();

    Future<dynamic> api(String method, String path, [Object? body]) async {
      final req = http.Request(method, Uri.parse('${AppConfig.apiUrl}$path'))
        ..headers['Authorization'] = 'Bearer ${deps.session.token}'
        ..headers['Content-Type'] = 'application/json';
      if (body != null) req.body = jsonEncode(body);
      final res = await http.Response.fromStream(await req.send());
      expect(res.statusCode, inInclusiveRange(200, 299), reason: res.body);
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }

    Future<List<Map<String, dynamic>>> blocksOn(String date) async {
      final j = await api('GET', '/scheduling/plan/day?date=$date');
      return ((j as Map<String, dynamic>)['blocks'] as List)
          .cast<Map<String, dynamic>>();
    }

    Future<List<Map<String, dynamic>>> occurrences(
      String from,
      String to,
    ) async {
      final j = await api(
        'GET',
        '/scheduling/commitments/occurrences?from=$from&to=$to',
      );
      return ((j as Map<String, dynamic>)['occurrences'] as List)
          .cast<Map<String, dynamic>>();
    }

    int localMinute(String iso) {
      final t = DateTime.parse(iso).toLocal();
      return t.hour * 60 + t.minute;
    }

    // --- Cadastro + onboarding (só as noites) --------------------------------
    await tapFinder(tester, find.widgetWithText(TertiaryButton, 'Criar conta'));
    await typeInto(tester, find.byKey(const Key('register-name')), 'Arthur');
    await typeInto(tester, find.byKey(const Key('register-email')), email);
    await typeInto(
      tester,
      find.byKey(const Key('register-password')),
      password,
    );
    await typeInto(tester, find.byKey(const Key('register-confirm')), password);
    await tapText(
      tester,
      'Li e aceito os Termos de uso e a Política de privacidade',
    );
    await tapFinder(tester, find.widgetWithText(PrimaryButton, 'Criar conta'));
    await pumpUntil(tester, find.text('1 de 6'), reason: 'cadastro');
    await tapText(tester, 'Continuar');
    await pumpUntil(tester, find.text('2 de 6'));
    await tapText(tester, 'Começar');
    await pumpUntil(tester, find.text('3 de 6'));
    await tapText(tester, 'Continuar');
    await pumpUntil(tester, find.text('4 de 6'));
    for (final d in ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM']) {
      await tapLabel(tester, '$d Noite');
    }
    await tapText(tester, 'Continuar');
    await pumpUntil(tester, find.text('5 de 6'));
    await tapText(tester, 'Continuar');
    await pumpUntil(tester, find.text('6 de 6'), reason: 'PUT availability');
    await tapText(tester, 'Ir para o Hoje');
    await pumpUntil(tester, find.text('Bom dia, Arthur'));

    // --- Um objetivo com uma etapa de 2h: o bloco cai hoje às 18:00 ----------
    await api('POST', '/goals', {
      'title': 'Trabalho E2E',
      'deadline': BoraFormat.dateKey(
        DateTime(now.year, now.month, now.day + 14),
      ),
      'kind': 'goal',
      'steps': [
        {
          'title': 'Escrever o relatório',
          'estimatedMinutes': 120,
          'microSteps': [],
        },
      ],
    });
    var blocks = await blocksOn(today);
    expect(blocks, isNotEmpty, reason: 'sem bloco hoje (rode antes de ~17:30)');
    expect(
      blocks.any(
        (b) =>
            localMinute(b['start'] as String) < 1260 &&
            localMinute(b['end'] as String) > 1140,
      ),
      isTrue,
    );

    // --- Semana → "+ Compromisso" → Toda semana, 19:00–21:00 (padrão) --------
    await tapLabel(tester, 'Semana');
    await pumpUntil(tester, find.widgetWithText(TertiaryButton, 'Compromisso'));
    await tapFinder(tester, find.widgetWithText(TertiaryButton, 'Compromisso'));
    await pumpUntil(tester, find.text('Novo compromisso'));
    await typeInto(tester, find.byType(TextField), 'Aula de violão');
    await tapText(tester, 'Toda semana');
    await pumpUntil(
      tester,
      find.textContaining('Bate com'),
      reason: 'conflito (MC5)',
    );
    await tapFinder(
      tester,
      find.widgetWithText(PrimaryButton, 'Salvar compromisso'),
    );
    await pumpUntil(tester, find.text('Plano recalculado'), reason: 'POST');
    await pumpUntil(tester, find.bySemanticsLabel('Opções de Aula de violão'));

    // O plano de hoje não tem mais bloco sobreposto a 19:00–21:00.
    blocks = await blocksOn(today);
    for (final b in blocks) {
      final s = localMinute(b['start'] as String),
          e = localMinute(b['end'] as String);
      expect(
        s >= 1260 || e <= 1140,
        isTrue,
        reason: 'bloco $s–$e sobre o compromisso',
      );
    }

    // --- Não vai ter nesse dia → "Não vai ter" → Vai ter sim -----------------
    await tapLabel(tester, 'Opções de Aula de violão');
    await tapText(tester, 'Não vai ter nesse dia');
    await pumpUntil(tester, find.text('Horário liberado'));
    await pumpUntil(tester, find.text('Não vai ter'));
    var occ = await occurrences(today, today);
    expect(occ.single['status'], 'cancelled');
    await tapLabel(tester, 'Opções de Aula de violão');
    await tapFinder(tester, find.widgetWithText(PrimaryButton, 'Vai ter sim'));
    await pumpUntil(tester, find.text('Voltou pra agenda'));
    occ = await occurrences(today, today);
    expect(occ.single['status'], 'normal');

    // --- Editar → Só nesse dia abre o formulário certo (e cancela) -----------
    await tapLabel(tester, 'Opções de Aula de violão');
    await tapText(tester, 'Editar');
    await tapFinder(tester, find.widgetWithText(PrimaryButton, 'Continuar'));
    await pumpUntil(tester, find.textContaining('Mudando só'));
    expect(find.text('Salvar só nesse dia'), findsOneWidget);
    await tapFinder(tester, find.widgetWithText(TertiaryButton, 'Cancelar'));
    await pumpUntil(tester, find.bySemanticsLabel('Opções de Aula de violão'));

    // --- Dia movido pela API → "Horário alterado" → Voltar pro normal --------
    final id = occ.single['commitmentId'] as String;
    await api('PUT', '/scheduling/commitments/$id/occurrences/$today', {
      'status': 'moved',
      'newDate': today,
      'startMinute': 1260,
      'endMinute': 1320,
    });
    await tapLabel(tester, 'Hoje');
    await tapLabel(tester, 'Semana');
    await pumpUntil(
      tester,
      find.text('Horário alterado'),
      reason: 'dia movido',
    );
    await tapLabel(tester, 'Opções de Aula de violão');
    await tapText(tester, 'Voltar pro horário normal');
    await pumpUntil(tester, find.text('Horário normal de volta'));
    await pumpGone(tester, find.text('Horário alterado'));

    // --- Hoje mostra o compromisso (MC6) ------------------------------------
    await tapLabel(tester, 'Hoje');
    await pumpUntil(
      tester,
      find.bySemanticsLabel('Opções de Aula de violão'),
      reason: 'compromisso no Hoje',
    );

    // --- Excluir → Desse dia em diante (a partir da semana que vem) ----------
    await api(
      'DELETE',
      '/scheduling/commitments/$id?scope=following&fromDate=$in7',
    );
    occ = await occurrences(today, in7);
    expect(occ.map((o) => o['date']), isNot(contains(in7)));
    expect(occ.map((o) => o['date']), contains(today));

    // --- Excluir todas pela tela ---------------------------------------------
    await tapLabel(tester, 'Semana');
    await tapLabel(tester, 'Opções de Aula de violão');
    await tapText(tester, 'Excluir');
    await tapText(tester, 'Todas as semanas');
    await tapFinder(tester, find.text('Excluir').last);
    await pumpUntil(tester, find.text('Compromisso excluído'));
    await pumpGone(tester, find.bySemanticsLabel('Opções de Aula de violão'));
    expect(await occurrences(today, in7), isEmpty);

    // --- Compromisso "Só uma vez" pelo botão do dia -------------------------
    await tapFinder(tester, find.widgetWithText(TertiaryButton, 'Compromisso'));
    await pumpUntil(tester, find.text('Novo compromisso'));
    await typeInto(tester, find.byType(TextField), 'Consulta no dentista');
    await tapFinder(
      tester,
      find.widgetWithText(PrimaryButton, 'Salvar compromisso'),
    );
    await pumpUntil(
      tester,
      find.bySemanticsLabel('Opções de Consulta no dentista'),
    );
    occ = await occurrences(today, in7);
    expect(occ.single['recurrence'], isNull);
    await tapLabel(tester, 'Opções de Consulta no dentista');
    await tapText(tester, 'Excluir');
    await pumpUntil(tester, find.text('Compromisso excluído'));

    // --- Tarefas únicas pelo Hoje (MC9) --------------------------------------
    await tapLabel(tester, 'Hoje');
    await tapFinder(
      tester,
      find.widgetWithText(TertiaryButton, 'Tarefas únicas'),
    );
    await pumpUntil(
      tester,
      find.text(
        'Coisas rápidas que não precisam virar objetivo. Eu encaixo nos seus horários livres.',
      ),
    );
    await typeInto(tester, find.byType(TextField), 'Pagar a conta de luz');
    await tapText(tester, '15 min');
    await tapFinder(
      tester,
      find.widgetWithText(PrimaryButton, 'Adicionar tarefa'),
    );
    await pumpUntil(tester, find.text('Tarefa anotada'));
    await pumpUntil(tester, find.text('15 min · Hoje'));

    var tasks =
        ((await api('GET', '/goals?kind=single')) as Map)['goals'] as List;
    expect(tasks.single['title'], 'Pagar a conta de luz');
    expect(tasks.single['plannedDate'], today);

    await typeInto(tester, find.byType(TextField), 'Comprar presente');
    await tapText(tester, 'Sem data');
    await tapFinder(
      tester,
      find.widgetWithText(PrimaryButton, 'Adicionar tarefa'),
    );
    await pumpUntil(tester, find.text('Eu encaixo quando sobrar um tempinho.'));
    await pumpUntil(tester, find.text('SEM DATA'));

    // marcar como feita → Feitas; desmarcar; excluir
    await tapLabel(tester, 'Marcar como feita');
    await pumpUntil(tester, find.text('Feito!'));
    await pumpUntil(tester, find.text('FEITAS'));
    tasks = ((await api('GET', '/goals?kind=single')) as Map)['goals'] as List;
    expect(tasks.where((t) => t['status'] == 'done'), hasLength(1));
    await tapLabel(tester, 'Desmarcar');
    await pumpGone(tester, find.text('FEITAS'));
    await tapLabel(tester, 'Excluir tarefa');
    await pumpUntil(tester, find.text('1 tarefa'));
    tasks = ((await api('GET', '/goals?kind=single')) as Map)['goals'] as List;
    expect(tasks, hasLength(1));

    // --- Objetivos não lista tarefas únicas (MC8) ----------------------------
    await tapLabel(tester, 'Objetivos');
    await pumpUntil(tester, find.text('Trabalho E2E'));
    expect(find.text('Comprar presente'), findsNothing);
    expect(find.text('Pagar a conta de luz'), findsNothing);
  });
}
