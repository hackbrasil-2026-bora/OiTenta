import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../../core/widgets/bora_widgets.dart';
import '../../../core/widgets/bora_buttons.dart';
import 'calendar_widgets.dart';
import 'commitment_card.dart';
import 'commitment_occurrence_view.dart';
import 'week_controller.dart';

/// Calendário (M03/M19 semana, M20 mês, M21 prazos). A tela só desenha o
/// estado do [WeekController] e avisa as ações.
class WeekScreen extends StatelessWidget {
  const WeekScreen({
    super.key,
    required this.state,
    required this.onSelectDay,
    required this.onSelectDate,
    required this.onExpand,
    required this.onCollapse,
    required this.onToggleExpanded,
    required this.onShowMonth,
    required this.onMode,
    required this.onAddCommitment,
    required this.onOpenCommitment,
  });

  final WeekController state;
  final ValueChanged<int> onSelectDay;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onToggleExpanded;

  /// Rolou a grade para outro mês (primeiro dia dele).
  final ValueChanged<DateTime> onShowMonth;
  final ValueChanged<CalendarMode> onMode;

  /// "+ Compromisso" (só em Execução): formulário "Só uma vez" no dia.
  final VoidCallback onAddCommitment;

  /// Toque no compromisso: abre o sheet da ocorrência.
  final ValueChanged<CommitmentOccurrenceView> onOpenCommitment;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    if (state.loading) {
      return BoraPage(children: [Text('Semana', style: BoraText.h1(c.tx))]);
    }
    final deadlines = state.mode == CalendarMode.deadlines;
    final items = state.dayItems;
    final dayDeadlines = state.dayDeadlines;
    return BoraPage(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.title, style: BoraText.h1(c.tx)),
                  const SizedBox(height: 2),
                  Text(state.subtitle, style: BoraText.small(c.tx2)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.s2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Segment(
                    label: 'Execução',
                    active: !deadlines,
                    onTap: () => onMode(CalendarMode.execution),
                  ),
                  _Segment(
                    label: 'Prazos',
                    active: deadlines,
                    onTap: () => onMode(CalendarMode.deadlines),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CalendarCard(
          expanded: state.expanded,
          week: WeekStrip(
            days: state.days,
            selectedIndex: state.selectedIndex,
            onSelectDay: onSelectDay,
          ),
          month: MonthPager(
            initialMonth: state.visibleMonth,
            weeksOf: state.monthWeeksOf,
            onSelectDate: onSelectDate,
            onMonthChanged: onShowMonth,
          ),
          onExpand: onExpand,
          onCollapse: onCollapse,
          onToggle: onToggleExpanded,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final l in state.legend)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Dot(color: c.objective(l.colorIndex)),
                  const SizedBox(width: 6),
                  Text(l.title, style: BoraText.caption(c.tx2)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.dayLabel.toUpperCase(),
                  style: BoraText.label(c.tx2),
                ),
              ),
              if (!deadlines) ...[
                const SizedBox(width: 8),
                TertiaryButton(
                  label: 'Compromisso',
                  icon: PhosphorIconsBold.plus,
                  compact: true,
                  onPressed: onAddCommitment,
                ),
              ],
            ],
          ),
        ),
        if (!deadlines && state.commitmentsError != null) ...[
          const SizedBox(height: 4),
          Text(state.commitmentsError!, style: BoraText.small(c.danger)),
        ],
        const SizedBox(height: 12),
        if (deadlines) ...[
          if (dayDeadlines.isEmpty) const _Empty('Nenhuma entrega neste dia.'),
          for (final d in dayDeadlines) ...[
            DeadlineCard(deadline: d),
            const SizedBox(height: 12),
          ],
        ] else ...[
          if (items.isEmpty) const _Empty('Nada planejado pra esse dia.'),
          for (final i in items) ...[
            if (i.commitment != null)
              _CommitmentRow(
                commitment: i.commitment!,
                onTap: () => onOpenCommitment(i.commitment!),
              )
            else
              _BlockRow(block: i.block!),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: BoraText.small(c.tx2),
      ),
    );
  }
}

/// Compromisso na lista do dia (Execução): hora à esquerda e o cartão.
class _CommitmentRow extends StatelessWidget {
  const _CommitmentRow({required this.commitment, required this.onTap});

  final CommitmentOccurrenceView commitment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              commitment.time,
              textAlign: TextAlign.center,
              style: BoraText.nunito(
                13,
                16,
                weight: FontWeight.w700,
                color: c.tx2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CommitmentCard(commitment: commitment, onTap: onTap),
        ),
      ],
    );
  }
}

/// Bloco de uma etapa na lista do dia (Execução).
class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.block});

  final WeekBlockView block;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final b = block;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              b.time,
              textAlign: TextAlign.center,
              style: BoraText.nunito(
                13,
                16,
                weight: FontWeight.w700,
                color: c.tx2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BoraCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Dot(color: c.objective(b.colorIndex)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.goalTitle,
                        overflow: TextOverflow.ellipsis,
                        style: BoraText.nunito(
                          13,
                          16,
                          weight: FontWeight.w700,
                          color: c.tx2,
                        ),
                      ),
                    ),
                    if (b.pill != null)
                      StatusPill(
                        label: b.pill!,
                        bg: b.done ? c.priSoft : c.s2,
                        fg: b.done ? c.pri : c.tx2,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(b.title, style: BoraText.h3(b.done ? c.tx2 : c.tx)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.clock, size: 16, color: c.tx2),
                    const SizedBox(width: 4),
                    Text(
                      b.duration,
                      style: BoraText.nunito(
                        13,
                        16,
                        weight: FontWeight.w700,
                        color: c.tx2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? c.surface : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? c.border : c.s2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: BoraText.nunito(
              13,
              13,
              weight: FontWeight.w800,
              color: active ? c.tx : c.tx2,
            ),
          ),
        ),
      ),
    );
  }
}
