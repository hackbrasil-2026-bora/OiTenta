import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_input.dart';
import '../../../core/widgets/bora_scaffold.dart';
import 'auth_fields.dart';
import 'register_controller.dart';

/// Criar conta (M34–M35, `<!-- CRIAR CONTA -->` do `Bora App.dc.html`).
/// A dica da senha segue a regra do backend (MP1).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    super.key,
    required this.state,
    required this.onName,
    required this.onEmail,
    required this.onPassword,
    required this.onConfirm,
    required this.onToggleObscure,
    required this.onToggleTerms,
    required this.onSubmit,
    required this.onBack,
    required this.onLogin,
    required this.onTerms,
    required this.onPrivacy,
  });

  static const passwordHint =
      'Mínimo de 8 caracteres, com maiúscula, minúscula, número e símbolo';

  final RegisterController state;
  final ValueChanged<String> onName;
  final ValueChanged<String> onEmail;
  final ValueChanged<String> onPassword;
  final ValueChanged<String> onConfirm;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleTerms;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onLogin;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final canSubmit = state.canSubmit && !state.busy;
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: onBack)),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text('Criar sua conta', style: BoraText.h1(c.tx)),
        const SizedBox(height: 2),
        Text(
          'Leva menos de 1 minuto. Depois eu te ajudo a montar o plano.',
          style: BoraText.small(c.tx2),
        ),
        const AuthFieldLabel('Como quer ser chamado?'),
        BoraInput(
          key: const Key('register-name'),
          value: state.name,
          onChanged: onName,
          hint: 'Ex.: Arthur',
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
        ),
        const AuthFieldLabel('E-mail'),
        BoraInput(
          key: const Key('register-email'),
          value: state.email,
          onChanged: onEmail,
          hint: 'seu@email.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const AuthFieldLabel('Senha'),
        PasswordField(
          key: const Key('register-password'),
          value: state.password,
          onChanged: onPassword,
          hint: 'Crie uma senha',
          obscure: state.obscure,
          onToggleObscure: onToggleObscure,
          textInputAction: TextInputAction.next,
        ),
        AuthHint(
          iconKey: const Key('register-password-hint-icon'),
          icon: state.passwordOk
              ? PhosphorIconsFill.checkCircle
              : PhosphorIconsRegular.circle,
          color: state.passwordOk ? c.pri : c.tx2,
          text: passwordHint,
        ),
        const AuthFieldLabel('Confirme sua senha'),
        PasswordField(
          key: const Key('register-confirm'),
          value: state.confirm,
          onChanged: onConfirm,
          hint: 'Digite a senha de novo',
          obscure: state.obscure,
          onToggleObscure: onToggleObscure,
          textInputAction: TextInputAction.done,
        ),
        if (state.confirmVisible)
          AuthHint(
            iconKey: const Key('register-confirm-hint-icon'),
            icon: state.confirmOk
                ? PhosphorIconsFill.checkCircle
                : PhosphorIconsRegular.info,
            color: state.confirmOk ? c.pri : c.blue,
            text: state.confirmText,
          ),
        const SizedBox(height: 20),
        _TermsCheck(
          checked: state.termsAccepted,
          onToggle: onToggleTerms,
          onTerms: onTerms,
          onPrivacy: onPrivacy,
        ),
        if (state.error != null) AuthError(state.error!),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Criar conta',
          onPressed: canSubmit ? onSubmit : null,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Já tem conta?', style: BoraText.small(c.tx2)),
            TertiaryButton(label: 'Entrar', onPressed: onLogin),
          ],
        ),
      ],
    );
  }
}

/// Caixa dos termos (24×24, raio 8, borda 2px): marcada fica `--pri` com o
/// check `--priTx`. O toque na linha alterna; os links abrem os Termos de uso
/// e a Política de privacidade (28/11/2026) sem alternar.
class _TermsCheck extends StatefulWidget {
  const _TermsCheck({
    required this.checked,
    required this.onToggle,
    required this.onTerms,
    required this.onPrivacy,
  });

  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  State<_TermsCheck> createState() => _TermsCheckState();
}

class _TermsCheckState extends State<_TermsCheck> {
  late final _terms = TapGestureRecognizer()..onTap = () => widget.onTerms();
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => widget.onPrivacy();

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checked = widget.checked;
    final onToggle = widget.onToggle;
    final c = context.bora;
    final link = BoraText.nunito(
      14,
      20,
      weight: FontWeight.w800,
      color: c.blue,
    );
    return Semantics(
      checked: checked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(0, -2),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? c.pri : c.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: checked ? c.pri : c.border,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: checked
                    ? Icon(PhosphorIconsBold.check, size: 14, color: c.priTx)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: BoraText.small(c.tx),
                  children: [
                    const TextSpan(text: 'Li e aceito os '),
                    TextSpan(
                      text: 'Termos de uso',
                      style: link,
                      recognizer: _terms,
                    ),
                    const TextSpan(text: ' e a '),
                    TextSpan(
                      text: 'Política de privacidade',
                      style: link,
                      recognizer: _privacy,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
