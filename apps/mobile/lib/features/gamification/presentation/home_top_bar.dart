import 'package:flutter/material.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../../core/widgets/broto.dart';
import '../domain/gamification.dart';
import 'gamified_bar.dart';

/// Topo do Hoje e do Jardim (M01, M39): o Broto abre o Jardim, a barra
/// gamificada (P18) e o botão com a inicial abre o Perfil.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.gamification,
    required this.userName,
    required this.onBroto,
    required this.onProfile,
  });

  final GamificationSnapshot? gamification;
  final String userName;
  final VoidCallback? onBroto;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final name = userName.trim();
    return BoraTopBar(
      // Sem ação (no próprio Jardim), o Broto é só imagem: não é anunciado
      // como botão para o leitor de tela.
      leading: Semantics(
        button: onBroto != null,
        image: onBroto == null,
        label: onBroto == null ? 'Mascote Broto' : 'Abrir Jardim',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBroto,
          child: const Broto(mood: BrotoMood.ok, size: 40),
        ),
      ),
      center: gamification == null ? null : GamifiedBar(data: gamification!),
      trailing: Semantics(
        button: true,
        label: 'Perfil',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onProfile,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface,
              border: Border.all(color: c.border),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '' : name[0].toUpperCase(),
              style: BoraText.fredoka(
                16,
                16,
                weight: FontWeight.w700,
                color: c.pri,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
