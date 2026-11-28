import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import 'profile_sheet_frame.dart';

/// Pergunta antes de sair da conta (AT9) e devolve `true` se confirmar.
Future<bool> showLogoutSheet(BuildContext context) async =>
    await showProfileSheet<bool>(
      context,
      (sheetContext) => LogoutSheet(
        onConfirm: () => Navigator.of(sheetContext).pop(true),
        onCancel: () => Navigator.of(sheetContext).pop(false),
      ),
    ) ??
    false;

/// Sheet "Sair da conta?" (AT9, sem design): a moldura do sheet de Idioma.
class LogoutSheet extends StatelessWidget {
  const LogoutSheet({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return ProfileSheetFrame(
      title: 'Sair da conta?',
      children: [
        Text(
          'Seus dados ficam salvos. É só entrar de novo com o seu e-mail.',
          style: BoraText.small(c.tx2),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Sair', onPressed: onConfirm),
        const SizedBox(height: 8),
        Center(
          child: TertiaryButton(label: 'Cancelar', onPressed: onCancel),
        ),
      ],
    );
  }
}
