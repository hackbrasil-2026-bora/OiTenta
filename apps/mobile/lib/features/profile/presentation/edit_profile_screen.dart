import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_input.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../auth/presentation/auth_fields.dart';
import 'edit_profile_controller.dart';

/// Editar perfil (AT3). **Sem design**: segue o visual de "Enviar sugestão"
/// (M29): título, rótulos em caixa alta, `BoraInput` e o botão primário.
/// A senha atual só aparece quando o e-mail muda.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onName,
    required this.onEmail,
    required this.onCurrentPassword,
    required this.onSave,
  });

  final EditProfileController state;
  final VoidCallback onBack;
  final ValueChanged<String> onName;
  final ValueChanged<String> onEmail;
  final ValueChanged<String> onCurrentPassword;
  final VoidCallback onSave;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final s = widget.state;
    Widget label(String text) =>
        Text(text.toUpperCase(), style: BoraText.label(c.tx2));
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: widget.onBack)),
      children: [
        Text('Editar perfil', style: BoraText.h1(c.tx)),
        const SizedBox(height: 2),
        Text(
          'Sua conta continua a mesma: dá pra trocar o nome e o e-mail quando quiser.',
          style: BoraText.small(c.tx2),
        ),
        const SizedBox(height: 20),
        label('Nome'),
        const SizedBox(height: 8),
        BoraInput(
          value: s.name,
          onChanged: widget.onName,
          hint: 'Como quer ser chamado?',
          semanticLabel: 'Nome',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        label('E-mail'),
        const SizedBox(height: 8),
        BoraInput(
          value: s.email,
          onChanged: widget.onEmail,
          hint: 'seu@email.com',
          semanticLabel: 'E-mail',
          keyboardType: TextInputType.emailAddress,
        ),
        if (s.emailChanged) ...[
          const SizedBox(height: 16),
          label('Senha atual'),
          const SizedBox(height: 8),
          PasswordField(
            value: s.currentPassword,
            onChanged: widget.onCurrentPassword,
            hint: 'Sua senha de agora',
            obscure: _obscure,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 6),
          Text(
            'Pra trocar o e-mail, confirme sua senha atual.',
            style: BoraText.small(c.tx2),
          ),
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
          label: 'Salvar',
          onPressed: s.canSave ? widget.onSave : null,
        ),
      ],
    );
  }
}
