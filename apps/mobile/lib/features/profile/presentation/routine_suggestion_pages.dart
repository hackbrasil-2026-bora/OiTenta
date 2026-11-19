import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/widgets/bora_scaffold.dart';

/// Redefinir minha rotina (M27). Esqueleto do passo 0.6; a tela real vem do S4.
class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Redefinir minha rotina', description: '');
}

/// Enviar sugestão (M29). Esqueleto do passo 0.6; a tela real vem do S4.
class SuggestionPage extends StatelessWidget {
  const SuggestionPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Enviar sugestão', description: '');
}
