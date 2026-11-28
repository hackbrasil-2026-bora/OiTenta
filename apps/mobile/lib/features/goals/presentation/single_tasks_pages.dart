import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/bora_toast.dart';
import '../../../core/widgets/controller_host.dart';
import 'date_picker_sheet.dart';
import 'single_tasks_controller.dart';
import 'single_tasks_screen.dart';

/// Tarefas únicas (M53–M54).
class SingleTasksPage extends StatelessWidget {
  const SingleTasksPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => ControllerHost<SingleTasksController>(
    create: () => SingleTasksController(deps.singleTasks, deps.clock),
    init: (c) => c.load(),
    builder: (context, c) {
      void toast(IconData icon, SingleTaskToast? t) {
        if (t == null || !context.mounted) return;
        showBoraToast(
          context,
          icon: icon,
          title: t.title,
          subtitle: t.subtitle,
        );
      }

      return SingleTasksScreen(
        state: c,
        // No protótipo nada leva a esta tela; o "voltar" vai ao Hoje.
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.today),
        onText: c.setText,
        onDuration: c.setMinutes,
        onWhen: c.setWhen,
        onPickDay: () async {
          c.setWhen(SingleTaskWhen.day);
          final r = await showBoraDatePicker(
            context,
            today: deps.clock.now(),
            initial: c.day,
            title: 'Quando fazer',
          );
          // "Sem prazo" (sem data) e fechar o sheet não mudam o dia.
          final d = r?.date;
          if (d != null) c.setDay(d);
        },
        onAdd: () async =>
            toast(PhosphorIconsBold.calendarCheck, await c.add()),
        onToggle: (id) async =>
            toast(PhosphorIconsBold.check, await c.toggle(id)),
        onDelete: c.remove,
      );
    },
  );
}
