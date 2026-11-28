import '../../../core/sample/bora_sample_data.dart';
import '../domain/gamification.dart';
import '../domain/garden.dart';
import 'gamification_repository.dart';

/// Valores fixos do protótipo (P18): sem lógica e sem endpoint.
class SampleGamificationRepository implements GamificationRepository {
  @override
  Future<GamificationSnapshot> getSnapshot() async {
    final g = BoraSample.gamification;
    return GamificationSnapshot(
      streak: g['streak']!,
      drops: g['drops']!,
      level: g['level']!,
      xp: g['xp']!,
      levelXp: g['levelXp']!,
    );
  }

  @override
  Future<CelebrationReward> getCelebration({required bool partial}) async {
    final c = partial
        ? BoraSample.celebrationPartial
        : BoraSample.celebrationDone;
    return CelebrationReward(
      drops: c['drops']!,
      level: c['level']!,
      xpBefore: c['xpBefore']!,
      xpAfter: c['xpAfter']!,
      levelXp: c['levelXp']!,
      focusXp: c['focusXp']!,
    );
  }

  @override
  Future<Garden> getGarden() async {
    final g = BoraSample.gamification;
    return Garden(
      name: BoraSample.gardenName,
      stage: BoraSample.gardenStage,
      level: g['level']!,
      xp: g['xp']!,
      levelXp: g['levelXp']!,
      streak: g['streak']!,
      drops: g['drops']!,
      umbrellas: BoraSample.gardenUmbrellas,
      days: [
        for (final [label, state] in BoraSample.gardenDays)
          GardenDay(label: label, state: GardenDayState.values.byName(state)),
      ],
      badges: [
        for (final [name, description, icon, state] in BoraSample.gardenBadges)
          GardenBadge(
            name: name,
            description: description,
            icon: icon,
            state: GardenBadgeState.values.byName(state),
          ),
      ],
    );
  }
}
