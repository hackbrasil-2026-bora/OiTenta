import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/controller_host.dart';
import 'garden_controller.dart';
import 'garden_screen.dart';

/// Jardim (M04/M39): liga o [GardenController] à tela.
class GardenPage extends StatelessWidget {
  const GardenPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<GardenController>(
    create: () => GardenController(deps.gamification, deps.session),
    init: (c) => c.load(),
    builder: (context, c) => GardenScreen(
      state: c,
      onProfile: () => context.push(AppRoutes.profile),
      // No Jardim, o Broto do topo não faz nada (como no protótipo).
      onBroto: null,
    ),
  );
}
