import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';

/// Modelos de compromisso do app × contrato §5b (MC1–MC6).
void main() {
  const json = {
    'id': 'c1',
    'title': 'Aula de violão',
    'category': 'pessoal',
    'startDate': '2025-11-04',
    'startMinute': 1140,
    'endMinute': 1200,
    'recurrence': {
      'weekdays': [1],
      'endDate': '2025-12-12',
    },
    'exceptions': [
      {'date': '2025-11-11', 'type': 'cancelled'},
      {
        'date': '2025-11-18',
        'type': 'moved',
        'newDate': '2025-11-19',
        'startMinute': 1200,
        'endMinute': 1260,
      },
    ],
  };

  group('Commitment', () {
    test('fromJson lê todos os campos', () {
      final c = Commitment.fromJson(json);
      expect(c.id, 'c1');
      expect(c.title, 'Aula de violão');
      expect(c.category, CommitmentCategory.pessoal);
      expect(c.startDate, '2025-11-04');
      expect(c.startMinute, 1140);
      expect(c.endMinute, 1200);
      expect(c.recurrence!.weekdays, [1]);
      expect(c.recurrence!.endDate, '2025-12-12');
      expect(c.isRecurring, isTrue);
      expect(c.exceptions, hasLength(2));
      expect(c.exceptions[0].type, CommitmentExceptionType.cancelled);
      expect(c.exceptions[1].newDate, '2025-11-19');
      expect(c.exceptions[1].startMinute, 1200);
      expect(
        c.exceptionOn('2025-11-11')!.type,
        CommitmentExceptionType.cancelled,
      );
      expect(c.exceptionOn('2025-11-25'), isNull);
    });

    test('único: recurrence nula, sem exceções', () {
      final c = Commitment.fromJson({
        ...json,
        'recurrence': null,
        'exceptions': <Object>[],
      });
      expect(c.recurrence, isNull);
      expect(c.isRecurring, isFalse);
      expect(c.exceptions, isEmpty);
    });

    test('recorrência sem endDate', () {
      final r = CommitmentRecurrence.fromJson({
        'weekdays': [0, 2, 4],
      });
      expect(r.endDate, isNull);
      expect(r.toJson(), {
        'weekdays': [0, 2, 4],
      });
    });
  });

  group('categorias', () {
    test('nome no JSON é o do contrato', () {
      expect(CommitmentCategory.values.map((c) => c.name), [
        'aula',
        'trabalho',
        'saude',
        'pessoal',
      ]);
      expect(CommitmentCategory.fromName('saude'), CommitmentCategory.saude);
      expect(() => CommitmentCategory.fromName('lazer'), throwsArgumentError);
    });

    test('rótulos do formulário', () {
      expect(CommitmentCategory.aula.label, 'Aula');
      expect(CommitmentCategory.trabalho.label, 'Trabalho');
      expect(CommitmentCategory.saude.label, 'Saúde');
      expect(CommitmentCategory.pessoal.label, 'Pessoal');
    });
  });

  group('CommitmentOccurrence', () {
    test('fromJson e estados', () {
      final o = CommitmentOccurrence.fromJson({
        'commitmentId': 'c1',
        'title': 'Aula de violão',
        'category': 'pessoal',
        'date': '2025-11-19',
        'originalDate': '2025-11-18',
        'startMinute': 1200,
        'endMinute': 1260,
        'status': 'moved',
        'recurrence': {
          'weekdays': [1],
        },
      });
      expect(o.commitmentId, 'c1');
      expect(o.date, '2025-11-19');
      expect(o.originalDate, '2025-11-18');
      expect(o.status, OccurrenceStatus.moved);
      expect(o.isRecurring, isTrue);
      expect(o.isCancelled, isFalse);
      expect(o.isMoved, isTrue);
    });

    test('cancelada e única', () {
      final o = CommitmentOccurrence.fromJson({
        'commitmentId': 'd',
        'title': 'Consulta no dentista',
        'category': 'pessoal',
        'date': '2025-11-11',
        'originalDate': '2025-11-11',
        'startMinute': 480,
        'endMinute': 540,
        'status': 'cancelled',
        'recurrence': null,
      });
      expect(o.isCancelled, isTrue);
      expect(o.isRecurring, isFalse);
    });
  });

  group('payloads', () {
    test('NewCommitment.toJson no formato do POST', () {
      const n = NewCommitment(
        title: 'Academia',
        category: CommitmentCategory.saude,
        startDate: '2025-11-06',
        startMinute: 390,
        endMinute: 450,
        recurrence: CommitmentRecurrence(weekdays: [0, 2, 4]),
      );
      expect(n.toJson(), {
        'title': 'Academia',
        'category': 'saude',
        'startDate': '2025-11-06',
        'startMinute': 390,
        'endMinute': 450,
        'recurrence': {
          'weekdays': [0, 2, 4],
        },
      });
    });

    test('NewCommitment único manda recurrence null', () {
      const n = NewCommitment(
        title: 'Consulta',
        category: CommitmentCategory.pessoal,
        startDate: '2025-11-11',
        startMinute: 480,
        endMinute: 540,
        recurrence: null,
      );
      expect(n.toJson()['recurrence'], isNull);
      expect(n.toJson().containsKey('recurrence'), isTrue);
    });

    test('CommitmentChange manda só o que mudou, com o escopo', () {
      const ch = CommitmentChange(
        scope: CommitmentScope.following,
        fromDate: '2025-11-18',
        startMinute: 1200,
        endMinute: 1260,
      );
      expect(ch.toJson(), {
        'scope': 'following',
        'fromDate': '2025-11-18',
        'startMinute': 1200,
        'endMinute': 1260,
      });
      const all = CommitmentChange(
        scope: CommitmentScope.all,
        title: 'Violão',
        recurrence: CommitmentRecurrence(weekdays: [2]),
      );
      expect(all.toJson(), {
        'scope': 'all',
        'title': 'Violão',
        'recurrence': {
          'weekdays': [2],
        },
      });
    });

    test('CommitmentChange com makeSingle manda recurrence: null', () {
      const ch = CommitmentChange(
        scope: CommitmentScope.all,
        startDate: '2025-11-11',
        makeSingle: true,
      );
      final j = ch.toJson();
      expect(j.containsKey('recurrence'), isTrue);
      expect(j['recurrence'], isNull);
      expect(j['startDate'], '2025-11-11');
      // sem makeSingle e sem recorrência: a chave não vai (mantém a série)
      expect(const CommitmentChange(scope: CommitmentScope.all).toJson(), {
        'scope': 'all',
      });
    });

    test('OccurrenceChange: cancelar e mover', () {
      expect(const OccurrenceChange.cancel().toJson(), {'status': 'cancelled'});
      expect(
        const OccurrenceChange.move(
          newDate: '2025-11-19',
          startMinute: 1200,
          endMinute: 1260,
        ).toJson(),
        {
          'status': 'moved',
          'newDate': '2025-11-19',
          'startMinute': 1200,
          'endMinute': 1260,
        },
      );
    });
  });
}
