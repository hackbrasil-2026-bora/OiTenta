import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';

/// Moldura dos sheets do Perfil (`sheetIdioma` do protótipo): raio 24 no
/// topo, borda, sombra, a alça e o título.
class ProfileSheetFrame extends StatelessWidget {
  const ProfileSheetFrame({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: c.border),
          left: BorderSide(color: c.border),
          right: BorderSide(color: c.border),
        ),
        boxShadow: [
          BoxShadow(
            color: c.sheetShadow,
            offset: const Offset(0, -8),
            blurRadius: 32,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom > 0 ? bottom : 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: BoraText.h3(c.tx)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Abre um sheet do Perfil sobre a tela inteira e devolve o que ele der
/// com `Navigator.pop`.
Future<T?> showProfileSheet<T>(
  BuildContext context,
  Widget Function(BuildContext sheetContext) builder,
) {
  final c = context.bora;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: c.surface.withValues(alpha: 0),
    barrierColor: c.scrim,
    builder: builder,
  );
}
