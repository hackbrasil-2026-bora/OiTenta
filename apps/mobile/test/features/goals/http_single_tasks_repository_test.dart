import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/goals/data/http_single_tasks_repository.dart';
import 'package:oitenta/features/goals/domain/single_task.dart';

import '../../helpers/fake_api.dart';

Map<String, dynamic> _item(
  String id, {
  String title = 'Pagar a conta de luz',
  String status = 'active',
  String? plannedDate = '2026-11-20',
  int minutes = 15,
}) => {
  'id': id,
  'title': title,
  'deadline': null,
  'kind': 'single',
  'plannedDate': plannedDate,
  'estimatedMinutes': minutes,
  'colorIndex': 1,
  'progressPct': status == 'done' ? 100 : 0,
  'done': status == 'done' ? 1 : 0,
  'total': 1,
  'status': status,
  'slackDays': null,
  'createdAt': '2026-11-20T12:00:00.000Z',
};

const _plan = {'totalMinutes': 15, 'days': 1, 'goals': []};

void main() {
  late FakeApi api;
  late HttpSingleTasksRepository repo;

  setUp(() {
    api = FakeApi();
    repo = HttpSingleTasksRepository(api.client);
  });

  group('list', () {
    test('GET /goals?kind=single com Bearer e lê goals[]', () async {
      api.respond({
        'goals': [
          _item('t1'),
          _item(
            't2',
            title: 'Comprar presente',
            status: 'done',
            plannedDate: null,
            minutes: 30,
          ),
        ],
      });
      final list = await repo.list();
      expect(api.last.method, 'GET');
      expect(api.last.url.path, '/goals');
      expect(api.last.url.queryParameters, {'kind': 'single'});
      expect(api.last.headers['Authorization'], 'Bearer tok-123');
      expect(list, hasLength(2));
      expect(list.first.id, 't1');
      expect(list.first.title, 'Pagar a conta de luz');
      expect(list.first.estimatedMinutes, 15);
      expect(list.first.plannedDate, '2026-11-20');
      expect(list.first.done, isFalse);
      expect(list.last.done, isTrue);
      expect(list.last.plannedDate, isNull);
      expect(list.last.estimatedMinutes, 30);
    });

    test('401 → UnauthorizedFailure e avisa a sessão', () async {
      api.fail(401, 'Token inválido.');
      await expectLater(repo.list(), throwsA(isA<UnauthorizedFailure>()));
      expect(api.unauthorizedCalls, 1);
    });
  });

  group('create', () {
    test(
      'POST /goals com kind single, 1 etapa e plannedDate; lê o goal',
      () async {
        api.respond({
          'goal': {
            'id': 'g9',
            'title': 'Pagar o boleto',
            'deadline': null,
            'colorIndex': 2,
            'progressPct': 0,
          },
          'plan': _plan,
        }, 201);
        final t = await repo.create(
          const NewSingleTask(
            title: 'Pagar o boleto',
            estimatedMinutes: 30,
            plannedDate: '2026-11-21',
          ),
        );
        expect(api.last.method, 'POST');
        expect(api.last.url.path, '/goals');
        expect(api.lastBody, {
          'title': 'Pagar o boleto',
          'kind': 'single',
          'plannedDate': '2026-11-21',
          'steps': [
            {
              'title': 'Pagar o boleto',
              'estimatedMinutes': 30,
              'microSteps': [],
            },
          ],
        });
        expect(t.id, 'g9');
        expect(t.title, 'Pagar o boleto');
        expect(t.estimatedMinutes, 30);
        expect(t.plannedDate, '2026-11-21');
        expect(t.done, isFalse);
      },
    );

    test('"Sem data" manda plannedDate: null no corpo', () async {
      api.respond({
        'goal': {
          'id': 'g10',
          'title': 'Comprar presente',
          'deadline': null,
          'colorIndex': 3,
          'progressPct': 0,
        },
        'plan': _plan,
      }, 201);
      final t = await repo.create(
        const NewSingleTask(
          title: 'Comprar presente',
          estimatedMinutes: 15,
          plannedDate: null,
        ),
      );
      final body = api.lastBody as Map;
      expect(body.containsKey('plannedDate'), isTrue);
      expect(body['plannedDate'], isNull);
      expect(body.containsKey('deadline'), isFalse);
      expect(t.plannedDate, isNull);
    });

    test(
      '422 → ValidationFailure; 404 (sem disponibilidade) → NotFoundFailure',
      () async {
        const t = NewSingleTask(
          title: 'x',
          estimatedMinutes: 15,
          plannedDate: null,
        );
        api.fail(422, 'Dados inválidos.');
        await expectLater(repo.create(t), throwsA(isA<ValidationFailure>()));
        api.fail(404, 'Sem disponibilidade.');
        await expectLater(repo.create(t), throwsA(isA<NotFoundFailure>()));
      },
    );
  });

  group('setDone', () {
    test('PATCH /goals/:id/done com {done}', () async {
      api.respond({'goal': _item('t1', status: 'done'), 'plan': _plan});
      await repo.setDone('t1', done: true);
      expect(api.last.method, 'PATCH');
      expect(api.last.url.path, '/goals/t1/done');
      expect(api.lastBody, {'done': true});
      await repo.setDone('t1', done: false);
      expect(api.lastBody, {'done': false});
    });

    test('codifica o id na URL', () async {
      await repo.setDone('a/b c', done: true);
      expect(api.last.url.pathSegments, ['goals', 'a/b c', 'done']);
    });

    test(
      '404 → NotFoundFailure; 422 (objetivo comum) → ValidationFailure',
      () async {
        api.fail(404, 'Objetivo não encontrado.');
        await expectLater(
          repo.setDone('x', done: true),
          throwsA(isA<NotFoundFailure>()),
        );
        api.fail(422, 'Só tarefa única.');
        await expectLater(
          repo.setDone('x', done: true),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );
  });

  group('delete', () {
    test('DELETE /goals/:id sem corpo', () async {
      api.respond({'plan': _plan});
      await repo.delete('t1');
      expect(api.last.method, 'DELETE');
      expect(api.last.url.path, '/goals/t1');
      expect(api.last.body, isEmpty);
    });

    test('codifica o id na URL', () async {
      await repo.delete('a/b c');
      expect(api.last.url.pathSegments, ['goals', 'a/b c']);
    });

    test('404 → NotFoundFailure', () async {
      api.fail(404, 'Objetivo não encontrado.');
      await expectLater(repo.delete('x'), throwsA(isA<NotFoundFailure>()));
    });
  });
}
