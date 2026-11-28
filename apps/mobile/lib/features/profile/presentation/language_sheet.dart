import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import 'profile_controller.dart';
import 'profile_sheet_frame.dart';

/// Abre o sheet "Idioma" (M28, `sheetIdioma` do protótipo) e devolve o
/// código escolhido, ou `null` se o usuário fechar sem escolher.
Future<String?> showLanguageSheet(
  BuildContext context, {
  required String current,
}) => showProfileSheet<String>(
  context,
  (sheetContext) => LanguageSheet(
    current: current,
    onSelect: (code) => Navigator.of(sheetContext).pop(code),
  ),
);

/// Sheet "Idioma": as 3 opções, com check na atual (MP8: só muda o texto da
/// linha do Perfil; o app continua em português).
class LanguageSheet extends StatelessWidget {
  const LanguageSheet({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => ProfileSheetFrame(
    title: 'Idioma',
    children: [
      for (final (i, l) in ProfileController.languages.indexed) ...[
        if (i > 0) const SizedBox(height: 8),
        LanguageOption(
          name: l.name,
          selected: l.code == current,
          onTap: () => onSelect(l.code),
        ),
      ],
    ],
  );
}

/// Opção do sheet: 52 de altura mínima, borda 2px, raio 16; selecionada em
/// `--priSoft` com borda `--pri` e o check.
class LanguageOption extends StatelessWidget {
  const LanguageOption({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(16, 0, 14, 0),
          decoration: BoxDecoration(
            color: selected ? c.priSoft : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? c.pri : c.border, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: BoraText.nunito(
                    15,
                    20,
                    weight: FontWeight.w800,
                    color: c.tx,
                  ),
                ),
              ),
              if (selected)
                Icon(PhosphorIconsFill.checkCircle, size: 22, color: c.pri),
            ],
          ),
        ),
      ),
    );
  }
}
