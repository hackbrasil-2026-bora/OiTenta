import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_input.dart';
import '../../../core/widgets/broto.dart';
import 'auth_fields.dart';
import 'login_controller.dart';

/// Entrar (M33, `<!-- LOGIN -->` do `Bora App.dc.html`). Sem "Entrar com
/// Google" e o divisor "ou" (MP3); o botão de demo só com [showDemo] (MP5).
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.state,
    required this.showDemo,
    required this.onEmail,
    required this.onPassword,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onForgot,
    required this.onRegister,
    required this.onDemo,
  });

  final LoginController state;
  final bool showDemo;
  final ValueChanged<String> onEmail;
  final ValueChanged<String> onPassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;
  final VoidCallback onRegister;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final canSubmit = state.canSubmit && !state.busy;
    return Material(
      color: c.bg,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Center(
                      child: Broto(mood: BrotoMood.animado, size: 112),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Que bom te ver!',
                      textAlign: TextAlign.center,
                      style: BoraText.h1(c.tx),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Entra aí pra continuar de onde parou.',
                      textAlign: TextAlign.center,
                      style: BoraText.nunito(
                        16,
                        24,
                        weight: FontWeight.w400,
                        color: c.tx2,
                      ),
                    ),
                    const AuthFieldLabel('E-mail', top: 24),
                    BoraInput(
                      key: const Key('login-email'),
                      value: state.email,
                      onChanged: onEmail,
                      hint: 'seu@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const AuthFieldLabel('Senha'),
                    PasswordField(
                      key: const Key('login-password'),
                      value: state.password,
                      onChanged: onPassword,
                      hint: 'Sua senha',
                      obscure: state.obscure,
                      onToggleObscure: onToggleObscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (canSubmit) onSubmit();
                      },
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Transform.translate(
                        // `margin-right: -14px`: o texto alinha com o campo.
                        offset: const Offset(14, 0),
                        child: TertiaryButton(
                          label: 'Esqueci minha senha',
                          onPressed: onForgot,
                        ),
                      ),
                    ),
                    if (state.error != null) AuthError(state.error!),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Entrar',
                      onPressed: canSubmit ? onSubmit : null,
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ainda não tem conta?',
                          style: BoraText.small(c.tx2),
                        ),
                        TertiaryButton(
                          label: 'Criar conta',
                          onPressed: onRegister,
                        ),
                      ],
                    ),
                    if (showDemo)
                      Center(
                        child: TertiaryButton(
                          label: 'Entrar direto como Arthur (demo)',
                          onPressed: state.busy ? null : onDemo,
                        ),
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
