import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../system/system_navigation_bar_scope.dart';
import '../theme/bora_colors.dart';
import '../theme/bora_text.dart';

/// Abas do app (tab bar do protótipo): Hoje, Objetivos, Semana, Jardim.
enum AppTab { today, goals, week, garden }

/// Moldura das telas logadas: conteúdo + tab bar.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.current,
    required this.onTab,
  });

  final Widget child;
  final AppTab current;
  final ValueChanged<AppTab> onTab;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Scaffold(
      backgroundColor: c.bg,
      body: child,
      bottomNavigationBar: switch (SystemNavigationBarScope.visibleOf(
        context,
      )) {
        null => BoraTabBar(current: current, onTab: onTab),
        final visible => _SlidingTabBar(
          visible: visible,
          tabBar: BoraTabBar(current: current, onTab: onTab),
        ),
      },
    );
  }
}

/// Chave da faixa desenhada atrás dos botões do Android, para os testes.
const systemNavigationBarBackdropKey = ValueKey('system-nav-backdrop');

/// Fundo dos botões do Android: o `pri` do tema claro, translúcido.
const _systemNavigationBarBackdrop = Color(0xD9047857);

/// Altura da barra de navegação do Android quando o sistema não informa.
const _defaultSystemNavigationBarHeight = 48.0;

/// Tab bar no Android com a barra de navegação escondida (modo imersivo).
///
/// A tab bar tem sempre a mesma altura e ignora o espaço do sistema. Quando
/// os botões do Android aparecem, ela desliza para cima inteira, sem esticar
/// e sem mudar o tamanho do resto da tela, e uma faixa verde translúcida
/// cobre os botões.
class _SlidingTabBar extends StatefulWidget {
  const _SlidingTabBar({required this.visible, required this.tabBar});

  final bool visible;
  final Widget tabBar;

  @override
  State<_SlidingTabBar> createState() => _SlidingTabBarState();
}

class _SlidingTabBarState extends State<_SlidingTabBar> {
  /// O Android já informou a altura dos botões alguma vez. A partir daí, o
  /// espaço voltar a zero também conta como "botões escondidos": o sistema
  /// pode escondê-los antes do relógio do app.
  bool _insetReported = false;

  @override
  Widget build(BuildContext context) {
    final reported = MediaQuery.viewPaddingOf(context).bottom;
    if (reported > 0) _insetReported = true;
    final shown = widget.visible && (reported > 0 || !_insetReported);
    final tabBar = MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: widget.tabBar,
    );
    // Escondida: no lugar na hora, sem animação (desce junto com os botões).
    if (!shown) return tabBar;

    final inset = reported > 0 ? reported : _defaultSystemNavigationBarHeight;
    // Aparecendo: sobe animada, a partir do pé da tela.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: inset),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, dy, child) => Transform.translate(
        offset: Offset(0, -dy),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            Positioned(
              left: 0,
              right: 0,
              bottom: -inset,
              height: inset,
              child: const ColoredBox(
                key: systemNavigationBarBackdropKey,
                color: _systemNavigationBarBackdrop,
              ),
            ),
          ],
        ),
      ),
      child: tabBar,
    );
  }
}

class BoraTabBar extends StatelessWidget {
  const BoraTabBar({super.key, required this.current, required this.onTab});

  final AppTab current;
  final ValueChanged<AppTab> onTab;

  static const _tabs = [
    (AppTab.today, 'Hoje', PhosphorIconsRegular.sun, PhosphorIconsFill.sun),
    (
      AppTab.goals,
      'Objetivos',
      PhosphorIconsRegular.flagBanner,
      PhosphorIconsFill.flagBanner,
    ),
    (
      AppTab.week,
      'Semana',
      PhosphorIconsRegular.calendarBlank,
      PhosphorIconsFill.calendarBlank,
    ),
    (
      AppTab.garden,
      'Jardim',
      PhosphorIconsRegular.plant,
      PhosphorIconsFill.plant,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottom > 0 ? bottom - 4 : 12),
      child: Row(
        children: [
          for (final (tab, label, icon, iconFill) in _tabs)
            Expanded(
              child: Semantics(
                button: true,
                selected: tab == current,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTab(tab),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 32,
                        decoration: BoxDecoration(
                          color: tab == current
                              ? c.priSoft
                              : c.surface.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          tab == current ? iconFill : icon,
                          size: 24,
                          color: tab == current ? c.pri : c.tx2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: BoraText.nunito(
                          12,
                          16,
                          weight: tab == current
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: tab == current ? c.tx : c.tx2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
