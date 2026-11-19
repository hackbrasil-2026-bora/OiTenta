import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import 'profile_controller.dart';

/// Abre o sheet "Idioma" (M28, `sheetIdioma` do protótipo) e devolve o
/// código escolhido, ou `null` se o usuário fechar sem escolher.
Future<String?> showLanguageSheet(
  BuildContext context, {
  required String current,
}) {
  final c = context.bora;
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: c.surface.withValues(alpha: 0),
    barrierColor: c.scrim,
    builder: (sheetContext) => LanguageSheet(
      current: current,
      onSelect: (code) => Navigator.of(sheetContext).pop(code),
    ),
  );
}

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
  Widget build(BuildContext context) {
    final c = context.bora;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: c.border),
          left: BorderSide(color: c.border),
          right: BorderSide(color: c.border),
        ),
        boxShadow: [
          BoxShadow(
            color: c.sheetShadow,
            offset: const Offset(0, -8),
            blurRadius: 32,
          ),
        ],
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
          Text('Idioma', style: BoraText.h3(c.tx)),
          const SizedBox(height: 12),
          for (final (i, l) in ProfileController.languages.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            LanguageOption(
              name: l.name,
              selected: l.code == current,
              onTap: () => onSelect(l.code),
            ),
          ],
        ],
      ),
    );
  }
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
