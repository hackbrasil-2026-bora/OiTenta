import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../../core/widgets/bora_toast.dart';
import '../../../core/widgets/controller_host.dart';
import 'login_controller.dart';
import 'login_screen.dart';
import 'register_controller.dart';
import 'register_screen.dart';

/// Duração do toast de entrada (`entrar` do protótipo: 2600 ms).
const _welcomeToast = Duration(milliseconds: 2600);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<LoginController>(
    create: () => LoginController(deps.auth, deps.scheduling, deps.session),
    builder: (context, c) {
      void go(AfterLogin next) => context.go(
        next == AfterLogin.today ? AppRoutes.today : AppRoutes.onboarding,
      );
      return LoginScreen(
        state: c,
        showDemo: deps.showDemo,
        onEmail: c.setEmail,
        onPassword: c.setPassword,
        onToggleObscure: c.toggleObscure,
        onSubmit: () async {
          final next = await c.submit();
          if (!context.mounted || next == null) return;
          showBoraToast(
            context,
            icon: PhosphorIconsBold.handWaving,
            title: 'Oi de novo, ${c.firstName}!',
            subtitle: 'Seu plano tá do jeitinho que você deixou.',
            duration: _welcomeToast,
          );
          go(next);
        },
        onForgot: () => context.push(AppRoutes.forgotPassword),
        onRegister: () => context.push(AppRoutes.register),
        onDemo: () async {
          final next = await c.enterDemo();
          if (!context.mounted || next == null) return;
          go(next);
        },
      );
    },
  );
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<RegisterController>(
    create: () => RegisterController(deps.auth, deps.session),
    builder: (context, c) {
      void toLogin() =>
          context.canPop() ? context.pop() : context.go(AppRoutes.login);
      return RegisterScreen(
        state: c,
        onName: c.setName,
        onEmail: c.setEmail,
        onPassword: c.setPassword,
        onConfirm: c.setConfirm,
        onToggleObscure: c.toggleObscure,
        onToggleTerms: c.toggleTerms,
        onBack: toLogin,
        onLogin: toLogin,
        onTerms: () => context.push(AppRoutes.terms),
        onPrivacy: () => context.push(AppRoutes.privacy),
        onSubmit: () async {
          final ok = await c.submit();
          if (!context.mounted || !ok) return;
          // Depois de criar a conta, sempre o onboarding (decisão 4b).
          showBoraToast(
            context,
            icon: PhosphorIconsBold.handWaving,
            title: 'Conta criada!',
            subtitle: 'Bem-vindo ao Bora, ${c.firstName}.',
            duration: _welcomeToast,
          );
          context.go(AppRoutes.onboarding);
        },
      );
    },
  );
}

/// Esqueci minha senha: placeholder (MP4, regra 4i) até existir backend de
/// recuperação; as telas M36–M38 entram depois.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: 'Esqueci minha senha',
    description: 'A recuperação de senha ainda não está disponível.',
    actionLabel: 'Voltar pro login',
    onAction: () =>
        context.canPop() ? context.pop() : context.go(AppRoutes.login),
  );
}
