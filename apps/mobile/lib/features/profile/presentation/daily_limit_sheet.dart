import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_widgets.dart';
import 'profile_sheet_frame.dart';

/// Abre o sheet "Máximo por dia" (AT5) e devolve as horas escolhidas, ou
/// `null` se o usuário fechar sem salvar.
Future<int?> showDailyLimitSheet(
  BuildContext context, {
  required int currentHours,
}) => showProfileSheet<int>(
  context,
  (sheetContext) => DailyLimitSheet(
    initialHours: currentHours,
    onSave: (hours) => Navigator.of(sheetContext).pop(hours),
  ),
);

/// Sheet "Máximo por dia" (AT5). **Sem design**: a moldura do sheet de
/// Idioma (M28) com o mesmo controle de 1h a 8h do "Limite diário" da
/// Redefinir rotina (M27).
class DailyLimitSheet extends StatefulWidget {
  const DailyLimitSheet({
    super.key,
    required this.initialHours,
    required this.onSave,
  });

  final int initialHours;
  final ValueChanged<int> onSave;

  @override
  State<DailyLimitSheet> createState() => _DailyLimitSheetState();
}

class _DailyLimitSheetState extends State<DailyLimitSheet> {
  late int _hours = widget.initialHours.clamp(1, 8);

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return ProfileSheetFrame(
      title: 'Máximo por dia',
      children: [
        Text(
          'Quanto tempo de etapas cabe num dia. O plano se reorganiza ao salvar.',
          style: BoraText.small(c.tx2),
        ),
        const SizedBox(height: 16),
        Text(
          '${_hours}h',
          textAlign: TextAlign.center,
          style: BoraText.fredoka(28, 32, color: c.pri),
        ),
        const SizedBox(height: 10),
        BoraSlider(
          value: _hours.toDouble(),
          min: 1,
          max: 8,
          step: 1,
          semanticLabel: 'Máximo por dia',
          onChanged: (v) => setState(() => _hours = v.round()),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Salvar', onPressed: () => widget.onSave(_hours)),
      ],
    );
  }
}
