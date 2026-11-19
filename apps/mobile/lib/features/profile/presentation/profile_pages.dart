import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/widgets/bora_scaffold.dart';

/// Perfil (M26). Esqueleto do passo 0.6; a tela real vem do S3.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Perfil', description: '');
}
