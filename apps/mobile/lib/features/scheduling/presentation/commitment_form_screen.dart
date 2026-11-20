import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_input.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../../core/widgets/bora_widgets.dart';
import '../domain/commitment.dart';
import 'commitment_form_controller.dart';
import 'time_range_field.dart';

/// Ícones do "Tipo" (`TIPOS` do protótipo).
IconData commitmentCategoryIcon(CommitmentCategory c) => switch (c) {
  CommitmentCategory.aula => PhosphorIconsRegular.graduationCap,
  CommitmentCategory.trabalho => PhosphorIconsRegular.briefcase,
  CommitmentCategory.saude => PhosphorIconsRegular.barbell,
  CommitmentCategory.pessoal => PhosphorIconsRegular.user,
};

/// Novo/Editar compromisso (M46, M47, M52; template `NOVO COMPROMISSO`).
class CommitmentFormScreen extends StatelessWidget {
  const CommitmentFormScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onTitle,
    required this.onCategory,
    required this.onRepeat,
    required this.onWeekday,
    required this.onUntil,
    required this.onPickDate,
    required this.onStart,
    required this.onEnd,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
  });

  final CommitmentFormController state;
  final VoidCallback onBack;
  final ValueChanged<String> onTitle;
  final ValueChanged<CommitmentCategory> onCategory;
  final ValueChanged<CommitmentRepeat> onRepeat;
  final ValueChanged<int> onWeekday;
  final ValueChanged<CommitmentUntil> onUntil;
  final VoidCallback onPickDate;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onEnd;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final s = state;
    Widget label(String t, {double top = 16}) => Padding(
      padding: EdgeInsets.only(top: top, bottom: 8),
      child: Text(t.toUpperCase(), style: BoraText.label(c.tx2)),
    );
    final error = s.error == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(s.error!, style: BoraText.small(c.danger)),
          );
    final cancel = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: TertiaryButton(label: 'Cancelar', onPressed: onCancel),
      ),
    );
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: onBack)),
      children: [
        Text(s.heading, style: BoraText.h1(c.tx)),
        const SizedBox(height: 2),
        Text(s.subtitle, style: BoraText.small(c.tx2)),
        if (!s.loaded) ...[
          if (s.loading)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator(color: c.pri)),
            )
          else ...[
            ?error,
            cancel,
          ],
        ] else ...[
          if (s.showFixedName) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.s2,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.repeat, size: 18, color: c.tx2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.title,
                      style: BoraText.nunito(
                        15,
                        20,
                        weight: FontWeight.w800,
                        color: c.tx,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (s.showName) ...[
            label('Nome', top: 20),
            BoraInput(
              value: s.title,
              onChanged: onTitle,
              hint: 'Ex.: Aula de Banco de Dados',
            ),
            label('Tipo', top: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in CommitmentCategory.values)
                  _IconChip(
                    label: k.label,
                    icon: commitmentCategoryIcon(k),
                    iconColor: c.pri,
                    selected: s.category == k,
                    onTap: () => onCategory(k),
                  ),
              ],
            ),
          ],
          if (s.showRepeat) ...[
            label('Repete?', top: 20),
            OptionCard(
              name: 'Toda semana',
              description: 'Aulas, estágio, treino',
              icon: PhosphorIconsRegular.repeat,
              selected: s.isWeekly,
              onTap: () => onRepeat(CommitmentRepeat.weekly),
            ),
            const SizedBox(height: 10),
            OptionCard(
              name: 'Só uma vez',
              description: 'Consulta, reunião, viagem',
              icon: PhosphorIconsRegular.calendarDot,
              selected: !s.isWeekly,
              onTap: () => onRepeat(CommitmentRepeat.once),
            ),
          ],
          if (s.isWeekly) ...[
            label('Dias da semana'),
            Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _DayButton(
                      letter: commitmentWeekdayLetters[i],
                      name: commitmentWeekdayNames[i],
                      selected: s.weekdays.contains(i),
                      onTap: () => onWeekday(i),
                    ),
                  ),
                ],
              ],
            ),
            label('Até quando?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _IconChip(
                  label: 'Sem fim',
                  selected: s.until == CommitmentUntil.none,
                  onTap: () => onUntil(CommitmentUntil.none),
                ),
                _IconChip(
                  label: 'Fim do semestre',
                  selected: s.until == CommitmentUntil.semester,
                  onTap: () => onUntil(CommitmentUntil.semester),
                ),
                _IconChip(
                  label: s.untilDateLabel,
                  icon: PhosphorIconsRegular.calendarBlank,
                  iconColor: c.blue,
                  selected: s.until == CommitmentUntil.date,
                  onTap: () => onUntil(CommitmentUntil.date),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.untilText, style: BoraText.caption(c.tx2)),
          ] else ...[
            label('Data'),
            _DateField(
              text: s.dateText,
              filled: s.date != null,
              onTap: onPickDate,
            ),
          ],
          label('Horário'),
          TimeRangeField(
            start: s.startMinute,
            end: s.endMinute,
            onStart: onStart,
            onEnd: onEnd,
          ),
          if (s.conflictTitle != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.blueSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIconsFill.arrowsClockwise,
                    size: 22,
                    color: c.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.conflictTitle!,
                          style: BoraText.nunito(
                            15,
                            20,
                            weight: FontWeight.w800,
                            color: c.tx,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sem estresse: quando você salvar, eu mudo essa etapa pra outro horário livre.',
                          style: BoraText.caption(c.tx2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          ?error,
          const SizedBox(height: 28),
          PrimaryButton(
            label: s.saveLabel,
            onPressed: s.canSave ? onSave : null,
          ),
          cancel,
          if (s.canDelete)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: TertiaryButton(
                  label: 'Excluir compromisso',
                  icon: PhosphorIconsBold.trash,
                  color: c.danger,
                  onPressed: s.busy ? null : onDelete,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Chip de 36 com ícone opcional (Tipo e "Escolher data").
class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

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
                Icon(icon, size: 16, color: iconColor),
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

/// Dia da semana (S T Q Q S S D), com o nome completo para acessibilidade.
class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.letter,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? c.pri : c.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? c.pri : c.border, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: BoraText.nunito(
              14,
              14,
              weight: FontWeight.w800,
              color: selected ? c.priTx : c.tx,
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo "Data" (abre o seletor de data existente).
class _DateField extends StatelessWidget {
  const _DateField({
    required this.text,
    required this.filled,
    required this.onTap,
  });

  final String text;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Semantics(
      button: true,
      label: 'Data, $text',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.calendarBlank, size: 20, color: c.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: BoraText.nunito(15, 20, color: filled ? c.tx : c.tx2),
                ),
              ),
              Icon(PhosphorIconsBold.caretDown, size: 16, color: c.tx2),
            ],
          ),
        ),
      ),
    );
  }
}
