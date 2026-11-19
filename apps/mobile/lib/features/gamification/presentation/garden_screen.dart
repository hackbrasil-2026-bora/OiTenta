import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../../core/widgets/bora_widgets.dart';
import '../../../core/widgets/broto.dart';
import '../domain/garden.dart';
import 'garden_controller.dart';
import 'home_top_bar.dart';

/// Jardim (M04, M39): Broto, dias regados, conquistas e guarda-chuva, com os
/// valores fixos do protótipo (P18). "Trocar por 50" não tem ação (MP13).
class GardenScreen extends StatelessWidget {
  const GardenScreen({
    super.key,
    required this.state,
    required this.onProfile,
    this.onBroto,
  });

  final GardenController state;

  /// Botão com a inicial: abre o Perfil (M26).
  final VoidCallback? onProfile;

  /// Broto do topo. No Jardim não faz nada, como no protótipo.
  final VoidCallback? onBroto;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final g = state.garden;
    return BoraPage(
      topBar: HomeTopBar(
        gamification: state.gamification,
        userName: state.userName,
        onBroto: onBroto,
        onProfile: onProfile,
      ),
      children: [
        Text('Jardim', style: BoraText.h1(c.tx)),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(state.error!, style: BoraText.small(c.danger)),
        ],
        if (g != null) ...[
          const SizedBox(height: 16),
          _BrotoCard(garden: g),
          const SizedBox(height: 24),
          SectionHeader(label: 'Dias regados', trailing: g.streakLabel),
          const SizedBox(height: 12),
          _Days(days: g.days),
          const SizedBox(height: 24),
          SectionHeader(label: 'Conquistas', trailing: g.badgesLabel),
          const SizedBox(height: 12),
          for (var i = 0; i < g.badges.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _BadgeRow(index: i, badge: g.badges[i]),
          ],
          const SizedBox(height: 24),
          _UmbrellaCard(garden: g),
        ],
      ],
    );
  }
}

class _BrotoCard extends StatelessWidget {
  const _BrotoCard({required this.garden});

  final Garden garden;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return BoraCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          const Broto(mood: BrotoMood.ok, size: 130),
          const SizedBox(height: 16),
          Text(garden.name, style: BoraText.h2(c.tx)),
          const SizedBox(height: 4),
          Text(garden.stageLabel, style: BoraText.small(c.tx2)),
          const SizedBox(height: 16),
          ProgressBar(value: garden.levelProgress, color: c.fill, height: 10),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(garden.nextLevelLabel, style: BoraText.caption(c.tx2)),
          ),
        ],
      ),
    );
  }
}

class _Days extends StatelessWidget {
  const _Days({required this.days});

  final List<GardenDay> days;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                AspectRatio(aspectRatio: 1, child: _dayTile(c, i, days[i])),
                const SizedBox(height: 4),
                Text(days[i].label, style: BoraText.caption(c.tx2)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dayTile(BoraColors c, int i, GardenDay day) {
    final (Color? bg, IconData icon, Color iconColor) = switch (day.state) {
      GardenDayState.watered => (c.priSoft, PhosphorIconsFill.drop, c.pri),
      GardenDayState.umbrella => (
        c.blueSoft,
        PhosphorIconsFill.umbrella,
        c.blue,
      ),
      GardenDayState.pending => (null, PhosphorIconsRegular.drop, c.tx2),
    };
    final tile = Container(
      key: Key('garden-day-$i'),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: iconColor),
    );
    if (day.state != GardenDayState.pending) return tile;
    return CustomPaint(
      key: Key('garden-day-$i-dashed'),
      foregroundPainter: _DashedBorderPainter(color: c.border, radius: 12),
      child: tile,
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.index, required this.badge});

  final int index;
  final GardenBadge badge;

  static IconData _icon(String name) => switch (name) {
    'footprints' => PhosphorIconsFill.footprints,
    'flag-checkered' => PhosphorIconsFill.flagCheckered,
    'arrow-counter-clockwise' => PhosphorIconsFill.arrowCounterClockwise,
    'paper-plane-tilt' => PhosphorIconsFill.paperPlaneTilt,
    _ => PhosphorIconsFill.drop,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final (
      Color bg,
      Color? ring,
      IconData icon,
      Color iconColor,
      Color nameColor,
      Color subColor,
    ) = switch (badge.state) {
      GardenBadgeState.rare => (
        c.streakSoft,
        c.streak,
        _icon(badge.icon),
        c.streakInk,
        c.tx,
        c.streakInk,
      ),
      GardenBadgeState.earned => (
        c.priSoft,
        c.fill,
        _icon(badge.icon),
        c.pri,
        c.tx,
        c.tx2,
      ),
      GardenBadgeState.locked => (
        c.s2,
        null,
        PhosphorIconsRegular.lockSimple,
        c.tx2,
        c.tx2,
        c.tx2,
      ),
    };
    final circle = Container(
      key: Key('garden-badge-$index'),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: ring == null ? null : Border.all(color: ring, width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 26, color: iconColor),
    );
    return Row(
      children: [
        if (ring == null)
          CustomPaint(
            key: Key('garden-badge-$index-dashed'),
            foregroundPainter: _DashedBorderPainter(
              color: c.border,
              radius: 28,
            ),
            child: circle,
          )
        else
          circle,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.name,
                style: BoraText.fredoka(16, 20, color: nameColor),
              ),
              Text(badge.description, style: BoraText.caption(subColor)),
            ],
          ),
        ),
      ],
    );
  }
}

class _UmbrellaCard extends StatelessWidget {
  const _UmbrellaCard({required this.garden});

  final Garden garden;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return BoraCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  PhosphorIconsFill.umbrella,
                  size: 24,
                  color: c.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guarda-chuva', style: BoraText.h3(c.tx)),
                    Text(garden.umbrellaLabel, style: BoraText.caption(c.tx2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // MP13: mesma aparência do protótipo, mas sem ação.
          Semantics(
            button: true,
            child: Container(
              key: const Key('garden-buy-umbrella'),
              height: 52,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.border, width: 2),
                boxShadow: [
                  BoxShadow(color: c.border, offset: const Offset(0, 3)),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Trocar por ${Garden.umbrellaPrice}',
                    style: BoraText.button(c.blue),
                  ),
                  const SizedBox(width: 6),
                  Icon(PhosphorIconsFill.drop, size: 16, color: c.blueFill),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Borda tracejada de 2px (o `2px dashed var(--border)` do protótipo).
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = math.min(radius, size.shortestSide / 2);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          Radius.circular(r),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
