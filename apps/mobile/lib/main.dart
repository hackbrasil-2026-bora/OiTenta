import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/system/immersive_navigation_bar.dart';
import 'core/system/system_navigation_bar_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final isAndroid = defaultTargetPlatform == TargetPlatform.android;
  final navigationBar = ImmersiveNavigationBar(isAndroid: isAndroid);
  navigationBar.start();
  // Ao voltar para o app, o Android mostra a barra de novo.
  AppLifecycleListener(onResume: navigationBar.hide);
  final app = BoraApp(deps: AppDependencies.fromConfig());
  runApp(
    // Só no Android a tab bar sobe junto com os botões do sistema.
    isAndroid
        ? SystemNavigationBarScope(visible: navigationBar.visible, child: app)
        : app,
  );
}
