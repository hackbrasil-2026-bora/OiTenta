import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/bora_toast.dart';
import '../../../core/widgets/controller_host.dart';
import '../../goals/presentation/date_picker_sheet.dart';
import 'commitment_form_controller.dart';
import 'commitment_form_screen.dart';

export 'commitment_form_controller.dart' show CommitmentFormArgs;

/// Novo/Editar compromisso (M46, M47, M52): `/semana/compromisso` e
/// `/semana/compromisso/:id`, com o modo em [args].
class CommitmentFormPage extends StatelessWidget {
  const CommitmentFormPage({
    super.key,
    required this.deps,
    this.commitmentId,
    this.args = const CommitmentFormArgs(),
  });

  final AppDependencies deps;
  final String? commitmentId;
  final CommitmentFormArgs args;

  void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.week);

  void _finish(BuildContext context, CommitmentFormToast? t) {
    if (t == null) return;
    showBoraToast(
      context,
      icon: switch (t.kind) {
        CommitmentToastKind.saved => PhosphorIconsBold.calendarCheck,
        CommitmentToastKind.recalculated => PhosphorIconsBold.arrowsClockwise,
        CommitmentToastKind.deleted => PhosphorIconsBold.trash,
      },
      title: t.title,
      subtitle: t.subtitle,
      duration: Duration(
        milliseconds: t.kind == CommitmentToastKind.deleted ? 2400 : 2600,
      ),
    );
    _leave(context);
  }

  @override
  Widget build(BuildContext context) =>
      ControllerHost<CommitmentFormController>(
        create: () => CommitmentFormController(
          commitments: deps.commitments,
          scheduling: deps.scheduling,
          clock: deps.clock,
          commitmentId: commitmentId,
          args: args,
        ),
        init: (c) => c.load(),
        builder: (context, c) => CommitmentFormScreen(
          state: c,
          onBack: () => _leave(context),
          onCancel: () => _leave(context),
          onTitle: c.setTitle,
          onCategory: c.setCategory,
          onRepeat: c.setRepeat,
          onWeekday: c.toggleWeekday,
          onUntil: (u) async {
            c.chooseUntil(u);
            if (u != CommitmentUntil.date) return;
            final r = await showBoraDatePicker(
              context,
              today: deps.clock.now(),
              initial: c.untilDate,
              title: 'Repete até',
            );
            // "Sem prazo" (DatePick sem data) não muda nada.
            if (r?.date != null) c.setUntilDate(r!.date!);
          },
          onPickDate: () async {
            final r = await showBoraDatePicker(
              context,
              today: deps.clock.now(),
              initial: c.date,
              title: 'Data do compromisso',
            );
            if (r?.date != null) c.setDate(r!.date!);
          },
          onStart: c.setStart,
          onEnd: c.setEnd,
          onSave: () async {
            final t = await c.save();
            if (context.mounted) _finish(context, t);
          },
          onDelete: () async {
            final t = await c.delete();
            if (context.mounted) _finish(context, t);
          },
        ),
      );
}
