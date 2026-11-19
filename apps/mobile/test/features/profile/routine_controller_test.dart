import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/profile/presentation/routine_controller.dart';
import 'package:oitenta/features/scheduling/data/sample_scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/availability.dart';

import 'routine_fakes.dart';

AvailabilityWindow w(int day, int start, int end) => AvailabilityWindow(
  weekday: day,
  startMinute: start * 60,
  endMinute: end * 60,
);

void main() {
  group('load', () {
    test('lê a disponibilidade e preenche a grade e o limite', () async {
      final repo = FakeSchedulingRepository(
        availability: WeeklyAvailability(
          windows: [w(0, 12, 18)],
          dailyLimitMinutes: 240,
        ),
      );
      final c = RoutineController(repo);
      await c.load();
      expect(c.isFree(0, 2), isTrue); // Seg 12h
      expect(c.isFree(0, 4), isTrue); // Seg 16h
      expect(c.isFree(0, 5), isFalse); // Seg 18h
      expect(c.freeHours, 6);
      expect(c.limitHours, 4);
      expect(c.loading, isFalse);
      expect(c.error, isNull);
    });

    test('o limite em minutos vira horas (180 → 3h)', () async {
      final c = RoutineController(
        FakeSchedulingRepository(
          availability: WeeklyAvailability(
            windows: [w(1, 8, 10)],
            dailyLimitMinutes: 180,
          ),
        ),
      );
      await c.load();
      expect(c.limitHours, 3);
    });

    test('sem disponibilidade (null): grade vazia e limite 4h', () async {
      final c = RoutineController(FakeSchedulingRepository());
      await c.load();
      expect(c.freeHours, 0);
      expect(c.limitHours, 4);
      expect(c.canSave, isFalse);
    });

    test('loading é verdadeiro durante a carga e avisa os ouvintes', () async {
      final c = RoutineController(FakeSchedulingRepository());
      final seen = <bool>[];
      c.addListener(() => seen.add(c.loading));
      final f = c.load();
      expect(c.loading, isTrue);
      await f;
      expect(seen, [true, false]);
    });

    test('se a leitura falhar, mostra o erro e a grade fica vazia', () async {
      final repo = FakeSchedulingRepository()
        ..getError = NetworkFailure('sem rede');
      final c = RoutineController(repo);
      await c.load();
      expect(c.error, 'Não deu pra carregar sua rotina. Tenta de novo?');
      expect(c.freeHours, 0);
      expect(c.loading, isFalse);
    });
  });

  group('edição', () {
    test('toggle alterna a célula e avisa os ouvintes', () {
      final c = RoutineController(FakeSchedulingRepository());
      var calls = 0;
      c.addListener(() => calls++);
      c.toggle(2, 3);
      expect(c.isFree(2, 3), isTrue);
      expect(c.freeHours, 2);
      c.toggle(2, 3);
      expect(c.isFree(2, 3), isFalse);
      expect(calls, 2);
    });

    test('setLimitHours fica entre 1h e 8h e avisa os ouvintes', () {
      final c = RoutineController(FakeSchedulingRepository());
      var calls = 0;
      c.addListener(() => calls++);
      c.setLimitHours(6);
      expect(c.limitHours, 6);
      c.setLimitHours(9);
      expect(c.limitHours, 8);
      c.setLimitHours(0);
      expect(c.limitHours, 1);
      expect(calls, 3);
    });

    test('canSave é falso sem células e verdadeiro com uma', () {
      final c = RoutineController(FakeSchedulingRepository());
      expect(c.canSave, isFalse);
      c.toggle(0, 0);
      expect(c.canSave, isTrue);
    });
  });

  group('save', () {
    test(
      'grava a grade inteira (células vizinhas juntas) e o limite em minutos',
      () async {
        final repo = FakeSchedulingRepository();
        final c = RoutineController(repo);
        c
          ..toggle(0, 3) // Seg 14h
          ..toggle(0, 4) // Seg 16h
          ..toggle(0, 5) // Seg 18h
          ..toggle(5, 0) // Sáb 8h
          ..setLimitHours(3);
        final ok = await c.save();
        expect(ok, isTrue);
        expect(repo.saved, hasLength(1));
        expect(repo.saved.single.windows, [w(0, 14, 20), w(5, 8, 10)]);
        expect(repo.saved.single.dailyLimitMinutes, 180);
        expect(c.saving, isFalse);
        expect(c.error, isNull);
      },
    );

    test('a grade substitui o que estava fora de 8h–22h (MP11)', () async {
      final repo = FakeSchedulingRepository(
        availability: WeeklyAvailability(
          windows: [w(0, 6, 12), w(0, 18, 23)],
          dailyLimitMinutes: 240,
        ),
      );
      final c = RoutineController(repo);
      await c.load();
      expect(await c.save(), isTrue);
      expect(repo.saved.single.windows, [w(0, 8, 12), w(0, 18, 22)]);
    });

    test('funciona com o repositório de exemplo', () async {
      final repo = SampleSchedulingRepository(hasAvailability: false);
      final c = RoutineController(repo)..toggle(4, 6);
      expect(await c.save(), isTrue);
      final a = (await repo.getAvailability())!;
      expect(a.windows, [w(4, 20, 22)]);
      expect(a.dailyLimitMinutes, 240);
    });

    test('sem células não chama o repositório e devolve false', () async {
      final repo = FakeSchedulingRepository();
      final c = RoutineController(repo);
      expect(await c.save(), isFalse);
      expect(repo.saved, isEmpty);
    });

    test('ValidationFailure: mostra a mensagem e devolve false', () async {
      final repo = FakeSchedulingRepository()
        ..setError = ValidationFailure('Janela inválida.');
      final c = RoutineController(repo)..toggle(0, 0);
      expect(await c.save(), isFalse);
      expect(c.error, 'Janela inválida.');
      expect(c.saving, isFalse);
    });

    test('outro erro: mensagem genérica e devolve false', () async {
      final repo = FakeSchedulingRepository()
        ..setError = NetworkFailure('sem rede');
      final c = RoutineController(repo)..toggle(0, 0);
      expect(await c.save(), isFalse);
      expect(c.error, 'Não deu pra salvar sua rotina. Tenta de novo?');
      expect(c.saving, isFalse);
    });

    test(
      'saving é verdadeiro durante o envio e não envia duas vezes',
      () async {
        final repo = FakeSchedulingRepository()..gate = Completer<void>();
        final c = RoutineController(repo)..toggle(0, 0);
        final first = c.save();
        expect(c.saving, isTrue);
        expect(c.canSave, isFalse);
        expect(await c.save(), isFalse);
        repo.gate!.complete();
        expect(await first, isTrue);
        expect(repo.saved, hasLength(1));
        expect(c.saving, isFalse);
      },
    );

    test('um novo envio limpa o erro anterior', () async {
      final repo = FakeSchedulingRepository()
        ..setError = ValidationFailure('Janela inválida.');
      final c = RoutineController(repo)..toggle(0, 0);
      await c.save();
      repo.setError = null;
      expect(await c.save(), isTrue);
      expect(c.error, isNull);
    });
  });
}
