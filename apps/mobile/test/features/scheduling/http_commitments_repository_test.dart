import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/scheduling/data/http_commitments_repository.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';

import '../../helpers/fake_api.dart';

const _commitment = {
  'id': 'c 1',
  'title': 'Aula de violão',
  'category': 'pessoal',
  'startDate': '2025-11-06',
  'startMinute': 1140,
  'endMinute': 1200,
  'recurrence': {
    'weekdays': [1],
  },
  'exceptions': [
    {'date': '2025-11-18', 'type': 'cancelled'},
  ],
};

const _plan = {'totalMinutes': 0, 'days': 0, 'goals': <Object>[]};

void main() {
  late FakeApi api;
  late HttpCommitmentsRepository repo;

  setUp(() {
    api = FakeApi();
    repo = HttpCommitmentsRepository(api.client);
  });

  test(
    'create: POST /scheduling/commitments com o corpo do contrato',
    () async {
      api.respond({'commitment': _commitment, 'plan': _plan}, 201);
      final c = await repo.create(
        const NewCommitment(
          title: 'Aula de violão',
          category: CommitmentCategory.pessoal,
          startDate: '2025-11-06',
          startMinute: 1140,
          endMinute: 1200,
          recurrence: CommitmentRecurrence(weekdays: [1]),
        ),
      );
      expect(api.last.method, 'POST');
      expect(api.last.url.path, '/scheduling/commitments');
      expect(api.last.headers['Authorization'], 'Bearer tok-123');
      expect(api.lastBody, {
        'title': 'Aula de violão',
        'category': 'pessoal',
        'startDate': '2025-11-06',
        'startMinute': 1140,
        'endMinute': 1200,
        'recurrence': {
          'weekdays': [1],
        },
      });
      expect(c.id, 'c 1');
      expect(c.exceptions.single.type, CommitmentExceptionType.cancelled);
    },
  );

  test('get: GET /scheduling/commitments/:id com o id codificado', () async {
    api.respond({'commitment': _commitment});
    final c = await repo.get('c 1');
    expect(api.last.method, 'GET');
    expect(
      api.last.url.toString(),
      'http://api.test/scheduling/commitments/c%201',
    );
    expect(c.title, 'Aula de violão');
  });

  test('listOccurrences: GET …/occurrences?from&to', () async {
    api.respond({
      'occurrences': [
        {
          'commitmentId': 'c 1',
          'title': 'Aula de violão',
          'category': 'pessoal',
          'date': '2025-11-11',
          'originalDate': '2025-11-11',
          'startMinute': 1140,
          'endMinute': 1200,
          'status': 'normal',
          'recurrence': {
            'weekdays': [1],
          },
        },
      ],
    });
    final list = await repo.listOccurrences('2025-11-10', '2025-11-16');
    expect(api.last.method, 'GET');
    expect(api.last.url.path, '/scheduling/commitments/occurrences');
    expect(api.last.url.queryParameters, {
      'from': '2025-11-10',
      'to': '2025-11-16',
    });
    expect(list.single.commitmentId, 'c 1');
    expect(list.single.status, OccurrenceStatus.normal);
  });

  test(
    'update: PATCH /scheduling/commitments/:id com change.toJson()',
    () async {
      api.respond({'commitment': _commitment, 'plan': _plan});
      final c = await repo.update(
        'c 1',
        const CommitmentChange(
          scope: CommitmentScope.following,
          fromDate: '2025-11-18',
          startMinute: 1200,
          endMinute: 1260,
        ),
      );
      expect(api.last.method, 'PATCH');
      expect(api.last.url.path, '/scheduling/commitments/c%201');
      expect(api.lastBody, {
        'scope': 'following',
        'fromDate': '2025-11-18',
        'startMinute': 1200,
        'endMinute': 1260,
      });
      expect(c.id, 'c 1');
    },
  );

  test('delete: DELETE …/:id?scope=all, sem fromDate', () async {
    api.respond({'plan': _plan});
    await repo.delete('c 1', scope: CommitmentScope.all);
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, '/scheduling/commitments/c%201');
    expect(api.last.url.queryParameters, {'scope': 'all'});
  });

  test('delete: DELETE …/:id?scope=following&fromDate=', () async {
    api.respond({'plan': _plan});
    await repo.delete(
      'c 1',
      scope: CommitmentScope.following,
      fromDate: '2025-11-18',
    );
    expect(api.last.url.queryParameters, {
      'scope': 'following',
      'fromDate': '2025-11-18',
    });
  });

  test('setOccurrence: PUT …/:id/occurrences/:date (cancelar)', () async {
    api.respond({'commitment': _commitment, 'plan': _plan});
    final c = await repo.setOccurrence(
      'c 1',
      '2025-11-18',
      const OccurrenceChange.cancel(),
    );
    expect(api.last.method, 'PUT');
    expect(
      api.last.url.path,
      '/scheduling/commitments/c%201/occurrences/2025-11-18',
    );
    expect(api.lastBody, {'status': 'cancelled'});
    expect(c.exceptionOn('2025-11-18'), isNotNull);
  });

  test('setOccurrence: PUT com status moved, newDate e horários', () async {
    api.respond({'commitment': _commitment, 'plan': _plan});
    await repo.setOccurrence(
      'c 1',
      '2025-11-18',
      const OccurrenceChange.move(
        newDate: '2025-11-19',
        startMinute: 600,
        endMinute: 660,
      ),
    );
    expect(api.lastBody, {
      'status': 'moved',
      'newDate': '2025-11-19',
      'startMinute': 600,
      'endMinute': 660,
    });
  });

  test('clearOccurrence: DELETE …/:id/occurrences/:date', () async {
    api.respond({'commitment': _commitment, 'plan': _plan});
    final c = await repo.clearOccurrence('c 1', '2025-11-18');
    expect(api.last.method, 'DELETE');
    expect(
      api.last.url.path,
      '/scheduling/commitments/c%201/occurrences/2025-11-18',
    );
    expect(api.last.body, isEmpty);
    expect(c.id, 'c 1');
  });

  test('404 vira NotFoundFailure', () async {
    api.fail(404, 'Compromisso não encontrado.');
    await expectLater(repo.get('x'), throwsA(isA<NotFoundFailure>()));
    await expectLater(
      repo.clearOccurrence('x', '2025-11-18'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('422 vira ValidationFailure com a mensagem', () async {
    api.fail(422, 'Intervalo inválido.');
    await expectLater(
      repo.listOccurrences('2025-11-16', '2025-11-10'),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Intervalo inválido.',
        ),
      ),
    );
  });

  test('401 vira UnauthorizedFailure e avisa a sessão', () async {
    api.fail(401, 'Token inválido.');
    await expectLater(
      repo.delete('x', scope: CommitmentScope.all),
      throwsA(isA<UnauthorizedFailure>()),
    );
    expect(api.unauthorizedCalls, 1);
  });
}
