import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/scheduling/data/sample_commitments_repository.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';

/// Compromissos de exemplo (protótipo `cpDefaults`, hoje = qui 06/11/2025),
/// com a regra "série + exceções" (MC1, MC12).
void main() {
  late SampleCommitmentsRepository repo;
  setUp(() => repo = SampleCommitmentsRepository());

  Future<List<CommitmentOccurrence>> on(String date) =>
      repo.listOccurrences(date, date);

  test(
    'ter 11/11: violão 19:00 e dentista 08:00, ordenados pela hora',
    () async {
      final day = await on('2025-11-11');
      expect(day.map((o) => o.title), [
        'Consulta no dentista',
        'Aula de violão',
      ]);
      expect(day.first.isRecurring, isFalse);
      expect(day.last.startMinute, 1140);
    },
  );

  test('sex 07/11: academia cancelada aparece como cancelled', () async {
    final day = await on('2025-11-07');
    final acad = day.firstWhere((o) => o.commitmentId == 'acad');
    expect(acad.status, OccurrenceStatus.cancelled);
  });

  test('qua 12/11: estágio movido para 14:00–17:00', () async {
    final day = await on('2025-11-12');
    final est = day.firstWhere((o) => o.commitmentId == 'est');
    expect(est.status, OccurrenceStatus.moved);
    expect(est.startMinute, 840);
    expect(est.originalDate, '2025-11-12');
  });

  test('a série respeita startDate e endDate', () async {
    expect(await on('2025-11-04'), isEmpty); // antes do início (06/11)
    final dez = await on('2025-12-15');
    expect(dez.any((o) => o.commitmentId == 'ed'), isFalse); // fim 12/12
  });

  test('criar e ler', () async {
    final c = await repo.create(
      const NewCommitment(
        title: 'Inglês',
        category: CommitmentCategory.aula,
        startDate: '2025-11-06',
        startMinute: 1080,
        endMinute: 1140,
        recurrence: CommitmentRecurrence(weekdays: [3]),
      ),
    );
    expect((await repo.get(c.id)).title, 'Inglês');
    expect((await on('2025-11-13')).any((o) => o.commitmentId == c.id), isTrue);
  });

  test('editar todas as semanas', () async {
    await repo.update(
      'violao',
      const CommitmentChange(
        scope: CommitmentScope.all,
        startMinute: 1200,
        endMinute: 1260,
      ),
    );
    final o = (await on(
      '2025-11-11',
    )).firstWhere((o) => o.commitmentId == 'violao');
    expect(o.startMinute, 1200);
  });

  test('editar desse dia em diante divide a série (MC12)', () async {
    final next = await repo.update(
      'violao',
      const CommitmentChange(
        scope: CommitmentScope.following,
        fromDate: '2025-11-18',
        startMinute: 1200,
        endMinute: 1260,
      ),
    );
    final antes = (await on(
      '2025-11-11',
    )).firstWhere((o) => o.title == 'Aula de violão');
    final depois = (await on(
      '2025-11-18',
    )).firstWhere((o) => o.title == 'Aula de violão');
    expect(antes.startMinute, 1140);
    expect(depois.startMinute, 1200);
    expect(depois.commitmentId, next.id);
    expect((await repo.get('violao')).recurrence!.endDate, '2025-11-17');
  });

  test('dividir no primeiro dia apaga a série antiga', () async {
    await repo.update(
      'violao',
      const CommitmentChange(
        scope: CommitmentScope.following,
        fromDate: '2025-11-06',
        title: 'Violão',
      ),
    );
    expect(() => repo.get('violao'), throwsA(isA<NotFoundFailure>()));
  });

  test('excluir desse dia em diante encerra; excluir tudo apaga', () async {
    await repo.delete(
      'violao',
      scope: CommitmentScope.following,
      fromDate: '2025-11-18',
    );
    expect(
      (await on('2025-11-11')).any((o) => o.commitmentId == 'violao'),
      isTrue,
    );
    expect(
      (await on('2025-11-18')).any((o) => o.commitmentId == 'violao'),
      isFalse,
    );
    await repo.delete('dent', scope: CommitmentScope.all);
    expect(() => repo.get('dent'), throwsA(isA<NotFoundFailure>()));
  });

  test('não vai ter nesse dia e vai ter sim', () async {
    await repo.setOccurrence(
      'violao',
      '2025-11-11',
      const OccurrenceChange.cancel(),
    );
    var o = (await on(
      '2025-11-11',
    )).firstWhere((o) => o.commitmentId == 'violao');
    expect(o.isCancelled, isTrue);
    await repo.clearOccurrence('violao', '2025-11-11');
    o = (await on('2025-11-11')).firstWhere((o) => o.commitmentId == 'violao');
    expect(o.status, OccurrenceStatus.normal);
  });

  test('mover só nesse dia (outro dia e horário)', () async {
    await repo.setOccurrence(
      'violao',
      '2025-11-11',
      const OccurrenceChange.move(
        newDate: '2025-11-12',
        startMinute: 1200,
        endMinute: 1260,
      ),
    );
    expect(
      (await on('2025-11-11')).any((o) => o.commitmentId == 'violao'),
      isFalse,
    );
    final o = (await on(
      '2025-11-12',
    )).firstWhere((o) => o.commitmentId == 'violao');
    expect(o.isMoved, isTrue);
    expect(o.originalDate, '2025-11-11');
  });

  test(
    'erros: dia que não é ocorrência, sem exceção, id inexistente',
    () async {
      expect(
        () => repo.setOccurrence(
          'violao',
          '2025-11-12',
          const OccurrenceChange.cancel(),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => repo.clearOccurrence('violao', '2025-11-11'),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(() => repo.get('nada'), throwsA(isA<NotFoundFailure>()));
    },
  );
}
