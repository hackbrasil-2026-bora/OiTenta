import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';
import 'package:oitenta/features/gamification/data/gamification_repository.dart';
import 'package:oitenta/features/gamification/data/sample_gamification_repository.dart';
import 'package:oitenta/features/gamification/domain/gamification.dart';
import 'package:oitenta/features/gamification/domain/garden.dart';
import 'package:oitenta/features/gamification/presentation/garden_controller.dart';

/// Repositório que sempre falha, para o caminho de erro.
class _FailingRepository implements GamificationRepository {
  @override
  Future<GamificationSnapshot> getSnapshot() async => throw Exception('x');

  @override
  Future<CelebrationReward> getCelebration({required bool partial}) async =>
      throw Exception('x');

  @override
  Future<Garden> getGarden() async => throw Exception('x');
}

SessionStore _session([String name = 'Arthur']) => SessionStore()
  ..save(
    AuthSession(
      token: 't',
      user: AuthUser(
        id: '1',
        name: name,
        email: 'a@a',
        timezone: 'America/Sao_Paulo',
      ),
    ),
  );

void main() {
  test('antes de carregar: loading verdadeiro e sem dados', () {
    final c = GardenController(SampleGamificationRepository(), _session());
    expect(c.loading, isTrue);
    expect(c.garden, isNull);
    expect(c.gamification, isNull);
    expect(c.error, isNull);
  });

  test('load() preenche o Jardim e a barra do topo', () async {
    final c = GardenController(SampleGamificationRepository(), _session());
    await c.load();
    expect(c.loading, isFalse);
    expect(c.garden!.stageLabel, 'Estágio Broto · Nível 7');
    expect(c.gamification!.drops, 340);
  });

  test('load() avisa os ouvintes com loading verdadeiro e depois falso', () {
    final c = GardenController(SampleGamificationRepository(), _session());
    final seen = <bool>[];
    c.addListener(() => seen.add(c.loading));
    return c.load().then((_) => expect(seen, [true, false]));
  });

  test('o nome do topo vem da sessão', () {
    final c = GardenController(SampleGamificationRepository(), _session());
    expect(c.userName, 'Arthur');
  });

  test('sem sessão, o nome fica vazio', () {
    final c = GardenController(SampleGamificationRepository(), SessionStore());
    expect(c.userName, '');
  });

  test('falha no repositório: mensagem de erro e loading falso', () async {
    final c = GardenController(_FailingRepository(), _session());
    await c.load();
    expect(c.loading, isFalse);
    expect(c.garden, isNull);
    expect(c.error, 'Não deu pra carregar o seu jardim.');
  });

  test('carregar de novo limpa o erro anterior', () async {
    final c = GardenController(SampleGamificationRepository(), _session());
    c.error = 'antigo';
    await c.load();
    expect(c.error, isNull);
  });
}
