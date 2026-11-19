import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/gamification/domain/garden.dart';

void main() {
  final repo = SampleGamificationRepository();

  test('barra com os valores fixos do protótipo (P18)', () async {
    final s = await repo.getSnapshot();
    expect(
      [s.streak, s.drops, s.level, s.xp, s.levelXp],
      [6, 340, 7, 410, 480],
    );
  });

  test('celebração: +20 gotas e 435/480 XP; parcial dá +10', () async {
    final c = await repo.getCelebration(partial: false);
    expect(c.drops, 20);
    expect(c.xpAfter, 435);
    expect(c.minutesToNextLevel, 45);
    expect((await repo.getCelebration(partial: true)).drops, 10);
  });

  group('getGarden (Jardim, M04; valores fixos do protótipo, P18)', () {
    late Garden g;
    setUp(() async => g = await repo.getGarden());

    test('Broto: nome, estágio e nível 7', () {
      expect(g.name, 'Broto');
      expect(g.stageLabel, 'Estágio Broto · Nível 7');
    });

    test('XP: 410 de 480 e "70 min de foco até o Nível 8"', () {
      expect([g.level, g.xp, g.levelXp], [7, 410, 480]);
      expect(g.levelProgress, closeTo(410 / 480, 1e-9));
      expect(g.minutesToNextLevel, 70);
      expect(g.nextLevelLabel, '70 min de foco até o Nível 8');
    });

    test('Dias regados: 7 dias com os rótulos do protótipo', () {
      expect(g.days.map((d) => d.label), [
        'Sex',
        'Sáb',
        'Dom',
        'Seg',
        'Ter',
        'Qua',
        'Hoje',
      ]);
    });

    test('Sáb tem guarda-chuva, Hoje está vazio e os demais regados', () {
      expect(g.days.map((d) => d.state), [
        GardenDayState.watered,
        GardenDayState.umbrella,
        GardenDayState.watered,
        GardenDayState.watered,
        GardenDayState.watered,
        GardenDayState.watered,
        GardenDayState.pending,
      ]);
    });

    test('sequência: "6 seguidos"', () {
      expect(g.streak, 6);
      expect(g.streakLabel, '6 seguidos');
    });

    test('Conquistas: os 5 nomes e descrições do protótipo', () {
      expect(g.badges.map((b) => [b.name, b.description]), [
        ['Primeiro passo', 'Fez o primeiro degrau'],
        ['Rampa completa', 'Rara · 8% dos usuários'],
        ['Voltou da pausa', 'Voltou depois de uma pausa'],
        ['7 dias regados', '6 de 7'],
        ['Entregue com folga', 'Entregar antes do prazo'],
      ]);
    });

    test('Conquistas: três conquistadas (uma rara) e duas bloqueadas', () {
      expect(g.badges.map((b) => b.state), [
        GardenBadgeState.earned,
        GardenBadgeState.rare,
        GardenBadgeState.earned,
        GardenBadgeState.locked,
        GardenBadgeState.locked,
      ]);
      expect(g.badges.map((b) => b.earned), [true, true, true, false, false]);
    });

    test('Conquistas: ícones do protótipo', () {
      expect(g.badges.map((b) => b.icon), [
        'footprints',
        'flag-checkered',
        'arrow-counter-clockwise',
        'drop',
        'paper-plane-tilt',
      ]);
    });

    test('"3 de 5" conquistas', () {
      expect(g.earnedBadges, 3);
      expect(g.badgesLabel, '3 de 5');
    });

    test('guarda-chuva: "Protege 1 dia da sequência · você tem 1"', () {
      expect(g.umbrellas, 1);
      expect(g.umbrellaLabel, 'Protege 1 dia da sequência · você tem 1');
      expect(Garden.umbrellaPrice, 50);
    });

    test('gotas: 340', () {
      expect(g.drops, 340);
    });
  });
}
