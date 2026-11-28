import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/theme/bora_colors.dart';

/// Paleta escura (MP7, S6): `[data-bora][data-theme="dark"]` de
/// `design/mobile/app/source/Bora App.dc.html`.
void main() {
  const d = BoraColors.dark;

  group('BoraColors.dark tem exatamente os hex do design', () {
    final esperado = <String, (Color, int)>{
      'bg': (d.bg, 0xFF0B1512),
      'surface': (d.surface, 0xFF12201C),
      's2': (d.s2, 0xFF1A2C27),
      'border': (d.border, 0xFF24413A),
      'tx': (d.tx, 0xFFE6F2EE),
      'tx2': (d.tx2, 0xFF9FB8B0),
      'pri': (d.pri, 0xFF34D399),
      'priTx': (d.priTx, 0xFF052E22),
      'lip': (d.lip, 0xFF0F8A63),
      'fill': (d.fill, 0xFF34D399),
      'priSoft': (d.priSoft, 0xFF123A2E),
      'blue': (d.blue, 0xFF38BDF8),
      'blueFill': (d.blueFill, 0xFF38BDF8),
      'blueSoft': (d.blueSoft, 0xFF0E2A3A),
      'streak': (d.streak, 0xFFFBBF24),
      'streakInk': (d.streakInk, 0xFFFBBF24),
      'streakSoft': (d.streakSoft, 0xFF3A2E10),
      'danger': (d.danger, 0xFFF87171),
      'obj1': (d.obj1, 0xFF34D399),
      'obj2': (d.obj2, 0xFF38BDF8),
      'obj3': (d.obj3, 0xFF2DD4BF),
      'obj4': (d.obj4, 0xFF10B981),
      'toastIcon': (d.toastIcon, 0xFF0369A1),
      'focusBg': (d.focusBg, 0xFF12201C),
      'ringTrack': (d.ringTrack, 0xFF1A2C27),
      // `--shadow: none`.
      'shadow': (d.shadow, 0x00000000),
      // `--sheetShadow: 0 -8px 32px rgba(0,0,0,.35)` → alfa 0x59.
      'sheetShadow': (d.sheetShadow, 0x59000000),
      'knob': (d.knob, 0xFFFFFFFF),
    };

    for (final MapEntry(key: nome, value: (cor, hex)) in esperado.entries) {
      test(nome, () => expect(cor.toARGB32(), hex));
    }
  });

  group('tokens que o design não define no escuro', () {
    test('bgSoft é o próprio bg', () {
      expect(d.bgSoft, d.bg);
    });

    test('scrim e floatShadow seguem o rgba(14,31,26,…) fixo do protótipo', () {
      // O `.dc.html` escreve o scrim (`rgba(14,31,26,.4)`) e a sombra do
      // toast (`rgba(14,31,26,.18)`) com cor fixa, sem variável: valem nos
      // dois temas.
      expect(d.scrim, BoraColors.light.scrim);
      expect(d.floatShadow, BoraColors.light.floatShadow);
    });
  });

  group('objective e objectiveInk no escuro', () {
    test('as cores dos objetivos vêm da paleta escura', () {
      expect(d.objective(1), d.obj1);
      expect(d.objective(2), d.obj2);
      expect(d.objective(3), d.obj3);
      expect(d.objective(4), d.obj4);
      expect(d.objective(0), d.tx2);
      expect(d.objectiveInk(2), d.blue);
    });
  });

  group('copyWith e lerp', () {
    test('copyWith sem argumentos devolve a paleta escura', () {
      expect(d.copyWith(), same(d));
    });

    test('lerp do claro para o escuro termina no escuro', () {
      final fim = BoraColors.light.lerp(d, 1);
      expect(fim.bg, d.bg);
      expect(fim.tx, d.tx);
      expect(fim.sheetShadow, d.sheetShadow);
      expect(fim.knob, d.knob);
    });

    test('lerp do claro para o escuro começa no claro', () {
      final inicio = BoraColors.light.lerp(d, 0);
      expect(inicio.bg, BoraColors.light.bg);
      expect(inicio.tx, BoraColors.light.tx);
    });

    test('lerp no meio mistura as duas paletas', () {
      final meio = BoraColors.light.lerp(d, .5);
      expect(meio.bg, Color.lerp(BoraColors.light.bg, d.bg, .5));
      expect(meio.pri, Color.lerp(BoraColors.light.pri, d.pri, .5));
      expect(meio.obj4, Color.lerp(BoraColors.light.obj4, d.obj4, .5));
    });

    test('lerp do escuro para o claro termina no claro', () {
      final fim = d.lerp(BoraColors.light, 1);
      expect(fim.bg, BoraColors.light.bg);
      expect(fim.tx2, BoraColors.light.tx2);
    });

    test('lerp sem outra paleta devolve a própria', () {
      expect(d.lerp(null, .5), same(d));
    });
  });
}
