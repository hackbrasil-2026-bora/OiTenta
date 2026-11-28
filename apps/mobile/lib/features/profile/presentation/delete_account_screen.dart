import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../auth/presentation/auth_fields.dart';
import 'delete_account_controller.dart';

/// Apagar conta (AT9). **Sem design**: diz o que some, pede a senha e usa um
/// botão no `--danger` (o app não tem botão de perigo no design system).
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onPassword,
    required this.onDelete,
  });

  final DeleteAccountController state;
  final VoidCallback onBack;
  final ValueChanged<String> onPassword;
  final VoidCallback onDelete;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final s = widget.state;
    final enabled = s.canDelete;
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: widget.onBack)),
      children: [
        Text('Apagar conta', style: BoraText.h1(c.tx)),
        const SizedBox(height: 8),
        Text(
          'Isso apaga de verdade a sua conta e tudo o que está nela: '
          'objetivos, etapas, plano, sessões de foco, rotina e compromissos. '
          'Não dá pra desfazer.',
          style: BoraText.nunito(16, 24, weight: FontWeight.w400, color: c.tx),
        ),
        const SizedBox(height: 20),
        Text('Senha atual'.toUpperCase(), style: BoraText.label(c.tx2)),
        const SizedBox(height: 8),
        PasswordField(
          value: s.password,
          onChanged: widget.onPassword,
          hint: 'Confirme com a sua senha',
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
        ),
        if (s.error != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(s.error!, style: BoraText.small(c.danger)),
          ),
        ],
        const SizedBox(height: 24),
        Semantics(
          button: true,
          enabled: enabled,
          label: 'Apagar minha conta',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? widget.onDelete : null,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled ? c.danger : c.danger.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Apagar minha conta',
                style: BoraText.nunito(
                  16,
                  16,
                  weight: FontWeight.w800,
                  color: c.priTx,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
