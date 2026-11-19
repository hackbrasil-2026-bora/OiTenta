import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/routes/app_routes.dart';
import 'package:oitenta/core/theme/bora_colors.dart';
import 'package:oitenta/core/widgets/bora_widgets.dart';
import 'package:oitenta/core/widgets/broto.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/gamification/domain/garden.dart';
import 'package:oitenta/features/gamification/presentation/garden_controller.dart';
import 'package:oitenta/features/gamification/presentation/garden_pages.dart';
import 'package:oitenta/features/gamification/presentation/garden_screen.dart';
import 'package:oitenta/features/gamification/presentation/home_top_bar.dart';
import 'package:oitenta/features/profile/presentation/profile_pages.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../helpers/test_app.dart';

const _c = BoraColors.light;

Future<GardenController> _loaded({bool load = true}) async {
  final session = SessionStore()
    ..save(
      const AuthSession(
        token: 't',
        user: AuthUser(
          id: '1',
          name: 'Arthur',
          email: 'a@a',
          timezone: 'America/Sao_Paulo',
        ),
      ),
    );
  final c = GardenController(SampleGamificationRepository(), session);
  if (load) await c.load();
  return c;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  GardenController state, {
  VoidCallback? onProfile,
  VoidCallback? onBroto,
}) async {
  await usePhoneSize(tester);
  await tester.pumpWidget(
    themed(GardenScreen(state: state, onProfile: onProfile, onBroto: onBroto)),
  );
  await tester.pump();
}

BoxDecoration _decoration(WidgetTester tester, String key) =>
    tester.widget<Container>(find.byKey(Key(key))).decoration! as BoxDecoration;

Finder _iconIn(String key, IconData icon) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byIcon(icon));

void main() {
  group('GardenScreen (M04)', () {
    testWidgets('topo: Broto, barra gamificada e o botão "A"', (tester) async {
      await _pumpScreen(tester, await _loaded());
      expect(find.byType(HomeTopBar), findsOneWidget);
      // No Jardim o Broto não tem ação: é anunciado só como "Mascote Broto".
      expect(find.bySemanticsLabel('Mascote Broto'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
      expect(find.text('Nv 7'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('o botão "A" avisa onProfile', (tester) async {
      var profile = 0;
      await _pumpScreen(tester, await _loaded(), onProfile: () => profile++);
      await tester.tap(find.bySemanticsLabel('Perfil'));
      expect(profile, 1);
    });

    testWidgets('título "Jardim"', (tester) async {
      await _pumpScreen(tester, await _loaded());
      expect(find.text('Jardim'), findsOneWidget);
    });

    testWidgets('card do Broto: nome, estágio, barra e texto do XP', (
      tester,
    ) async {
      await _pumpScreen(tester, await _loaded());
      final broto = tester
          .widgetList<Broto>(find.byType(Broto))
          .where((b) => b.size == 130);
      expect(broto, hasLength(1));
      expect(find.text('Broto'), findsOneWidget);
      expect(find.text('Estágio Broto · Nível 7'), findsOneWidget);
      final bar = tester.widget<ProgressBar>(find.byType(ProgressBar));
      expect(bar.value, closeTo(410 / 480, 1e-9));
      expect(bar.height, 10);
      expect(bar.color, _c.fill);
      expect(find.text('70 min de foco até o Nível 8'), findsOneWidget);
    });

    testWidgets('"Dias regados": cabeçalho, "6 seguidos" e os 7 rótulos', (
      tester,
    ) async {
      await _pumpScreen(tester, await _loaded());
      expect(find.text('DIAS REGADOS'), findsOneWidget);
      expect(find.text('6 seguidos'), findsOneWidget);
      for (final d in ['Sex', 'Sáb', 'Dom', 'Seg', 'Ter', 'Qua', 'Hoje']) {
        expect(find.text(d), findsOneWidget, reason: d);
      }
      for (var i = 0; i < 7; i++) {
        expect(find.byKey(Key('garden-day-$i')), findsOneWidget);
      }
    });

    testWidgets('dia regado: gota cheia verde sobre priSoft', (tester) async {
      await _pumpScreen(tester, await _loaded());
      for (final i in [0, 2, 3, 4, 5]) {
        expect(_decoration(tester, 'garden-day-$i').color, _c.priSoft);
        expect(
          _iconIn('garden-day-$i', PhosphorIconsFill.drop),
          findsOneWidget,
        );
      }
      final icon = tester.widget<Icon>(
        _iconIn('garden-day-0', PhosphorIconsFill.drop),
      );
      expect(icon.color, _c.pri);
    });

    testWidgets('Sáb: guarda-chuva azul sobre blueSoft', (tester) async {
      await _pumpScreen(tester, await _loaded());
      expect(_decoration(tester, 'garden-day-1').color, _c.blueSoft);
      final icon = tester.widget<Icon>(
        _iconIn('garden-day-1', PhosphorIconsFill.umbrella),
      );
      expect(icon.color, _c.blue);
    });

    testWidgets('Hoje: vazio, tracejado, com a gota vazada', (tester) async {
      await _pumpScreen(tester, await _loaded());
      expect(_decoration(tester, 'garden-day-6').color, isNull);
      expect(
        find.descendant(
          of: find.byKey(const Key('garden-day-6-dashed')),
          matching: find.byKey(const Key('garden-day-6')),
        ),
        findsOneWidget,
      );
      final icon = tester.widget<Icon>(
        _iconIn('garden-day-6', PhosphorIconsRegular.drop),
      );
      expect(icon.color, _c.tx2);
    });

    testWidgets('"Conquistas": cabeçalho, "3 de 5", nomes e descrições', (
      tester,
    ) async {
      await _pumpScreen(tester, await _loaded());
      expect(find.text('CONQUISTAS'), findsOneWidget);
      expect(find.text('3 de 5'), findsOneWidget);
      for (final t in [
        'Primeiro passo',
        'Fez o primeiro degrau',
        'Rampa completa',
        'Rara · 8% dos usuários',
        'Voltou da pausa',
        'Voltou depois de uma pausa',
        '7 dias regados',
        '6 de 7',
        'Entregue com folga',
        'Entregar antes do prazo',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('conquistadas: ícone próprio sobre priSoft com borda fill', (
      tester,
    ) async {
      await _pumpScreen(tester, await _loaded());
      expect(
        _iconIn('garden-badge-0', PhosphorIconsFill.footprints),
        findsOneWidget,
      );
      expect(
        _iconIn('garden-badge-2', PhosphorIconsFill.arrowCounterClockwise),
        findsOneWidget,
      );
      for (final i in [0, 2]) {
        final d = _decoration(tester, 'garden-badge-$i');
        expect(d.color, _c.priSoft);
        expect((d.border! as Border).top.color, _c.fill);
      }
    });

    testWidgets('rara: âmbar (streakSoft, borda streak, texto streakInk)', (
      tester,
    ) async {
      await _pumpScreen(tester, await _loaded());
      expect(
        _iconIn('garden-badge-1', PhosphorIconsFill.flagCheckered),
        findsOneWidget,
      );
      final d = _decoration(tester, 'garden-badge-1');
      expect(d.color, _c.streakSoft);
      expect((d.border! as Border).top.color, _c.streak);
      final sub = tester.widget<Text>(find.text('Rara · 8% dos usuários'));
      expect(sub.style!.color, _c.streakInk);
    });

    testWidgets('bloqueadas: cadeado, s2, tracejado e nome apagado', (
      tester,
    ) async {
      await _pumpScreen(tester, await _loaded());
      for (final i in [3, 4]) {
        expect(
          _iconIn('garden-badge-$i', PhosphorIconsRegular.lockSimple),
          findsOneWidget,
        );
        expect(_decoration(tester, 'garden-badge-$i').color, _c.s2);
        expect(find.byKey(Key('garden-badge-$i-dashed')), findsOneWidget);
      }
      final name = tester.widget<Text>(find.text('Entregue com folga'));
      expect(name.style!.color, _c.tx2);
      final earned = tester.widget<Text>(find.text('Primeiro passo'));
      expect(earned.style!.color, _c.tx);
    });

    testWidgets('card do guarda-chuva e "Trocar por 50" com a gota', (
      tester,
    ) async {
      await _pumpScreen(tester, await _loaded());
      expect(find.text('Guarda-chuva'), findsOneWidget);
      expect(
        find.text('Protege 1 dia da sequência · você tem 1'),
        findsOneWidget,
      );
      expect(find.text('Trocar por 50'), findsOneWidget);
      expect(
        _iconIn('garden-buy-umbrella', PhosphorIconsFill.drop),
        findsOneWidget,
      );
      final label = tester.widget<Text>(find.text('Trocar por 50'));
      expect(label.style!.color, _c.blue);
    });

    testWidgets('carregando: só o título, sem o card do Broto', (tester) async {
      await _pumpScreen(tester, await _loaded(load: false));
      expect(find.text('Jardim'), findsOneWidget);
      expect(find.text('Estágio Broto · Nível 7'), findsNothing);
      expect(find.text('Trocar por 50'), findsNothing);
    });

    testWidgets('conquista "Entregue com folga" ganha usa o avião de papel', (
      tester,
    ) async {
      final c = await _loaded();
      final g = c.garden!;
      c.garden = Garden(
        name: g.name,
        stage: g.stage,
        level: g.level,
        xp: g.xp,
        levelXp: g.levelXp,
        streak: g.streak,
        drops: g.drops,
        umbrellas: g.umbrellas,
        days: g.days,
        badges: const [
          GardenBadge(
            name: 'Entregue com folga',
            description: 'Entregar antes do prazo',
            icon: 'paper-plane-tilt',
            state: GardenBadgeState.earned,
          ),
        ],
      );
      await _pumpScreen(tester, c);
      expect(
        _iconIn('garden-badge-0', PhosphorIconsFill.paperPlaneTilt),
        findsOneWidget,
      );
    });

    testWidgets('erro: mostra a mensagem', (tester) async {
      final c = await _loaded(load: false)
        ..loading = false
        ..error = 'Não deu pra carregar o seu jardim.';
      await _pumpScreen(tester, c);
      expect(find.text('Não deu pra carregar o seu jardim.'), findsOneWidget);
    });
  });

  group('GardenPage no app (/jardim)', () {
    testWidgets('abre com o topo, o título e os dados do Jardim', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.garden);
      expect(find.byType(GardenScreen), findsOneWidget);
      expect(find.byType(HomeTopBar), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
      expect(find.text('Estágio Broto · Nível 7'), findsOneWidget);
    });

    testWidgets('o botão "A" abre o Perfil', (tester) async {
      await pumpApp(tester, location: AppRoutes.garden);
      await tester.tap(find.bySemanticsLabel('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('no Jardim, o Broto do topo não faz nada', (tester) async {
      await pumpApp(tester, location: AppRoutes.garden);
      final top = tester.widget<HomeTopBar>(find.byType(HomeTopBar));
      expect(top.onBroto, isNull);
      await tester.tap(find.bySemanticsLabel('Mascote Broto'));
      await tester.pumpAndSettle();
      expect(find.byType(GardenPage), findsOneWidget);
      expect(find.byType(ProfilePage), findsNothing);
    });

    testWidgets('"Trocar por 50" não tem ação (MP13): nada muda', (
      tester,
    ) async {
      await pumpApp(tester, location: AppRoutes.garden);
      final buy = find.text('Trocar por 50');
      await tester.ensureVisible(buy);
      await tester.pumpAndSettle();
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(find.text('340'), findsOneWidget);
      expect(
        find.text('Protege 1 dia da sequência · você tem 1'),
        findsOneWidget,
      );
      expect(find.text('−50 gotas'), findsNothing);
      expect(find.textContaining('Guarda-chuva guardado'), findsNothing);
    });
  });
}
