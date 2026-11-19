import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/bora_toast.dart';
import '../../../core/widgets/controller_host.dart';
import 'routine_controller.dart';
import 'routine_screen.dart';
import 'suggestion_controller.dart';
import 'suggestion_screen.dart';

/// Volta para quem abriu a tela (o Perfil) ou, sem histórico, vai ao Perfil.
void _leave(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(AppRoutes.profile);

/// Redefinir minha rotina (M27): `GET`/`PUT /scheduling/availability`.
class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<RoutineController>(
    create: () => RoutineController(deps.scheduling),
    init: (c) => c.load(),
    builder: (context, c) => RoutineScreen(
      state: c,
      onBack: () => _leave(context),
      onToggle: c.toggle,
      onLimit: c.setLimitHours,
      onSave: () async {
        if (!await c.save() || !context.mounted) return;
        showBoraToast(
          context,
          icon: PhosphorIconsBold.arrowsClockwise,
          title: 'Plano recalculado',
          subtitle: 'Sua rotina nova vale a partir de amanhã',
        );
        _leave(context);
      },
    ),
  );
}

/// Enviar sugestão (M29). Só visual (MP9): `deps.feedback` é o exemplo.
class SuggestionPage extends StatelessWidget {
  const SuggestionPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<SuggestionController>(
    create: () => SuggestionController(deps.feedback),
    builder: (context, c) => SuggestionScreen(
      state: c,
      onBack: () => _leave(context),
      onText: c.setText,
      onSend: () async {
        if (!await c.send() || !context.mounted) return;
        showBoraToast(
          context,
          icon: PhosphorIconsBold.paperPlaneTilt,
          title: 'Sugestão enviada',
          subtitle: 'Valeu! A gente lê tudo.',
        );
        _leave(context);
      },
    ),
  );
}
