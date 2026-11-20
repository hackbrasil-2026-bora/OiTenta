import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../domain/commitment.dart';

/// Como o formulário foi aberto (M46, M47, M52).
class CommitmentFormArgs {
  const CommitmentFormArgs({this.date, this.scope, this.occurrenceDate});

  /// Dia escolhido na Semana ("+ Compromisso" abre "Só uma vez" nesse dia).
  final String? date;

  /// Escopo da edição; `null` com [occurrenceDate] = "Só nesse dia".
  final CommitmentScope? scope;

  /// A ocorrência tocada (Editar "Só nesse dia" ou "Desse dia em diante").
  final String? occurrenceDate;
}

/// Novo/Editar compromisso. Esqueleto do passo 0.6; a tela real vem do M2.
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

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: commitmentId == null ? 'Novo compromisso' : 'Editar compromisso',
    description: '',
  );
}
