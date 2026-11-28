import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/bora_toast.dart';
import '../../../core/widgets/controller_host.dart';
import 'change_password_controller.dart';
import 'change_password_screen.dart';
import 'daily_limit_sheet.dart';
import 'delete_account_controller.dart';
import 'delete_account_screen.dart';
import 'edit_profile_controller.dart';
import 'edit_profile_screen.dart';
import 'language_sheet.dart';
import 'logout_sheet.dart';
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

  Future<void> _openReminder(BuildContext context, ProfileController c) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: c.reminderHour, minute: c.reminderMinute),
      helpText: 'Lembrete da rampa',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) c.setReminder(picked.hour, picked.minute);
  }

  Future<void> _logout(BuildContext context, ProfileController c) async {
    if (!await showLogoutSheet(context) || !context.mounted) return;
    c.logout();
    context.go(AppRoutes.login);
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
      onReminder: () => _openReminder(context, c),
      onChangePassword: () => context.push(AppRoutes.profilePassword),
      onLogout: () => _logout(context, c),
      onDeleteAccount: () => context.push(AppRoutes.profileDelete),
      onTerms: () => context.push(AppRoutes.terms),
      onPrivacy: () => context.push(AppRoutes.privacy),
    ),
  );
}

/// Trocar senha (AT9).
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key, required this.deps});

  final AppDependencies deps;

  void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.profile);

  @override
  Widget build(BuildContext context) =>
      ControllerHost<ChangePasswordController>(
        create: () => ChangePasswordController(deps.auth),
        builder: (context, c) => ChangePasswordScreen(
          state: c,
          onBack: () => _leave(context),
          onCurrent: c.setCurrent,
          onNew: c.setNew,
          onConfirm: c.setConfirm,
          onSave: () async {
            if (!await c.save() || !context.mounted) return;
            showBoraToast(
              context,
              icon: PhosphorIconsBold.checkCircle,
              title: 'Senha trocada',
              subtitle: 'Use a senha nova da próxima vez que entrar.',
            );
            _leave(context);
          },
        ),
      );
}

/// Apagar conta (AT9): depois de apagar, volta ao login.
class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<DeleteAccountController>(
    create: () => DeleteAccountController(deps.auth, deps.session),
    builder: (context, c) => DeleteAccountScreen(
      state: c,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.profile),
      onPassword: c.setPassword,
      onDelete: () async {
        if (!await c.delete() || !context.mounted) return;
        context.go(AppRoutes.login);
        showBoraToast(
          context,
          icon: PhosphorIconsBold.trash,
          title: 'Conta apagada',
          subtitle: 'Seus dados foram apagados. Até a próxima!',
        );
      },
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
