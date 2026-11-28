import 'dart:async';

import 'package:flutter/services.dart';

/// Esconde a barra de navegação do Android (voltar, início e abas) e deixa só
/// a barra de status (hora e bateria), como nos outros apps em tela cheia.
///
/// Arrastar a partir da borda de baixo mostra a barra; ela some sozinha
/// depois de [rehideDelay]. Fora do Android (iOS, testes de outras telas)
/// não faz nada.
class ImmersiveNavigationBar {
  ImmersiveNavigationBar({
    required this.isAndroid,
    this.rehideDelay = const Duration(seconds: 3),
  });

  final bool isAndroid;
  final Duration rehideDelay;

  Timer? _rehide;

  Future<void> start() async {
    if (!isAndroid) return;
    await hide();
    await SystemChrome.setSystemUIChangeCallback((visible) async {
      _rehide?.cancel();
      if (visible) _rehide = Timer(rehideDelay, hide);
    });
  }

  /// Esconde a barra de navegação agora (também ao voltar para o app).
  Future<void> hide() async {
    if (!isAndroid) return;
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );
  }

  void dispose() {
    _rehide?.cancel();
    _rehide = null;
    if (isAndroid) SystemChrome.setSystemUIChangeCallback(null);
  }
}
