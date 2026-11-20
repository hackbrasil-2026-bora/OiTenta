import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/widgets/bora_scaffold.dart';

/// Tarefas únicas (M53–M54). Esqueleto do passo 0.6; a tela real vem do M3.
class SingleTasksPage extends StatelessWidget {
  const SingleTasksPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Tarefas únicas', description: '');
}
