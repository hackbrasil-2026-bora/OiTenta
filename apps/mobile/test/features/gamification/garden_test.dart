import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/gamification/domain/garden.dart';

Garden _garden({
  int level = 3,
  int xp = 30,
  int levelXp = 120,
  int streak = 0,
  int umbrellas = 0,
  List<GardenBadge> badges = const [],
}) => Garden(
  name: 'Broto',
  stage: 'Muda',
  level: level,
  xp: xp,
  levelXp: levelXp,
  streak: streak,
  drops: 0,
  umbrellas: umbrellas,
  days: const [GardenDay(label: 'Hoje', state: GardenDayState.pending)],
  badges: badges,
);

void main() {
  test('o rótulo do estágio usa o estágio e o nível', () {
    expect(_garden().stageLabel, 'Estágio Muda · Nível 3');
  });

  test('o texto do XP usa o que falta e o próximo nível', () {
    expect(_garden().nextLevelLabel, '90 min de foco até o Nível 4');
  });

  test('progresso do nível: fração do XP', () {
    expect(_garden().levelProgress, 0.25);
  });

  test('progresso do nível: 0 quando o nível não tem XP', () {
    expect(_garden(levelXp: 0).levelProgress, 0);
  });

  test('progresso do nível: nunca passa de 1', () {
    expect(_garden(xp: 200, levelXp: 100).levelProgress, 1);
  });

  test('sem conquistas: "0 de 0"', () {
    expect(_garden().badgesLabel, '0 de 0');
  });

  test('só a bloqueada não conta como conquistada', () {
    const badges = [
      GardenBadge(
        name: 'a',
        description: '',
        icon: 'drop',
        state: GardenBadgeState.locked,
      ),
      GardenBadge(
        name: 'b',
        description: '',
        icon: 'drop',
        state: GardenBadgeState.rare,
      ),
    ];
    expect(_garden(badges: badges).badgesLabel, '1 de 2');
  });

  test('sequência e guarda-chuvas entram nos textos', () {
    final g = _garden(streak: 2, umbrellas: 3);
    expect(g.streakLabel, '2 seguidos');
    expect(g.umbrellaLabel, 'Protege 1 dia da sequência · você tem 3');
  });
}
