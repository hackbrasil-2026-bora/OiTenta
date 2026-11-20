import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/goals/data/sample_single_tasks_repository.dart';
import 'package:oitenta/features/goals/data/single_tasks_repository.dart';
import 'package:oitenta/features/goals/domain/single_task.dart';
import 'package:oitenta/features/goals/presentation/single_tasks_controller.dart';

/// Quinta, 6/11/2025 (o "hoje" do protótipo).
final _today = DateTime(2025, 11, 6, 9, 41);

/// Repositório de teste: lista fixa ou a de exemplo, falhas por método e uma
/// trava para segurar a chamada no meio.
class _Repo implements SingleTasksRepository {
  _Repo([List<SingleTask>? tasks])
    : _inner = SampleSingleTasksRepository(today: _today),
      _fixed = tasks;

  final SampleSingleTasksRepository _inner;
  final List<SingleTask>? _fixed;
  final Set<String> failOn = {};
  Completer<void>? gate;
  final List<String> calls = [];
  NewSingleTask? lastCreated;

  Future<void> _step(String name) async {
    calls.add(name);
    if (gate != null) await gate!.future;
    if (failOn.contains(name)) throw NetworkFailure('sem rede');
  }

  @override
  Future<List<SingleTask>> list() async {
    await _step('list');
    return _fixed ?? await _inner.list();
  }

  @override
  Future<SingleTask> create(NewSingleTask task) async {
    await _step('create');
    lastCreated = task;
    return _inner.create(task);
  }

  @override
  Future<void> setDone(String id, {required bool done}) async {
    await _step('setDone:$id:$done');
    await _inner.setDone(id, done: done);
  }

  @override
  Future<void> delete(String id) async {
    await _step('delete:$id');
    await _inner.delete(id);
  }
}

SingleTask _t(String id, String? date, {int minutes = 15, bool done = false}) =>
    SingleTask(
      id: id,
      title: 'Tarefa $id',
      estimatedMinutes: minutes,
      plannedDate: date,
      done: done,
    );

void main() {
  late _Repo repo;
  late SingleTasksController c;

  SingleTasksController make(_Repo r) =>
      SingleTasksController(r, FixedClock(_today));

  setUp(() {
    repo = _Repo();
    c = make(repo);
  });

  group('grupos', () {
    test(
      'as tarefas do protótipo nos grupos e subtítulos da tela 53',
      () async {
        expect(c.loading, isTrue);
        await c.load();
        expect(c.loading, isFalse);
        expect(c.error, isNull);
        expect(c.groups.map((g) => g.title), [
          'Hoje',
          'Próximos dias',
          'Sem data',
          'Feitas',
        ]);
        expect(c.groups.map((g) => g.count), [
          '1 tarefa',
          '3 tarefas',
          '1 tarefa',
          '1 tarefa',
        ]);
        final hoje = c.groups[0].items.single;
        expect(hoje.title, 'Pagar a conta de luz');
        expect(hoje.subtitle, '15 min · Hoje');
        expect(hoje.done, isFalse);
        expect(hoje.toggleLabel, 'Marcar como feita');
        expect(c.groups[1].items.map((i) => i.subtitle), [
          '30 min · Sáb, 08/11/2025',
          '15 min · Dom, 09/11/2025',
          '1h · Ter, 11/11/2025',
        ]);
        expect(c.groups[2].items.single.subtitle, '30 min · Sem data');
        final feita = c.groups[3].items.single;
        expect(feita.title, 'Renovar a carteirinha do RU');
        expect(feita.done, isTrue);
        expect(feita.toggleLabel, 'Desmarcar');
      },
    );

    test(
      'Hoje inclui datas passadas; Próximos dias por data; Amanhã e 2h',
      () async {
        repo = _Repo([
          _t('a', '2025-11-10'),
          _t('b', '2025-11-07', minutes: 120),
          _t('c', '2025-11-04'),
          _t('d', '2025-11-08'),
          _t('e', '2025-11-08', minutes: 30),
        ]);
        c = make(repo);
        await c.load();
        expect(c.groups.map((g) => g.title), ['Hoje', 'Próximos dias']);
        expect(c.groups[0].items.single.subtitle, '15 min · Ter, 04/11/2025');
        expect(c.groups[1].items.map((i) => i.id), ['b', 'd', 'e', 'a']);
        expect(c.groups[1].items.first.subtitle, '2h · Amanhã');
        expect(c.groups[1].count, '4 tarefas');
      },
    );

    test('Feitas reúne as feitas de qualquer data; vazios somem', () async {
      repo = _Repo([
        _t('a', '2025-11-20', done: true),
        _t('b', null, done: true),
        _t('c', '2025-11-06', done: true),
      ]);
      c = make(repo);
      await c.load();
      expect(c.groups.single.title, 'Feitas');
      expect(c.groups.single.count, '3 tarefas');
      expect(c.groups.single.items.map((i) => i.id), ['a', 'b', 'c']);
    });

    test('lista vazia: nenhum grupo', () async {
      repo = _Repo(const []);
      c = make(repo);
      await c.load();
      expect(c.groups, isEmpty);
    });

    test('falha ao carregar mostra o erro', () async {
      repo.failOn.add('list');
      await c.load();
      expect(c.loading, isFalse);
      expect(c.error, 'Não deu pra carregar suas tarefas.');
      expect(c.groups, isEmpty);
      repo.failOn.clear();
      await c.load();
      expect(c.error, isNull);
    });
  });

  group('painel de adicionar', () {
    setUp(() => c.load());

    test('abre ao digitar; padrões 30 min e Hoje; texto ≥ 2', () {
      expect(c.panelOpen, isFalse);
      expect(c.durations, [15, 30, 60, 120]);
      expect(c.durations.map(SingleTasksController.durationLabel), [
        '15 min',
        '30 min',
        '1h',
        '2h',
      ]);
      expect(c.minutes, 30);
      expect(c.when, SingleTaskWhen.today);
      c.setText('   ');
      expect(c.panelOpen, isFalse);
      c.setText(' P ');
      expect(c.panelOpen, isTrue);
      expect(c.canAdd, isFalse);
      c.setText(' Pa ');
      expect(c.canAdd, isTrue);
      c.setMinutes(60);
      expect(c.minutes, 60);
    });

    test('"Escolher dia" exige o dia e o chip mostra a data', () {
      c.setText('Pagar o boleto');
      expect(c.dayChipLabel, 'Escolher dia');
      c.setWhen(SingleTaskWhen.day);
      expect(c.when, SingleTaskWhen.day);
      expect(c.canAdd, isFalse);
      expect(c.dayChipLabel, 'Escolher dia');
      c.setDay(DateTime(2025, 11, 8));
      expect(c.when, SingleTaskWhen.day);
      expect(c.dayChipLabel, 'Sáb, 08/11/2025');
      expect(c.canAdd, isTrue);
      c.setWhen(SingleTaskWhen.tomorrow);
      expect(c.dayChipLabel, 'Escolher dia');
      expect(c.canAdd, isTrue);
    });

    test('adicionar Hoje: cria, recarrega, limpa e devolve o toast', () async {
      c.setText('  Pagar o boleto ');
      c.setMinutes(15);
      final toast = await c.add();
      expect(toast!.title, 'Tarefa anotada');
      expect(toast.subtitle, 'Encaixei num horário livre de hoje.');
      expect(repo.lastCreated!.title, 'Pagar o boleto');
      expect(repo.lastCreated!.estimatedMinutes, 15);
      expect(repo.lastCreated!.plannedDate, '2025-11-06');
      expect(repo.calls.last, 'list');
      expect(c.groups.first.count, '2 tarefas');
      expect(
        c.groups.first.items.map((i) => i.title),
        contains('Pagar o boleto'),
      );
      expect(c.text, '');
      expect(c.minutes, 30);
      expect(c.when, SingleTaskWhen.today);
      expect(c.day, isNull);
      expect(c.panelOpen, isFalse);
      expect(c.busy, isFalse);
    });

    test('adicionar Amanhã', () async {
      c.setText('Pagar o boleto');
      c.setWhen(SingleTaskWhen.tomorrow);
      final toast = await c.add();
      expect(toast!.subtitle, 'Encaixei num horário livre de amanhã.');
      expect(repo.lastCreated!.plannedDate, '2025-11-07');
      expect(repo.lastCreated!.estimatedMinutes, 30);
    });

    test('adicionar Sem data', () async {
      c.setText('Pagar o boleto');
      c.setWhen(SingleTaskWhen.none);
      final toast = await c.add();
      expect(toast!.subtitle, 'Eu encaixo quando sobrar um tempinho.');
      expect(repo.lastCreated!.plannedDate, isNull);
      final semData = c.groups.firstWhere((g) => g.title == 'Sem data');
      expect(semData.count, '2 tarefas');
    });

    test('adicionar num dia escolhido', () async {
      c.setText('Pagar o boleto');
      c.setWhen(SingleTaskWhen.day);
      c.setDay(DateTime(2025, 11, 8));
      final toast = await c.add();
      expect(toast!.subtitle, 'Encaixei num horário livre de sáb, 08/11/2025.');
      expect(repo.lastCreated!.plannedDate, '2025-11-08');
      expect(c.when, SingleTaskWhen.today);
      expect(c.day, isNull);
      expect(c.dayChipLabel, 'Escolher dia');
    });

    test('não adiciona quando não pode', () async {
      c.setText('P');
      expect(await c.add(), isNull);
      expect(repo.calls.where((x) => x == 'create'), isEmpty);
    });

    test('falha ao salvar mantém o texto e mostra o erro', () async {
      repo.failOn.add('create');
      c.setText('Pagar o boleto');
      expect(await c.add(), isNull);
      expect(c.error, 'Não deu pra salvar a tarefa.');
      expect(c.text, 'Pagar o boleto');
      expect(c.busy, isFalse);
    });

    test('busy durante o envio', () async {
      c.setText('Pagar o boleto');
      repo.gate = Completer<void>();
      final f = c.add();
      expect(c.busy, isTrue);
      expect(c.canAdd, isFalse);
      repo.gate!.complete();
      await f;
      expect(c.busy, isFalse);
    });

    test('fechar a tela no meio do envio não quebra', () async {
      c.setText('Pagar o boleto');
      repo.gate = Completer<void>();
      final f = c.add();
      c.dispose();
      repo.gate!.complete();
      expect(await f, isNotNull);
    });
  });

  group('marcar e excluir', () {
    setUp(() => c.load());

    test('marcar: setDone(true), toast "Feito!" e vai para Feitas', () async {
      final toast = await c.toggle('luz');
      expect(repo.calls, contains('setDone:luz:true'));
      expect(toast!.title, 'Feito!');
      expect(toast.subtitle, 'Uma coisa a menos na cabeça.');
      expect(c.groups.first.title, 'Próximos dias');
      expect(c.groups.last.count, '2 tarefas');
      expect(repo.calls.last, 'list');
    });

    test('desmarcar: setDone(false) sem toast', () async {
      expect(await c.toggle('ru'), isNull);
      expect(repo.calls, contains('setDone:ru:false'));
      expect(c.groups.first.count, '2 tarefas');
      expect(c.groups.last.title, 'Sem data');
    });

    test('id desconhecido não chama o backend', () async {
      expect(await c.toggle('xyz'), isNull);
      expect(repo.calls.where((x) => x.startsWith('setDone')), isEmpty);
    });

    test('excluir: delete e recarrega', () async {
      await c.remove('presente');
      expect(repo.calls, contains('delete:presente'));
      expect(repo.calls.last, 'list');
      expect(c.groups.map((g) => g.title), ['Hoje', 'Próximos dias', 'Feitas']);
    });

    test('falhas de marcar e excluir mostram o erro', () async {
      repo.failOn.addAll(['setDone:luz:true', 'delete:luz']);
      expect(await c.toggle('luz'), isNull);
      expect(c.error, 'Não deu pra atualizar a tarefa.');
      expect(c.busy, isFalse);
      await c.remove('luz');
      expect(c.error, 'Não deu pra atualizar a tarefa.');
      expect(c.busy, isFalse);
    });

    test('recarregar falhando depois da ação mostra o erro da lista', () async {
      repo.failOn.add('list');
      await c.remove('presente');
      expect(c.error, 'Não deu pra carregar suas tarefas.');
    });
  });
}
