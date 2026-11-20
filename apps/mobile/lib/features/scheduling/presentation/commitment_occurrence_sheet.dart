import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import 'commitment_card.dart';
import 'commitment_occurrence_controller.dart';

/// Ícone Phosphor de cada toast do sheet.
IconData occurrenceToastIcon(OccurrenceToastKind kind) => switch (kind) {
  OccurrenceToastKind.freed => PhosphorIconsBold.calendarX,
  OccurrenceToastKind.back ||
  OccurrenceToastKind.restored => PhosphorIconsBold.arrowCounterClockwise,
  OccurrenceToastKind.deleted ||
  OccurrenceToastKind.ended => PhosphorIconsBold.trash,
};

IconData _actionIcon(OccurrenceActionKind kind) => switch (kind) {
  OccurrenceActionKind.edit => PhosphorIconsRegular.pencilSimple,
  OccurrenceActionKind.skip => PhosphorIconsRegular.calendarX,
  OccurrenceActionKind.restore => PhosphorIconsRegular.arrowCounterClockwise,
  OccurrenceActionKind.delete => PhosphorIconsRegular.trash,
};

/// Sheet da ocorrência (`sheetCpOcc`): cabeçalho, menu de ações, dia
/// cancelado ("Vai ter sim") e o passo de escopo. Só desenha o
/// [CommitmentOccurrenceController] e avisa as ações.
class CommitmentOccurrenceSheet extends StatelessWidget {
  const CommitmentOccurrenceSheet({
    super.key,
    required this.state,
    required this.onAction,
    required this.onKeep,
    required this.onScope,
    required this.onConfirm,
    required this.onBack,
  });

  final CommitmentOccurrenceController state;
  final ValueChanged<OccurrenceActionKind> onAction;
  final VoidCallback onKeep;
  final ValueChanged<OccurrenceScopeChoice> onScope;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final busy = state.busy;
    final status = state.statusLabel;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [BoxShadow(color: c.sheetShadow, blurRadius: 24)],
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom > 0 ? bottom : 34),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.s2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    commitmentIcon(state.category),
                    size: 22,
                    color: c.pri,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.title, style: BoraText.h3(c.tx)),
                      const SizedBox(height: 2),
                      Text(
                        state.whenLabel,
                        style: BoraText.nunito(13, 16, color: c.tx2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(
                  label: state.repetition,
                  icon: PhosphorIconsRegular.repeat,
                  bg: c.s2,
                  fg: c.tx,
                ),
                if (status != null)
                  _Chip(label: status, bg: c.blueSoft, fg: c.blue),
              ],
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!, style: BoraText.small(c.danger)),
            ],
            if (state.isCancelled) ...[
              const SizedBox(height: 12),
              Text(
                'Liberei esse horário só nesse dia. '
                'As outras semanas continuam iguais.',
                style: BoraText.small(c.tx2),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Vai ter sim',
                height: 48,
                onPressed: busy ? null : onKeep,
              ),
            ] else if (state.scopeStep)
              ..._scopeStep(c, busy)
            else
              for (final a in state.actions) ...[
                const SizedBox(height: 8),
                _ActionRow(
                  action: a,
                  onTap: busy ? null : () => onAction(a.kind),
                ),
              ],
          ],
        ),
      ),
    );
  }

  List<Widget> _scopeStep(BoraColors c, bool busy) => [
    const SizedBox(height: 12),
    Text(
      state.scopeTitle,
      style: BoraText.nunito(13, 16, weight: FontWeight.w800, color: c.tx),
    ),
    for (final s in state.scopes) ...[
      const SizedBox(height: 8),
      _ScopeRow(scope: s, onTap: busy ? null : () => onScope(s.choice)),
    ],
    const SizedBox(height: 12),
    if (state.isDeleteStep)
      _DangerButton(label: 'Excluir', onPressed: busy ? null : onConfirm)
    else
      PrimaryButton(
        label: 'Continuar',
        height: 48,
        onPressed: busy ? null : onConfirm,
      ),
    const SizedBox(height: 4),
    Center(
      child: TertiaryButton(label: 'Voltar', onPressed: busy ? null : onBack),
    ),
  ];
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c.tx2),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: BoraText.nunito(13, 13, weight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Linha do menu (`ocAcoes`): tile, nome, descrição e chevron.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});

  final OccurrenceActionView action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final danger = action.kind == OccurrenceActionKind.delete;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _actionIcon(action.kind),
                  size: 20,
                  color: danger ? c.danger : c.pri,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.name,
                      style: BoraText.nunito(
                        15,
                        20,
                        weight: FontWeight.w800,
                        color: c.tx,
                      ),
                    ),
                    Text(action.description, style: BoraText.caption(c.tx2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(PhosphorIconsBold.caretRight, size: 16, color: c.tx2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opção do escopo (`ocEscopos`): selecionada em `--priSoft` com o check.
class _ScopeRow extends StatelessWidget {
  const _ScopeRow({required this.scope, required this.onTap});

  final OccurrenceScopeView scope;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final sel = scope.selected;
    return Semantics(
      button: true,
      selected: sel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
          decoration: BoxDecoration(
            color: sel ? c.priSoft : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? c.pri : c.border, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scope.name,
                      style: BoraText.nunito(
                        15,
                        20,
                        weight: FontWeight.w800,
                        color: c.tx,
                      ),
                    ),
                    Text(scope.description, style: BoraText.caption(c.tx2)),
                  ],
                ),
              ),
              if (sel) ...[
                const SizedBox(width: 10),
                Icon(PhosphorIconsFill.checkCircle, size: 22, color: c.pri),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão "Excluir" do escopo: secundário com texto e ícone `--danger`.
class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.border, width: 2),
            boxShadow: [BoxShadow(color: c.border, offset: const Offset(0, 3))],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsBold.trash, size: 18, color: c.danger),
              const SizedBox(width: 8),
              Text(label, style: BoraText.button(c.danger)),
            ],
          ),
        ),
      ),
    );
  }
}
