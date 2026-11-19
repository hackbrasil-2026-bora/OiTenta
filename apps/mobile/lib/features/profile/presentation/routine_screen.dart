import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../../core/widgets/bora_widgets.dart';
import '../domain/routine_grid.dart';
import 'routine_controller.dart';

/// Redefinir minha rotina (M27): grade de 2 em 2 horas (8h–22h) × 7 dias,
/// limite diário e "Salvar e recalcular plano" (`.dc.html`, `screens/27`).
class RoutineScreen extends StatelessWidget {
  const RoutineScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onToggle,
    required this.onLimit,
    required this.onSave,
    required this.onRetry,
  });

  final RoutineController state;
  final VoidCallback onBack;
  final void Function(int day, int row) onToggle;
  final ValueChanged<int> onLimit;
  final VoidCallback onSave;

  /// Carrega a rotina de novo depois de uma falha.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    // Sem a rotina carregada, a grade e o slider ficam sem ação (MP11).
    final editable = state.canEdit;
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: onBack)),
      children: [
        Text('Redefinir minha rotina', style: BoraText.h1(c.tx)),
        const SizedBox(height: 2),
        Text(
          'Pinte os horários em que você costuma estar livre. Eu só encaixo etapas neles.',
          style: BoraText.small(c.tx2),
        ),
        const SizedBox(height: 16),
        BoraCard(
          padding: const EdgeInsets.all(12),
          child: IgnorePointer(
            ignoring: !editable,
            child: _Grid(state: state, onToggle: onToggle),
          ),
        ),
        const SizedBox(height: 10),
        _Legend(freeHours: state.freeHours),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'Limite diário'.toUpperCase(),
                style: BoraText.label(c.tx2),
              ),
            ),
            Text(
              '${state.limitHours}h',
              style: BoraText.fredoka(18, 22, color: c.pri),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IgnorePointer(
          ignoring: !editable,
          child: BoraSlider(
            value: state.limitHours.toDouble(),
            min: 1,
            max: 8,
            step: 1,
            semanticLabel: 'Limite diário',
            onChanged: (v) => onLimit(v.round()),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(state.error!, style: BoraText.small(c.danger)),
          ),
          if (state.loadFailed)
            Align(
              alignment: Alignment.centerLeft,
              child: TertiaryButton(
                label: 'Tentar de novo',
                compact: true,
                onPressed: onRetry,
              ),
            ),
        ],
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Salvar e recalcular plano',
          onPressed: state.canSave ? onSave : null,
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.state, required this.onToggle});

  final RoutineController state;
  final void Function(int day, int row) onToggle;

  static const _gap = 4.0;
  static const _labelWidth = 32.0;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    Widget row(Widget label, Widget Function(int day) cell) => Row(
      children: [
        SizedBox(width: _labelWidth, child: label),
        for (var d = 0; d < RoutineGrid.dayCount; d++) ...[
          const SizedBox(width: _gap),
          Expanded(child: cell(d)),
        ],
      ],
    );
    return Column(
      children: [
        row(
          const SizedBox.shrink(),
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              RoutineGrid.dayLabels[d],
              textAlign: TextAlign.center,
              style: BoraText.nunito(
                12,
                16,
                weight: FontWeight.w800,
                color: c.tx2,
              ),
            ),
          ),
        ),
        for (var r = 0; r < RoutineGrid.rowCount; r++) ...[
          const SizedBox(height: _gap),
          row(
            Text(RoutineGrid.rowLabels[r], style: BoraText.caption(c.tx2)),
            (d) => _Cell(
              label: '${RoutineGrid.dayLabels[d]} ${RoutineGrid.rowLabels[r]}',
              free: state.isFree(d, r),
              onTap: () => onToggle(d, r),
            ),
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.free, required this.onTap});

  final String label;
  final bool free;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Semantics(
      button: true,
      selected: free,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: free ? c.fill : c.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: free ? c.fill : c.border),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.freeHours});

  final int freeHours;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    Widget item(Color color, Color border, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: BoraText.caption(c.tx2)),
      ],
    );
    return Row(
      children: [
        item(c.fill, c.fill, 'Livre'),
        const SizedBox(width: 14),
        item(c.surface, c.border, 'Ocupado'),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            '${freeHours}h livres por semana',
            textAlign: TextAlign.right,
            style: BoraText.caption(c.tx2),
          ),
        ),
      ],
    );
  }
}
