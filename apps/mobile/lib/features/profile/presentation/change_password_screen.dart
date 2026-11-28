import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../auth/presentation/auth_fields.dart';
import 'change_password_controller.dart';

/// Trocar senha (AT9). **Sem design**: o visual de "Editar perfil" (que
/// segue o de "Enviar sugestão", M29), com os campos de senha do Acesso.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onCurrent,
    required this.onNew,
    required this.onConfirm,
    required this.onSave,
  });

  final ChangePasswordController state;
  final VoidCallback onBack;
  final ValueChanged<String> onCurrent;
  final ValueChanged<String> onNew;
  final ValueChanged<String> onConfirm;
  final VoidCallback onSave;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final s = widget.state;
    Widget label(String text) =>
        Text(text.toUpperCase(), style: BoraText.label(c.tx2));
    Widget field(String value, ValueChanged<String> onChanged, String hint) =>
        PasswordField(
          value: value,
          onChanged: onChanged,
          hint: hint,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
        );
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: widget.onBack)),
      children: [
        Text('Trocar senha', style: BoraText.h1(c.tx)),
        const SizedBox(height: 20),
        label('Senha atual'),
        const SizedBox(height: 8),
        field(s.current, widget.onCurrent, 'Sua senha de agora'),
        const SizedBox(height: 16),
        label('Senha nova'),
        const SizedBox(height: 8),
        field(s.newPassword, widget.onNew, 'Crie uma senha'),
        const SizedBox(height: 6),
        Text(
          '8 caracteres ou mais, com maiúscula, minúscula, número e símbolo.',
          style: BoraText.small(s.newIsStrong ? c.pri : c.tx2),
        ),
        const SizedBox(height: 16),
        label('Confirme a senha nova'),
        const SizedBox(height: 8),
        field(s.confirm, widget.onConfirm, 'Repita a senha nova'),
        if (s.confirmMismatch) ...[
          const SizedBox(height: 6),
          Text('As senhas não batem.', style: BoraText.small(c.danger)),
        ],
        if (s.error != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(s.error!, style: BoraText.small(c.danger)),
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Salvar senha',
          onPressed: s.canSave ? widget.onSave : null,
        ),
      ],
    );
  }
}
