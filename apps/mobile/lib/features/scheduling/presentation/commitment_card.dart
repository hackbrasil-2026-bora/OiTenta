import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_widgets.dart';
import '../domain/commitment.dart';
import 'commitment_occurrence_view.dart';

/// Ícone do tipo (`cpIcon` do protótipo).
IconData commitmentIcon(CommitmentCategory category) => switch (category) {
  CommitmentCategory.aula => PhosphorIconsRegular.graduationCap,
  CommitmentCategory.trabalho => PhosphorIconsRegular.briefcase,
  CommitmentCategory.saude => PhosphorIconsRegular.barbell,
  CommitmentCategory.pessoal => PhosphorIconsRegular.user,
};

/// Linha do compromisso na lista do dia (template `isCp` da Semana; o Hoje
/// reaproveita o cartão). Fundo `--s2`; cancelado: título riscado, borda
/// tracejada e fundo transparente.
class CommitmentCard extends StatelessWidget {
  const CommitmentCard({
    super.key,
    required this.commitment,
    required this.onTap,
  });

  final CommitmentOccurrenceView commitment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final v = commitment;
    final off = v.cancelled;
    final meta = BoraText.nunito(12, 16, weight: FontWeight.w700, color: c.tx2);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            alignment: Alignment.center,
            child: Icon(commitmentIcon(v.category), size: 20, color: c.tx2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (v.isRecurring) ...[
                      Icon(PhosphorIconsRegular.repeat, size: 14, color: c.tx2),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        'Compromisso · ${v.repetition}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: meta,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  v.title,
                  style: BoraText.fredoka(16, 22, color: off ? c.tx2 : c.tx)
                      .copyWith(
                        decoration: off ? TextDecoration.lineThrough : null,
                      ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      v.hours,
                      style: BoraText.nunito(
                        13,
                        16,
                        weight: FontWeight.w700,
                        color: c.tx2,
                      ),
                    ),
                    if (v.pill != null)
                      StatusPill(
                        label: v.pill!,
                        bg: off ? c.s2 : c.blueSoft,
                        fg: off ? c.tx2 : c.blue,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(PhosphorIconsBold.caretRight, size: 16, color: c.tx2),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: 'Opções de ${v.title}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: off
            ? CustomPaint(
                painter: _DashedBorder(color: c.border, radius: 16),
                child: content,
              )
            : Container(
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: content,
              ),
      ),
    );
  }
}

/// Borda tracejada de 1px (`1px dashed var(--border)`).
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(.5),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}
