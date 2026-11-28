/// Estado de um dia em "Dias regados" (M04).
enum GardenDayState {
  /// Regado: gota cheia.
  watered,

  /// Protegido pelo guarda-chuva.
  umbrella,

  /// Ainda não regado (hoje): quadrado vazio e tracejado.
  pending,
}

class GardenDay {
  const GardenDay({required this.label, required this.state});

  final String label;
  final GardenDayState state;
}

/// Estado de uma conquista (M04).
enum GardenBadgeState { earned, rare, locked }

class GardenBadge {
  const GardenBadge({
    required this.name,
    required this.description,
    required this.icon,
    required this.state,
  });

  final String name;
  final String description;

  /// Nome do ícone Phosphor do protótipo (ex.: `footprints`).
  final String icon;
  final GardenBadgeState state;

  bool get earned => state != GardenBadgeState.locked;
}

/// Jardim (M04): Broto, dias regados, conquistas e guarda-chuva, com os
/// valores fixos do protótipo (P18).
class Garden {
  const Garden({
    required this.name,
    required this.stage,
    required this.level,
    required this.xp,
    required this.levelXp,
    required this.streak,
    required this.drops,
    required this.umbrellas,
    required this.days,
    required this.badges,
  });

  /// Preço do guarda-chuva em gotas ("Trocar por 50").
  static const umbrellaPrice = 50;

  final String name;
  final String stage;
  final int level;
  final int xp;
  final int levelXp;
  final int streak;
  final int drops;
  final int umbrellas;
  final List<GardenDay> days;
  final List<GardenBadge> badges;

  String get stageLabel => 'Estágio $stage · Nível $level';

  double get levelProgress =>
      levelXp == 0 ? 0 : (xp / levelXp).clamp(0, 1).toDouble();

  int get minutesToNextLevel => levelXp - xp;

  String get nextLevelLabel =>
      '$minutesToNextLevel min de foco até o Nível ${level + 1}';

  String get streakLabel => '$streak seguidos';

  int get earnedBadges => badges.where((b) => b.earned).length;

  String get badgesLabel => '$earnedBadges de ${badges.length}';

  String get umbrellaLabel =>
      'Protege 1 dia da sequência · você tem $umbrellas';
}
