import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_input.dart';
import '../../../core/widgets/bora_scaffold.dart';
import 'single_tasks_controller.dart';

/// Tarefas únicas (M53–M54, template `TAREFAS ÚNICAS`).
class SingleTasksScreen extends StatelessWidget {
  const SingleTasksScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onText,
    required this.onDuration,
    required this.onWhen,
    required this.onPickDay,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final SingleTasksController state;
  final VoidCallback onBack;
  final ValueChanged<String> onText;
  final ValueChanged<int> onDuration;

  /// Hoje, Amanhã ou Sem data.
  final ValueChanged<SingleTaskWhen> onWhen;

  /// "Escolher dia".
  final VoidCallback onPickDay;
  final VoidCallback onAdd;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final add = state.canAdd ? onAdd : null;
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: onBack)),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 128),
      children: [
        Text('Tarefas únicas', style: BoraText.h1(c.tx)),
        const SizedBox(height: 2),
        Text(
          'Coisas rápidas que não precisam virar objetivo. '
          'Eu encaixo nos seus horários livres.',
          style: BoraText.small(c.tx2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BoraInput(
                value: state.text,
                onChanged: onText,
                hint: 'Ex.: Arrumar o guarda-roupa',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => add?.call(),
              ),
            ),
            const SizedBox(width: 8),
            _AddCircle(onPressed: add),
          ],
        ),
        if (state.panelOpen) _AddPanel(screen: this, onAdd: add),
        for (final g in state.groups) ...[
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  g.title.toUpperCase(),
                  style: BoraText.label(c.tx2),
                ),
              ),
              Text(g.count, style: BoraText.caption(c.tx2)),
            ],
          ),
          for (final it in g.items) ...[
            const SizedBox(height: 8),
            _TaskItem(
              item: it,
              onToggle: state.busy ? null : () => onToggle(it.id),
              onDelete: state.busy ? null : () => onDelete(it.id),
            ),
          ],
        ],
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Text(state.error!, style: BoraText.small(c.danger)),
        ],
      ],
    );
  }
}

/// Botão "+" (52, redondo, com lábio) ao lado do campo.
class _AddCircle extends StatelessWidget {
  const _AddCircle({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final on = onPressed != null;
    return Semantics(
      button: true,
      enabled: on,
      label: 'Adicionar tarefa',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? c.pri : c.s2,
            boxShadow: [
              BoxShadow(
                color: on ? c.lip : c.border,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            PhosphorIconsBold.plus,
            size: 22,
            color: on ? c.priTx : c.tx2,
          ),
        ),
      ),
    );
  }
}

/// Painel "Quanto tempo leva?" / "Quando?" / "Adicionar tarefa".
class _AddPanel extends StatelessWidget {
  const _AddPanel({required this.screen, required this.onAdd});

  final SingleTasksScreen screen;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final s = screen.state;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(color: c.shadow, offset: const Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text('QUANTO TEMPO LEVA?', style: BoraText.label(c.tx2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in s.durations)
                _Chip(
                  label: SingleTasksController.durationLabel(m),
                  selected: s.minutes == m,
                  onTap: () => screen.onDuration(m),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('QUANDO?', style: BoraText.label(c.tx2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (w, l) in const [
                (SingleTaskWhen.today, 'Hoje'),
                (SingleTaskWhen.tomorrow, 'Amanhã'),
                (SingleTaskWhen.none, 'Sem data'),
              ])
                _Chip(
                  label: l,
                  selected: s.when == w,
                  onTap: () => screen.onWhen(w),
                ),
              _Chip(
                label: s.dayChipLabel,
                icon: PhosphorIconsRegular.calendarBlank,
                selected: s.when == SingleTaskWhen.day,
                onTap: screen.onPickDay,
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Adicionar tarefa', onPressed: onAdd),
        ],
      ),
    );
  }
}

/// Chip de escolha com ícone opcional (`chip` do protótipo).
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? c.priSoft : c.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? c.pri : c.border, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: c.pri),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: BoraText.nunito(
                  13,
                  13,
                  weight: FontWeight.w800,
                  color: c.tx,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item: caixa de marcar, título, subtítulo e lixeira.
class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final SingleTaskItemView item;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final done = item.done;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(color: c.shadow, offset: const Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            checked: done,
            label: item.toggleLabel,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: done ? c.pri : c.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: done ? c.pri : c.border,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: done
                        ? Icon(
                            PhosphorIconsBold.check,
                            size: 14,
                            color: c.priTx,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style:
                      BoraText.nunito(
                        15,
                        20,
                        weight: FontWeight.w800,
                        color: done ? c.tx2 : c.tx,
                      ).copyWith(
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: BoraText.caption(c.tx2)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Excluir tarefa',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDelete,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(PhosphorIconsRegular.trash, size: 18, color: c.tx2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
