import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/routes/app_routes.dart';
import 'package:oitenta/core/theme/app_theme.dart';
import 'package:oitenta/core/theme/bora_colors.dart';
import 'package:oitenta/core/theme/bora_text.dart';

import '../../helpers/test_app.dart';

/// `AppTheme.light()` como era antes do tema escuro (S6), copiado
/// literalmente para o teste de regressão.
ThemeData _lightAntes() {
  const c = BoraColors.light;
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.light(
      primary: c.pri,
      onPrimary: c.priTx,
      secondary: c.blue,
      surface: c.surface,
      onSurface: c.tx,
      error: c.danger,
    ),
    textTheme: base.textTheme
        .apply(bodyColor: c.tx, displayColor: c.tx)
        .copyWith(
          bodyMedium: BoraText.nunito(
            16,
            24,
            weight: FontWeight.w400,
            color: c.tx,
          ),
        ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.blue),
    extensions: const [c],
  );
}

void main() {
  group('AppTheme.light() (regressão)', () {
    test('continua idêntico ao de antes do tema escuro', () {
      expect(AppTheme.light(), _lightAntes());
    });
  });

  group('AppTheme.dark()', () {
    const d = BoraColors.dark;
    final t = AppTheme.dark();

    test('é escuro', () {
      expect(t.brightness, Brightness.dark);
      expect(t.colorScheme.brightness, Brightness.dark);
    });

    test('fundo #0B1512', () {
      expect(t.scaffoldBackgroundColor.toARGB32(), 0xFF0B1512);
    });

    test('usa a extensão BoraColors.dark', () {
      expect(t.extension<BoraColors>(), same(d));
    });

    test('ColorScheme vem da paleta escura', () {
      expect(t.colorScheme.primary, d.pri);
      expect(t.colorScheme.onPrimary, d.priTx);
      expect(t.colorScheme.secondary, d.blue);
      expect(t.colorScheme.surface, d.surface);
      expect(t.colorScheme.onSurface, d.tx);
      expect(t.colorScheme.error, d.danger);
    });

    test('textos com o tx escuro', () {
      expect(t.textTheme.bodyMedium?.color, d.tx);
      expect(t.textTheme.bodyLarge?.color, d.tx);
      expect(t.textTheme.headlineMedium?.color, d.tx);
    });

    test('cursor azul escuro e sem splash, como no claro', () {
      expect(t.textSelectionTheme.cursorColor, d.blue);
      expect(t.splashFactory, NoSplash.splashFactory);
      expect(t.highlightColor, Colors.transparent);
    });

    test('a extensão do ThemeData.lerp claro → escuro termina no escuro', () {
      final fim = ThemeData.lerp(AppTheme.light(), t, 1);
      expect(fim.extension<BoraColors>()?.bg, d.bg);
    });
  });

  group('Hoje no escuro', () {
    testWidgets('depois do toggle, fundo #0B1512 e texto #E6F2EE', (
      tester,
    ) async {
      final deps = await pumpApp(tester, location: AppRoutes.today);
      deps.theme.toggle();
      await tester.pumpAndSettle();

      final fundos = tester
          .widgetList<Scaffold>(find.byType(Scaffold))
          .map((s) => s.backgroundColor?.toARGB32());
      expect(fundos, contains(0xFF0B1512));

      final saudacao = tester.widget<Text>(find.textContaining('Bom dia'));
      expect(saudacao.style?.color?.toARGB32(), 0xFFE6F2EE);
    });
  });
}
