import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/controller_host.dart';
import 'language_sheet.dart';
import 'profile_controller.dart';
import 'profile_screen.dart';

/// Perfil (M26): liga o [ProfileController] à navegação e ao sheet de idioma.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.deps});

  final AppDependencies deps;

  Future<void> _openRoutine(BuildContext context, ProfileController c) async {
    await context.push(AppRoutes.profileRoutine);
    // A rotina pode ter mudado o "Máximo por dia".
    if (context.mounted) await c.load();
  }

  Future<void> _openLanguage(BuildContext context, ProfileController c) async {
    final code = await showLanguageSheet(context, current: c.language);
    if (code != null) c.selectLanguage(code);
  }

  @override
  Widget build(BuildContext context) => ControllerHost<ProfileController>(
    create: () =>
        ProfileController(deps.auth, deps.scheduling, deps.session, deps.theme),
    init: (c) => c.load(),
    builder: (context, c) => ProfileScreen(
      state: c,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.garden),
      onToggleDark: c.toggleDark,
      onToggleBlockApps: c.toggleBlockApps,
      onRoutine: () => _openRoutine(context, c),
      onLanguage: () => _openLanguage(context, c),
      onSuggestion: () => context.push(AppRoutes.profileSuggestion),
    ),
  );
}
