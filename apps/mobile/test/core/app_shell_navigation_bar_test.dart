import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/system/system_navigation_bar_scope.dart';
import 'package:oitenta/core/theme/app_theme.dart';
import 'package:oitenta/core/widgets/app_shell.dart';

const _bodyKey = Key('body');

/// Shell numa tela de 400×800 com a barra de navegação do Android
/// controlada por [visible]; [systemInset] é o espaço que o Android reserva.
Widget _shell(
  WidgetTester tester,
  ValueNotifier<bool> visible, {
  double systemInset = 0,
  ValueChanged<AppTab>? onTab,
}) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: systemInset);
  tester.view.viewPadding = FakeViewPadding(bottom: systemInset);
  addTearDown(tester.view.reset);
  return SystemNavigationBarScope(
    visible: visible,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: AppShell(
        current: AppTab.today,
        onTab: onTab ?? (_) {},
        child: const SizedBox.expand(key: _bodyKey),
      ),
    ),
  );
}

void main() {
  testWidgets('com a barra escondida, a tab bar fica no pé da tela', (
    tester,
  ) async {
    final visible = ValueNotifier(false);
    await tester.pumpWidget(_shell(tester, visible));
    await tester.pumpAndSettle();

    final tabBar = tester.getRect(find.byType(BoraTabBar));
    expect(tabBar.bottom, 800);
    expect(find.byKey(systemNavigationBarBackdropKey), findsNothing);
  });

  testWidgets(
    'quando a barra aparece, a tab bar sobe inteira sem mudar de tamanho',
    (tester) async {
      final visible = ValueNotifier(false);
      await tester.pumpWidget(_shell(tester, visible));
      await tester.pumpAndSettle();
      final before = tester.getRect(find.byType(BoraTabBar));
      final bodyBefore = tester.getSize(find.byKey(_bodyKey));

      // O Android mostra os botões e passa a reservar 48 dp embaixo.
      visible.value = true;
      await tester.pumpWidget(_shell(tester, visible, systemInset: 48));
      await tester.pumpAndSettle();

      final after = tester.getRect(find.byType(BoraTabBar));
      expect(after.height, before.height, reason: 'não estica');
      expect(after.top, before.top - 48, reason: 'sobe a altura dos botões');
      expect(
        tester.getSize(find.byKey(_bodyKey)),
        bodyBefore,
        reason: 'o resto da tela não muda de tamanho',
      );
    },
  );

  testWidgets(
    'atrás dos botões do Android aparece a faixa verde-escura translúcida',
    (tester) async {
      final visible = ValueNotifier(true);
      await tester.pumpWidget(_shell(tester, visible, systemInset: 48));
      await tester.pumpAndSettle();

      final backdrop = find.byKey(systemNavigationBarBackdropKey);
      expect(backdrop, findsOneWidget);
      expect(tester.getRect(backdrop), const Rect.fromLTRB(0, 752, 400, 800));
      final color = (tester.widget<ColoredBox>(backdrop)).color;
      expect(color.toARGB32() & 0x00FFFFFF, 0x047857, reason: 'pri do app');
      expect(color.a, inExclusiveRange(0.5, 1.0), reason: 'translúcida');
    },
  );

  testWidgets('se o Android não informar a altura, usa 48 dp', (tester) async {
    final visible = ValueNotifier(true);
    await tester.pumpWidget(_shell(tester, visible));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(systemNavigationBarBackdropKey)).height,
      48,
    );
  });

  testWidgets('com a tab bar levantada, o toque nas abas continua valendo', (
    tester,
  ) async {
    AppTab? tapped;
    final visible = ValueNotifier(true);
    await tester.pumpWidget(
      _shell(tester, visible, systemInset: 48, onTab: (t) => tapped = t),
    );
    await tester.pumpAndSettle();

    // Toca no alto da aba Objetivos, acima do espaço original da tab bar.
    final goals = tester.getRect(find.text('Objetivos'));
    await tester.tapAt(Offset(goals.center.dx, goals.top - 20));
    expect(tapped, AppTab.goals);
  });
}
