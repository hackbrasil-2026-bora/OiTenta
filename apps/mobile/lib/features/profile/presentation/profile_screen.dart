import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_scaffold.dart';
import '../../../core/widgets/bora_widgets.dart';
import 'profile_controller.dart';

/// Perfil (M26, template `PERFIL` do protótipo): avatar com a inicial, nome e
/// e-mail (MP6), "Preferências" e "Configurações". Sem "Sair da conta" (MP12).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onToggleDark,
    required this.onToggleBlockApps,
    required this.onRoutine,
    required this.onLanguage,
    required this.onSuggestion,
  });

  final ProfileController state;
  final VoidCallback onBack;
  final VoidCallback onToggleDark;
  final VoidCallback onToggleBlockApps;
  final VoidCallback onRoutine;
  final VoidCallback onLanguage;
  final VoidCallback onSuggestion;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: onBack)),
      children: [
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.priSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                state.initial,
                style: BoraText.fredoka(
                  32,
                  32,
                  weight: FontWeight.w700,
                  color: c.pri,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.name, style: BoraText.h1(c.tx)),
                  Text(state.subtitle, style: BoraText.small(c.tx2)),
                ],
              ),
            ),
          ],
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(state.error!, style: BoraText.caption(c.danger)),
        ],
        const SizedBox(height: 24),
        const SectionHeader(label: 'Preferências'),
        const SizedBox(height: 12),
        _Group(
          rows: [
            _Row(
              icon: PhosphorIconsRegular.moon,
              title: 'Modo escuro',
              subtitle: 'Tema atual: ${state.themeText}',
              trailing: BoraSwitch(on: state.isDark),
              toggled: state.isDark,
              onTap: onToggleDark,
            ),
            _Row(
              icon: PhosphorIconsRegular.lockSimple,
              title: 'Bloquear apps durante o foco',
              trailing: BoraSwitch(on: state.blockApps),
              toggled: state.blockApps,
              onTap: onToggleBlockApps,
            ),
            _Row(
              icon: PhosphorIconsRegular.clock,
              title: 'Máximo por dia',
              trailing: _Value(state.dailyLimitText),
            ),
            _Row(
              icon: PhosphorIconsRegular.bellSimple,
              title: 'Lembrete da rampa',
              trailing: _Value(state.reminderText),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(label: 'Configurações'),
        const SizedBox(height: 12),
        _Group(
          rows: [
            _Row(
              icon: PhosphorIconsRegular.arrowsClockwise,
              title: 'Redefinir minha rotina',
              trailing: const _Chevron(),
              onTap: onRoutine,
            ),
            _Row(
              icon: PhosphorIconsRegular.globe,
              title: 'Idioma',
              subtitle: state.languageName,
              trailing: const _Chevron(),
              onTap: onLanguage,
            ),
            _Row(
              icon: PhosphorIconsRegular.chatCircle,
              title: 'Enviar sugestão',
              trailing: const _Chevron(),
              onTap: onSuggestion,
            ),
          ],
        ),
      ],
    );
  }
}

/// Card com as linhas separadas por borda de 1px.
class _Group extends StatelessWidget {
  const _Group({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return BoraCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, row) in rows.indexed)
            if (i == 0)
              row
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: row,
              ),
        ],
      ),
    );
  }
}

/// Linha do Perfil: 60 de altura mínima, ícone 22, título e subtítulo
/// opcional, e o elemento à direita (interruptor, valor ou chevron).
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onTap,
    this.toggled,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final content = Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: c.tx2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BoraText.nunito(
                    15,
                    20,
                    weight: FontWeight.w800,
                    color: c.tx,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: BoraText.caption(c.tx2)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      toggled: toggled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Valor à direita (Fredoka 600 16, `--tx2`).
class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: BoraText.fredoka(16, 16, color: context.bora.tx2));
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) =>
      Icon(PhosphorIconsBold.caretRight, size: 18, color: context.bora.tx2);
}
