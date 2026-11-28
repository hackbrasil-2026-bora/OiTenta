// Gera o ícone do app (Android e iOS) a partir do widget Broto.
//
// Não roda com o `flutter test` normal (fica fora de test/). Para gerar de
// novo depois de mudar o Broto ou as cores, rode em apps/mobile:
//
//   flutter test tool/app_icon/generate_app_icon_test.dart
//
// Escreve os PNGs em android/app/src/main/res/mipmap-*/ e em
// ios/Runner/Assets.xcassets/AppIcon.appiconset/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/widgets/broto.dart';

/// Fundo do ícone: `priSoft` do tema claro (bora_colors.dart). Igual a
/// `ic_launcher_background` em android/app/src/main/res/values/colors.xml.
const _background = Color(0xFFD1FAE5);

/// Densidades do Android: nome da pasta → fator sobre 1 dp.
const _androidDensities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

/// Ícones do iOS: arquivo → lado em pixels.
const _iosIcons = {
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

/// Parte da caixa 120×120 do Broto que o desenho ocupa na vertical: da ponta
/// da folha (y 17) até a sombra no chão (y 116). O centro do desenho fica em
/// y 66,5, abaixo do centro da caixa (60).
const _artTop = 17.0;
const _artBottom = 116.0;

/// Desenha o Broto num quadrado de [side] px, com o desenho ocupando
/// [brotoFraction] da altura e centralizado pelo desenho (não pela caixa),
/// sobre [background] (ou transparente).
Future<List<int>> _render(
  WidgetTester tester, {
  required int side,
  required double brotoFraction,
  Color? background,
}) async {
  final key = GlobalKey();
  const logical = 512.0;
  final box = logical * brotoFraction * 120 / (_artBottom - _artTop);
  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: logical,
          height: logical,
          color: background ?? Colors.transparent,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, -((_artTop + _artBottom) / 2 - 60) / 120 * box),
            child: Broto(size: box),
          ),
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: side / logical);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }))!;
}

/// Grava fora do relógio simulado do teste (senão o IO nunca termina).
Future<void> _write(WidgetTester tester, String path, List<int> bytes) =>
    tester.runAsync(() async {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    });

void main() {
  testWidgets('gera o ícone do app a partir do Broto', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const res = 'android/app/src/main/res';
    for (final MapEntry(key: folder, value: factor)
        in _androidDensities.entries) {
      // Ícone antigo (Android 7 ou anterior): quadrado de 48 dp com fundo.
      await _write(
        tester,
        '$res/mipmap-$folder/ic_launcher.png',
        await _render(
          tester,
          side: (48 * factor).round(),
          brotoFraction: .72,
          background: _background,
        ),
      );
      // Ícone adaptativo (Android 8+): camada da frente de 108 dp, com o
      // Broto dentro da zona segura de 66 dp que nenhuma máscara corta.
      await _write(
        tester,
        '$res/mipmap-$folder/ic_launcher_foreground.png',
        await _render(
          tester,
          side: (108 * factor).round(),
          brotoFraction: 66 / 108,
        ),
      );
    }

    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final MapEntry(key: file, value: side) in _iosIcons.entries) {
      // O iOS arredonda os cantos sozinho e não aceita transparência.
      await _write(
        tester,
        '$ios/$file',
        await _render(
          tester,
          side: side,
          brotoFraction: .72,
          background: _background,
        ),
      );
    }
  });
}
