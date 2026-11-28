import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/system/immersive_navigation_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final navigationBar = ImmersiveNavigationBar(
    isAndroid: defaultTargetPlatform == TargetPlatform.android,
  );
  navigationBar.start();
  // Ao voltar para o app, o Android mostra a barra de novo.
  AppLifecycleListener(onResume: navigationBar.hide);
  runApp(BoraApp(deps: AppDependencies.fromConfig()));
}
