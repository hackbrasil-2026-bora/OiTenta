import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Esconde a barra de navegação do Android (voltar, início e abas) e deixa só
/// a barra de status (hora e bateria), como nos outros apps em tela cheia.
///
/// Arrastar a partir da borda de baixo mostra a barra; ela some sozinha
/// depois de [rehideDelay]. [visible] avisa as telas (a tab bar sobe junto,
/// ver `SystemNavigationBarScope`). O fundo do sistema fica transparente: o
/// app desenha o verde por trás dos botões. Fora do Android (iOS, testes de
/// outras telas) não faz nada.
class ImmersiveNavigationBar {
  ImmersiveNavigationBar({
    required this.isAndroid,
    this.rehideDelay = const Duration(seconds: 3),
  });

  final bool isAndroid;
  final Duration rehideDelay;

  /// Se os botões do Android estão aparecendo agora.
  final ValueNotifier<bool> visible = ValueNotifier(false);

  Timer? _rehide;

  Future<void> start() async {
    if (!isAndroid) return;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    await hide();
    await SystemChrome.setSystemUIChangeCallback((shown) async {
      _rehide?.cancel();
      visible.value = shown;
      if (shown) _rehide = Timer(rehideDelay, hide);
    });
  }

  /// Esconde a barra de navegação agora (também ao voltar para o app).
  Future<void> hide() async {
    if (!isAndroid) return;
    visible.value = false;
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.top],
    );
  }

  void dispose() {
    _rehide?.cancel();
    _rehide = null;
    if (isAndroid) SystemChrome.setSystemUIChangeCallback(null);
    visible.dispose();
  }
}
