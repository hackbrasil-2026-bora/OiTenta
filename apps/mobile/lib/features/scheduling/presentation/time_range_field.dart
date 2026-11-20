import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';

/// `19:00` (24 h) a partir dos minutos desde 00:00.
String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// "Horário" do formulário de compromisso: início "até" fim, cada um abrindo
/// um seletor de hora de 5 em 5 minutos (MC2). Com o fim antes do início,
/// mostra "O fim precisa ser depois do início".
class TimeRangeField extends StatelessWidget {
  const TimeRangeField({
    super.key,
    required this.start,
    required this.end,
    required this.onStart,
    required this.onEnd,
  });

  final int start;
  final int end;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onEnd;

  Future<void> _pick(
    BuildContext context,
    String title,
    int value,
    ValueChanged<int> onPick,
  ) async {
    final v = await showTimePickerSheet(context, title: title, initial: value);
    if (v != null) onPick(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TimeBox(
                label: 'Início',
                minutes: start,
                onTap: () => _pick(context, 'Início', start, onStart),
              ),
            ),
            const SizedBox(width: 10),
            Text('até', style: BoraText.small(c.tx2)),
            const SizedBox(width: 10),
            Expanded(
              child: _TimeBox(
                label: 'Fim',
                minutes: end,
                onTap: () => _pick(context, 'Fim', end, onEnd),
              ),
            ),
          ],
        ),
        if (end <= start)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.info, size: 16, color: c.blue),
                const SizedBox(width: 6),
                Text(
                  'O fim precisa ser depois do início',
                  style: BoraText.caption(c.tx2),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final text = formatMinutes(minutes);
    return Semantics(
      button: true,
      label: '$label, $text',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: BoraText.fredoka(18, 18, color: c.tx)),
              ),
              Icon(PhosphorIconsRegular.clock, size: 20, color: c.tx),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet com o seletor de hora (24 h, de 5 em 5 min). Devolve os
/// minutos desde 00:00, ou `null` se o usuário fechar sem confirmar.
Future<int?> showTimePickerSheet(
  BuildContext context, {
  required String title,
  required int initial,
}) {
  final c = context.bora;
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: c.surface.withValues(alpha: 0),
    barrierColor: c.scrim,
    builder: (_) => _TimePickerSheet(title: title, initial: initial),
  );
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.title, required this.initial});

  final String title;
  final int initial;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom > 0 ? bottom : 34),
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
          Text(widget.title, style: BoraText.h3(c.tx)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: BoraText.fredoka(
                    20,
                    24,
                    color: c.tx,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                minuteInterval: 5,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  widget.initial ~/ 60,
                  widget.initial % 60,
                ),
                onDateTimeChanged: (d) => _value = d.hour * 60 + d.minute,
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Confirmar',
            height: 48,
            onPressed: () => Navigator.of(context).pop(_value),
          ),
        ],
      ),
    );
  }
}
