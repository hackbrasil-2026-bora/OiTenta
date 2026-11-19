import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import 'garden_screen.dart';

/// Jardim (M04/M39). Esqueleto do passo 0.6; a tela real vem do S5.
class GardenPage extends StatelessWidget {
  const GardenPage({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) => const GardenScreen();
}
