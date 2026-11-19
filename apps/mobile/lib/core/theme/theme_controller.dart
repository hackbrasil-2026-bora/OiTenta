import 'package:flutter/material.dart';

/// Tema do app (MP7): claro ou escuro, guardado só em memória
/// (fechar o app volta ao claro, como o token).
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
