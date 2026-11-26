import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/bora_colors.dart';
import '../../../core/widgets/bora_toast.dart';
import '../../../core/widgets/controller_host.dart';
import '../../activation/presentation/checkin_controller.dart';
import '../../activation/presentation/checkin_sheet.dart';
import '../../activation/presentation/ramp_session.dart';
import 'commitment_form_pages.dart';
import 'commitment_occurrence_controller.dart';
import 'commitment_occurrence_sheet.dart';
import 'commitment_occurrence_view.dart';
import 'onboarding_controller.dart';
import 'onboarding_screen.dart';
import 'today_controller.dart';
import 'today_screen.dart';
import 'week_controller.dart';
import 'week_screen.dart';

/// Abre o sheet da ocorrência (Semana e Hoje). Depois de uma ação mostra o
/// toast e chama [reload]; no Editar abre o formulário e recarrega ao voltar.
/// Se o sheet for fechado (arrastar ou tocar fora) com uma ação em andamento,
/// espera a ação terminar e recarrega do mesmo jeito.
Future<void> openCommitmentOccurrence(
  BuildContext context,
  AppDependencies deps,
  CommitmentOccurrenceView view,
  Future<void> Function() reload,
) async {
  final c = context.bora;
  Future<OccurrenceOutcome?>? pending;
  final outcome = await showModalBottomSheet<OccurrenceOutcome>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: c.surface.withValues(alpha: 0),
    barrierColor: c.scrim,
    builder: (sheetContext) => ControllerHost<CommitmentOccurrenceController>(
      create: () =>
          CommitmentOccurrenceController(deps.commitments, view.occurrence),
      init: (oc) => oc.load(),
      builder: (_, oc) {
        Future<void> close(Future<OccurrenceOutcome?> run) async {
          pending = run;
          final result = await run;
          if (result != null && sheetContext.mounted) {
            Navigator.of(sheetContext).pop(result);
          }
        }

        return CommitmentOccurrenceSheet(
          state: oc,
          onAction: (k) => close(oc.pick(k)),
          onKeep: () => close(oc.keep()),
          onScope: oc.selectScope,
          onConfirm: () => close(oc.confirm()),
          onBack: oc.back,
        );
      },
    ),
  );
  if (outcome == null) {
    // Fechado sem resultado: se havia uma chamada, o backend pode tê-la
    // aplicado; recarrega depois que ela terminar.
    if (pending == null) return;
    await pending;
    if (context.mounted) await reload();
    return;
  }
  if (!context.mounted) return;
  final edit = outcome.edit;
  if (edit != null) {
    await context.push(
      AppRoutes.commitmentEdit(edit.commitmentId),
      extra: CommitmentFormArgs(
        scope: edit.scope,
        occurrenceDate: edit.occurrenceDate,
      ),
    );
  } else {
    final t = outcome.toast!;
    showBoraToast(
      context,
      icon: occurrenceToastIcon(t.kind),
      title: t.title,
      subtitle: t.subtitle,
    );
  }
  await reload();
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<OnboardingController>(
    create: () => OnboardingController(deps.scheduling, deps.session),
    builder: (context, c) => OnboardingScreen(
      state: c,
      onBack: () => c.step == 1 ? context.go(AppRoutes.login) : c.back(),
      onNext: c.next,
      onStuck: c.chooseStuck,
      onTogglePeriod: c.togglePeriod,
      onLimit: c.setLimit,
      onSave: c.save,
      onFinish: () => context.go(AppRoutes.today),
    ),
  );
}

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.deps});

  final AppDependencies deps;

  Future<void> _openCheckin(BuildContext context, TodayController today) async {
    final b = today.nextBlock;
    if (b == null) return;
    final target = RampTarget(
      goalId: b.goalId,
      stepId: b.stepId,
      blockId: b.id,
      goalTitle: b.goalTitle,
      stepTitle: b.stepTitle,
      colorIndex: b.colorIndex,
    );
    final c = context.bora;
    final built = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: c.surface.withValues(alpha: 0),
      barrierColor: c.scrim,
      builder: (sheetContext) => ControllerHost<CheckinController>(
        create: () => CheckinController(
          deps.activation,
          deps.rampSession,
          deps.clock,
          target,
        ),
        builder: (_, ci) => CheckinSheet(
          state: ci,
          onEnergy: ci.chooseEnergy,
          onTime: ci.chooseTime,
          onLightTasks: null,
          onBuild: () async {
            if (await ci.build() && sheetContext.mounted) {
              Navigator.of(sheetContext).pop(true);
            }
          },
        ),
      ),
    );
    if (built == true && context.mounted) context.go(AppRoutes.ramp);
  }

  @override
  Widget build(BuildContext context) => ControllerHost<TodayController>(
    create: () => TodayController(
      deps.scheduling,
      deps.goals,
      deps.gamification,
      deps.session,
      deps.clock,
      commitments: deps.commitments,
    ),
    init: (c) => c.load(),
    builder: (context, c) => TodayScreen(
      state: c,
      onStart: () => _openCheckin(context, c),
      onToggleLight: c.toggleLightTask,
      onProfile: () => context.push(AppRoutes.profile),
      onBroto: () => context.go(AppRoutes.garden),
      onSingleTasks: () async {
        await context.push(AppRoutes.singleTasks);
        await c.load();
      },
      onOpenCommitment: (o) =>
          openCommitmentOccurrence(context, deps, o, c.load),
    ),
  );
}

class WeekPage extends StatelessWidget {
  const WeekPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<WeekController>(
    create: () => WeekController(
      deps.scheduling,
      deps.clock,
      goals: deps.goals,
      commitments: deps.commitments,
    ),
    init: (c) => c.load(),
    builder: (context, c) => WeekScreen(
      state: c,
      onSelectDay: c.selectDay,
      onSelectDate: c.selectDate,
      onExpand: c.expand,
      onCollapse: c.collapse,
      onToggleExpanded: c.toggleExpanded,
      onShowMonth: c.showMonth,
      onMode: c.setMode,
      onAddCommitment: () async {
        await context.push(
          AppRoutes.commitmentNew,
          extra: CommitmentFormArgs(date: c.selectedDateKey),
        );
        await c.reload();
      },
      onOpenCommitment: (o) =>
          openCommitmentOccurrence(context, deps, o, c.reload),
    ),
  );
}
