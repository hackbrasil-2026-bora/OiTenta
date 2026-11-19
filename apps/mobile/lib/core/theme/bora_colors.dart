import 'package:flutter/material.dart';

/// Tokens de cor do protótipo mobile (`design/mobile/app/source/Bora App.dc.html`,
/// `[data-bora]`) e de `design/tokens.md`.
///
/// Os widgets leem as cores só por aqui (`context.bora`), nunca por hex.
@immutable
class BoraColors extends ThemeExtension<BoraColors> {
  const BoraColors({
    required this.bg,
    required this.bgSoft,
    required this.surface,
    required this.s2,
    required this.border,
    required this.tx,
    required this.tx2,
    required this.pri,
    required this.priTx,
    required this.lip,
    required this.fill,
    required this.priSoft,
    required this.blue,
    required this.blueFill,
    required this.blueSoft,
    required this.streak,
    required this.streakInk,
    required this.streakSoft,
    required this.danger,
    required this.toastIcon,
    required this.focusBg,
    required this.ringTrack,
    required this.obj1,
    required this.obj2,
    required this.obj3,
    required this.obj4,
    required this.scrim,
    required this.shadow,
    required this.floatShadow,
    required this.sheetShadow,
    required this.knob,
  });

  /// `--bg` do Bora App mobile (#FFFFFF).
  final Color bg;

  /// `--bg` do Bora Telas (#F6FAF8), usado no onboarding (divergência 1 de
  /// `design/tokens.md`).
  final Color bgSoft;
  final Color surface;
  final Color s2;
  final Color border;
  final Color tx;
  final Color tx2;
  final Color pri;
  final Color priTx;
  final Color lip;
  final Color fill;
  final Color priSoft;
  final Color blue;
  final Color blueFill;
  final Color blueSoft;
  final Color streak;
  final Color streakInk;
  final Color streakSoft;
  final Color danger;
  final Color toastIcon;
  final Color focusBg;
  final Color ringTrack;
  final Color obj1;
  final Color obj2;
  final Color obj3;
  final Color obj4;

  /// Scrim de sheet `rgba(14,31,26,.4)`.
  final Color scrim;

  /// `--shadow` (card): `0 1px 2px rgba(14,31,26,.04)`; `none` no escuro.
  final Color shadow;

  /// Sombra flutuante (toast): `0 8px 24px rgba(14,31,26,.18)`.
  final Color floatShadow;

  /// `--sheetShadow`: `0 -8px 32px rgba(14,31,26,.08)`; no escuro,
  /// `rgba(0,0,0,.35)`.
  final Color sheetShadow;

  /// Bolinha dos sliders e interruptores (`#FFFFFF` nos dois temas).
  final Color knob;

  static const light = BoraColors(
    bg: Color(0xFFFFFFFF),
    bgSoft: Color(0xFFF6FAF8),
    surface: Color(0xFFFFFFFF),
    s2: Color(0xFFEAF5F0),
    border: Color(0xFFD5E6DF),
    tx: Color(0xFF0E1F1A),
    tx2: Color(0xFF4A5D57),
    pri: Color(0xFF047857),
    priTx: Color(0xFFFFFFFF),
    lip: Color(0xFF065F46),
    fill: Color(0xFF10B981),
    priSoft: Color(0xFFD1FAE5),
    blue: Color(0xFF0369A1),
    blueFill: Color(0xFF0EA5E9),
    blueSoft: Color(0xFFE0F2FE),
    streak: Color(0xFFF59E0B),
    streakInk: Color(0xFFB45309),
    streakSoft: Color(0xFFFEF3C7),
    danger: Color(0xFFDC2626),
    toastIcon: Color(0xFF38BDF8),
    focusBg: Color(0xFFE0F2FE),
    ringTrack: Color(0xFFFFFFFF),
    obj1: Color(0xFF10B981),
    obj2: Color(0xFF0EA5E9),
    obj3: Color(0xFF2DD4BF),
    obj4: Color(0xFF059669),
    scrim: Color(0x660E1F1A),
    shadow: Color(0x0A0E1F1A),
    floatShadow: Color(0x2E0E1F1A),
    sheetShadow: Color(0x140E1F1A),
    knob: Color(0xFFFFFFFF),
  );

  /// `[data-bora][data-theme="dark"]` do Bora App mobile (MP7) e
  /// `design/tokens.md`, "Modo escuro".
  ///
  /// O design não define `bgSoft` no escuro (é o `--bg` do Bora Telas, só
  /// claro): usa o próprio `--bg`. O scrim e a sombra do toast são
  /// `rgba(14,31,26,…)` fixos no protótipo, sem variável, então valem nos dois
  /// temas.
  static const dark = BoraColors(
    bg: Color(0xFF0B1512),
    bgSoft: Color(0xFF0B1512),
    surface: Color(0xFF12201C),
    s2: Color(0xFF1A2C27),
    border: Color(0xFF24413A),
    tx: Color(0xFFE6F2EE),
    tx2: Color(0xFF9FB8B0),
    pri: Color(0xFF34D399),
    priTx: Color(0xFF052E22),
    lip: Color(0xFF0F8A63),
    fill: Color(0xFF34D399),
    priSoft: Color(0xFF123A2E),
    blue: Color(0xFF38BDF8),
    blueFill: Color(0xFF38BDF8),
    blueSoft: Color(0xFF0E2A3A),
    streak: Color(0xFFFBBF24),
    streakInk: Color(0xFFFBBF24),
    streakSoft: Color(0xFF3A2E10),
    danger: Color(0xFFF87171),
    toastIcon: Color(0xFF0369A1),
    focusBg: Color(0xFF12201C),
    ringTrack: Color(0xFF1A2C27),
    obj1: Color(0xFF34D399),
    obj2: Color(0xFF38BDF8),
    obj3: Color(0xFF2DD4BF),
    obj4: Color(0xFF10B981),
    scrim: Color(0x660E1F1A),
    shadow: Color(0x00000000),
    floatShadow: Color(0x2E0E1F1A),
    sheetShadow: Color(0x59000000),
    knob: Color(0xFFFFFFFF),
  );

  /// Cor do objetivo pelo `colorIndex` (P4). O índice 0 é a tarefa avulsa.
  Color objective(int colorIndex) {
    switch (colorIndex) {
      case 1:
        return obj1;
      case 2:
        return obj2;
      case 3:
        return obj3;
      case 4:
        return obj4;
      default:
        return tx2;
    }
  }

  /// Cor de texto que acompanha o objetivo (DATA `OBJ[].ink`).
  Color objectiveInk(int colorIndex) {
    switch (colorIndex) {
      case 1:
      case 4:
        return pri;
      case 2:
        return blue;
      default:
        return tx;
    }
  }

  /// As paletas são fixas (claro e escuro): `copyWith` sem argumentos devolve
  /// a própria paleta.
  @override
  BoraColors copyWith() => this;

  /// Mistura cor a cor, para a animação de troca de tema (MP7) não deixar os
  /// tokens presos ao tema anterior.
  @override
  BoraColors lerp(ThemeExtension<BoraColors>? other, double t) {
    if (other is! BoraColors) return this;
    return BoraColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSoft: Color.lerp(bgSoft, other.bgSoft, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      s2: Color.lerp(s2, other.s2, t)!,
      border: Color.lerp(border, other.border, t)!,
      tx: Color.lerp(tx, other.tx, t)!,
      tx2: Color.lerp(tx2, other.tx2, t)!,
      pri: Color.lerp(pri, other.pri, t)!,
      priTx: Color.lerp(priTx, other.priTx, t)!,
      lip: Color.lerp(lip, other.lip, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      priSoft: Color.lerp(priSoft, other.priSoft, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueFill: Color.lerp(blueFill, other.blueFill, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      streakInk: Color.lerp(streakInk, other.streakInk, t)!,
      streakSoft: Color.lerp(streakSoft, other.streakSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      toastIcon: Color.lerp(toastIcon, other.toastIcon, t)!,
      focusBg: Color.lerp(focusBg, other.focusBg, t)!,
      ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
      obj1: Color.lerp(obj1, other.obj1, t)!,
      obj2: Color.lerp(obj2, other.obj2, t)!,
      obj3: Color.lerp(obj3, other.obj3, t)!,
      obj4: Color.lerp(obj4, other.obj4, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      floatShadow: Color.lerp(floatShadow, other.floatShadow, t)!,
      sheetShadow: Color.lerp(sheetShadow, other.sheetShadow, t)!,
      knob: Color.lerp(knob, other.knob, t)!,
    );
  }
}

extension BoraColorsContext on BuildContext {
  BoraColors get bora => Theme.of(this).extension<BoraColors>()!;
}
