import 'package:flutter/widgets.dart';

/// Avisa as telas se a barra de navegação do Android (voltar, início, abas)
/// está aparecendo agora. Quem atualiza é o [ImmersiveNavigationBar].
///
/// Sem o escopo (iOS, testes de outras telas), as telas usam o espaço do
/// sistema como antes.
class SystemNavigationBarScope extends InheritedNotifier<ValueNotifier<bool>> {
  const SystemNavigationBarScope({
    super.key,
    required ValueNotifier<bool> visible,
    required super.child,
  }) : super(notifier: visible);

  /// `null` quando não há escopo; senão, se a barra está visível.
  static bool? visibleOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SystemNavigationBarScope>()
      ?.notifier
      ?.value;
}
