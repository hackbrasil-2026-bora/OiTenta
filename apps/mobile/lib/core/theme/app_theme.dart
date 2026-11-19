import 'package:flutter/material.dart';

import 'bora_colors.dart';
import 'bora_text.dart';

/// `ThemeData` do app com os tokens do protótipo mobile, nos modos claro e
/// escuro (MP7).
abstract final class AppTheme {
  static ThemeData light() => _build(BoraColors.light, Brightness.light);

  /// Tema escuro (MP7): `[data-bora][data-theme="dark"]` do protótipo.
  static ThemeData dark() => _build(BoraColors.dark, Brightness.dark);

  static ThemeData _build(BoraColors c, Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final scheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: c.pri,
            onPrimary: c.priTx,
            secondary: c.blue,
            surface: c.surface,
            onSurface: c.tx,
            error: c.danger,
          )
        : ColorScheme.light(
            primary: c.pri,
            onPrimary: c.priTx,
            secondary: c.blue,
            surface: c.surface,
            onSurface: c.tx,
            error: c.danger,
          );
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      colorScheme: scheme,
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
      extensions: [c],
    );
  }
}
