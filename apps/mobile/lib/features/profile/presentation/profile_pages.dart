import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/bora_toast.dart';
import '../../../core/widgets/controller_host.dart';
import 'daily_limit_sheet.dart';
import 'edit_profile_controller.dart';
import 'edit_profile_screen.dart';
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

  Future<void> _openEdit(BuildContext context, ProfileController c) async {
    await context.push(AppRoutes.profileEdit);
    // A edição atualiza a sessão; o Perfil relê o nome e o e-mail.
    c.refreshUser();
  }

  Future<void> _openDailyLimit(
    BuildContext context,
    ProfileController c,
  ) async {
    final hours = await showDailyLimitSheet(
      context,
      currentHours: c.dailyLimitHours,
    );
    if (hours == null || !await c.saveDailyLimit(hours) || !context.mounted) {
      return;
    }
    showBoraToast(
      context,
      icon: PhosphorIconsBold.arrowsClockwise,
      title: 'Máximo por dia: ${hours}h',
      subtitle: 'Seu plano foi reorganizado.',
    );
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
      onEditProfile: () => _openEdit(context, c),
      onToggleDailyEmail: c.toggleDailyEmail,
      onDailyLimit: () => _openDailyLimit(context, c),
    ),
  );
}

/// Editar perfil (AT3): liga o [EditProfileController] à navegação.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key, required this.deps});

  final AppDependencies deps;

  void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.profile);

  @override
  Widget build(BuildContext context) => ControllerHost<EditProfileController>(
    create: () => EditProfileController(deps.auth, deps.session),
    builder: (context, c) => EditProfileScreen(
      state: c,
      onBack: () => _leave(context),
      onName: c.setName,
      onEmail: c.setEmail,
      onCurrentPassword: c.setCurrentPassword,
      onSave: () async {
        if (!await c.save() || !context.mounted) return;
        showBoraToast(
          context,
          icon: PhosphorIconsBold.checkCircle,
          title: 'Perfil atualizado',
          subtitle: 'Seu nome e seu e-mail estão salvos.',
        );
        _leave(context);
      },
    ),
  );
}
