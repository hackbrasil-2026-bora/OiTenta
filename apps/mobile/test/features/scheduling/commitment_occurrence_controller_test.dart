import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/scheduling/data/sample_commitments_repository.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_occurrence_controller.dart';

/// Compromissos de exemplo (hoje = qui 06/11/2025) que anotam as mutações e
/// podem falhar ou segurar a resposta sob comando.
class _Repo extends SampleCommitmentsRepository {
  final calls = <String>[];
  bool fail = false;
  bool failGet = false;
  Completer<void>? hold;

  Future<void> _gate(String call) async {
    calls.add(call);
    if (hold != null) await hold!.future;
    if (fail) throw StateError('fora do ar');
  }

  @override
  Future<Commitment> get(String id) async {
    calls.add('get $id');
    if (failGet) throw StateError('fora do ar');
    return super.get(id);
  }

  @override
  Future<void> delete(
    String id, {
    required CommitmentScope scope,
    String? fromDate,
  }) async {
    await _gate('delete $id ${scope.name} $fromDate');
    return super.delete(id, scope: scope, fromDate: fromDate);
  }

  @override
  Future<Commitment> setOccurrence(
    String id,
    String date,
    OccurrenceChange change,
  ) async {
    await _gate('set $id $date ${change.status.name}');
    return super.setOccurrence(id, date, change);
  }

  @override
  Future<Commitment> clearOccurrence(String id, String date) async {
    await _gate('clear $id $date');
    return super.clearOccurrence(id, date);
  }
}

CommitmentOccurrence _occ(
  String id,
  String title,
  CommitmentCategory category,
  String date,
  int start,
  int end, {
  OccurrenceStatus status = OccurrenceStatus.normal,
  List<int>? weekdays,
}) => CommitmentOccurrence(
  commitmentId: id,
  title: title,
  category: category,
  date: date,
  originalDate: date,
  startMinute: start,
  endMinute: end,
  status: status,
  recurrence: weekdays == null
      ? null
      : CommitmentRecurrence(weekdays: weekdays),
);

final _violao = _occ(
  'violao',
  'Aula de violão',
  CommitmentCategory.pessoal,
  '2025-11-11',
  1140,
  1200,
  weekdays: [1],
);
final _estagioMovido = _occ(
  'est',
  'Estágio na Lumen Tech',
  CommitmentCategory.trabalho,
  '2025-11-12',
  840,
  1020,
  status: OccurrenceStatus.moved,
  weekdays: [0, 2, 4],
);
final _dentista = _occ(
  'dent',
  'Consulta no dentista',
  CommitmentCategory.pessoal,
  '2025-11-11',
  480,
  540,
);
final _academiaCancelada = _occ(
  'acad',
  'Academia',
  CommitmentCategory.saude,
  '2025-11-07',
  390,
  450,
  status: OccurrenceStatus.cancelled,
  weekdays: [0, 2, 4],
);

void main() {
  late _Repo repo;

  setUp(() => repo = _Repo());

  Future<CommitmentOccurrenceController> open(CommitmentOccurrence o) async {
    final c = CommitmentOccurrenceController(repo, o);
    await c.load();
    return c;
  }

  List<String> names(CommitmentOccurrenceController c) => [
    for (final a in c.actions) a.name,
  ];

  List<String> descriptions(CommitmentOccurrenceController c) => [
    for (final a in c.actions) a.description,
  ];

  group('cabeçalho', () {
    test(
      'recorrente: nome, "Ter, 11/11/2025 · 19:00–20:00", repetição',
      () async {
        final c = await open(_violao);
        expect(c.title, 'Aula de violão');
        expect(c.category, CommitmentCategory.pessoal);
        expect(c.whenLabel, 'Ter, 11/11/2025 · 19:00–20:00');
        expect(c.repetition, 'Toda terça');
        expect(c.statusLabel, isNull);
        // Sem exceção, não precisa buscar a série.
        expect(repo.calls, isEmpty);
      },
    );

    test('movido: busca a série para mostrar o horário normal', () async {
      final c = await open(_estagioMovido);
      expect(repo.calls, ['get est']);
      expect(c.whenLabel, 'Qua, 12/11/2025 · 14:00–17:00');
      expect(c.statusLabel, 'Horário alterado · normal é 13:00–15:30');
    });

    test('movido sem a série (erro no GET): texto sem o horário', () async {
      repo.failGet = true;
      final c = await open(_estagioMovido);
      expect(c.statusLabel, 'Horário alterado');
      expect(c.actions[1].description, 'Como nas outras semanas');
    });

    test('cancelado: "Não vai ter nesse dia"', () async {
      final c = await open(_academiaCancelada);
      expect(c.statusLabel, 'Não vai ter nesse dia');
      expect(c.isCancelled, isTrue);
    });
  });

  group('ações por estado (ocAcoes)', () {
    test('recorrente sem exceção: Editar, Não vai ter, Excluir', () async {
      final c = await open(_violao);
      expect(names(c), ['Editar', 'Não vai ter nesse dia', 'Excluir']);
      expect(descriptions(c), [
        'Horário, nome ou dias',
        'Libero esse horário só dessa vez',
        'Tirar da agenda: um dia, daqui pra frente ou tudo',
      ]);
      expect(c.isCancelled, isFalse);
    });

    test(
      'recorrente movido: Editar, Voltar pro horário normal, Excluir',
      () async {
        final c = await open(_estagioMovido);
        expect(names(c), ['Editar', 'Voltar pro horário normal', 'Excluir']);
        expect(
          c.actions[1].description,
          '13:00–15:30, como nas outras semanas',
        );
      },
    );

    test('único: Editar e Excluir com os textos do único', () async {
      final c = await open(_dentista);
      expect(c.repetition, 'Só uma vez');
      expect(names(c), ['Editar', 'Excluir']);
      expect(descriptions(c), ['Data, horário ou nome', 'Tirar da sua agenda']);
    });

    test('cancelado: sem menu (só o "Vai ter sim")', () async {
      final c = await open(_academiaCancelada);
      expect(c.actions, isEmpty);
    });
  });

  group('efeitos diretos', () {
    test('Não vai ter nesse dia → cancela a ocorrência', () async {
      final c = await open(_violao);
      final out = await c.pick(OccurrenceActionKind.skip);
      expect(repo.calls, ['set violao 2025-11-11 cancelled']);
      expect(out!.edit, isNull);
      expect(out.toast!.kind, OccurrenceToastKind.freed);
      expect(out.toast!.title, 'Horário liberado');
      expect(out.toast!.subtitle, 'Só nesse dia. Posso encaixar etapas aí.');
    });

    test('Vai ter sim → limpa a exceção', () async {
      final c = await open(_academiaCancelada);
      final out = await c.keep();
      expect(repo.calls, ['clear acad 2025-11-07']);
      expect(out!.toast!.kind, OccurrenceToastKind.back);
      expect(out.toast!.title, 'Voltou pra agenda');
      expect(out.toast!.subtitle, 'Esse dia segue o horário de sempre.');
    });

    test('Voltar pro horário normal → limpa a exceção', () async {
      final c = await open(_estagioMovido);
      final out = await c.pick(OccurrenceActionKind.restore);
      expect(repo.calls.last, 'clear est 2025-11-12');
      expect(out!.toast!.kind, OccurrenceToastKind.restored);
      expect(out.toast!.title, 'Horário normal de volta');
      expect(out.toast!.subtitle, '13:00–15:30 nesse dia.');
    });

    test('Voltar pro horário normal sem a série: subtítulo genérico', () async {
      repo.failGet = true;
      final c = await open(_estagioMovido);
      final out = await c.pick(OccurrenceActionKind.restore);
      expect(out!.toast!.subtitle, 'Esse dia segue o horário de sempre.');
    });

    test('único: Excluir → DELETE scope=all', () async {
      final c = await open(_dentista);
      final out = await c.pick(OccurrenceActionKind.delete);
      expect(repo.calls, ['delete dent all null']);
      expect(out!.toast!.kind, OccurrenceToastKind.deleted);
      expect(out.toast!.title, 'Compromisso excluído');
      expect(out.toast!.subtitle, 'Liberei esse horário pro seu plano.');
    });

    test(
      'único: Editar → formulário com scope all, sem chamar o backend',
      () async {
        final c = await open(_dentista);
        final out = await c.pick(OccurrenceActionKind.edit);
        expect(repo.calls, isEmpty);
        expect(out!.toast, isNull);
        expect(out.edit!.commitmentId, 'dent');
        expect(out.edit!.scope, CommitmentScope.all);
        expect(out.edit!.occurrenceDate, isNull);
      },
    );
  });

  group('passo de escopo (recorrente)', () {
    test('Editar abre "Editar qual?" com "Só nesse dia" marcado', () async {
      final c = await open(_violao);
      final out = await c.pick(OccurrenceActionKind.edit);
      expect(out, isNull);
      expect(c.scopeStep, isTrue);
      expect(c.isDeleteStep, isFalse);
      expect(c.scopeTitle, 'Editar qual?');
      expect(c.scopes.map((s) => s.name), [
        'Só nesse dia',
        'Desse dia em diante',
        'Todas as semanas',
      ]);
      expect(c.scopes.map((s) => s.description), [
        'Ter, 11/11/2025',
        'A partir de 11/11. Antes fica como era.',
        'A série inteira',
      ]);
      expect(c.scopes.map((s) => s.selected), [true, false, false]);
      expect(c.actions, isEmpty);
    });

    test('Excluir abre "Excluir qual?"; Voltar volta ao menu', () async {
      final c = await open(_violao);
      await c.pick(OccurrenceActionKind.delete);
      expect(c.scopeTitle, 'Excluir qual?');
      expect(c.isDeleteStep, isTrue);
      c.selectScope(OccurrenceScopeChoice.all);
      c.back();
      expect(c.scopeStep, isFalse);
      expect(names(c), ['Editar', 'Não vai ter nesse dia', 'Excluir']);
      // Ao reabrir, volta para "Só nesse dia".
      await c.pick(OccurrenceActionKind.delete);
      expect(c.scope, OccurrenceScopeChoice.day);
    });

    test('Editar só nesse dia → formulário com scope null e a data', () async {
      final c = await open(_violao);
      await c.pick(OccurrenceActionKind.edit);
      final out = await c.confirm();
      expect(repo.calls, isEmpty);
      expect(out!.edit!.commitmentId, 'violao');
      expect(out.edit!.scope, isNull);
      expect(out.edit!.occurrenceDate, '2025-11-11');
    });

    test('Editar desse dia em diante / todas as semanas', () async {
      final c = await open(_violao);
      await c.pick(OccurrenceActionKind.edit);
      c.selectScope(OccurrenceScopeChoice.following);
      expect(c.scopes.map((s) => s.selected), [false, true, false]);
      var out = await c.confirm();
      expect(out!.edit!.scope, CommitmentScope.following);
      expect(out.edit!.occurrenceDate, '2025-11-11');
      c.selectScope(OccurrenceScopeChoice.all);
      out = await c.confirm();
      expect(out!.edit!.scope, CommitmentScope.all);
      expect(out.edit!.occurrenceDate, '2025-11-11');
    });

    test('Excluir só nesse dia → cancela a ocorrência', () async {
      final c = await open(_violao);
      await c.pick(OccurrenceActionKind.delete);
      final out = await c.confirm();
      expect(repo.calls, ['set violao 2025-11-11 cancelled']);
      expect(out!.toast!.kind, OccurrenceToastKind.freed);
    });

    test('Excluir desse dia em diante → DELETE following com a data', () async {
      final c = await open(_violao);
      await c.pick(OccurrenceActionKind.delete);
      c.selectScope(OccurrenceScopeChoice.following);
      final out = await c.confirm();
      expect(repo.calls, ['delete violao following 2025-11-11']);
      expect(out!.toast!.kind, OccurrenceToastKind.ended);
      expect(out.toast!.title, 'Encerrado');
      expect(out.toast!.subtitle, 'O último foi em 10/11.');
    });

    test('Excluir todas as semanas → DELETE all', () async {
      final c = await open(_violao);
      await c.pick(OccurrenceActionKind.delete);
      c.selectScope(OccurrenceScopeChoice.all);
      final out = await c.confirm();
      expect(repo.calls, ['delete violao all null']);
      expect(out!.toast!.title, 'Compromisso excluído');
      expect(out.toast!.subtitle, 'Liberei esses horários pro seu plano.');
    });

    test('a ocorrência movida usa a data original nas ações', () async {
      final moved = CommitmentOccurrence(
        commitmentId: 'est',
        title: 'Estágio na Lumen Tech',
        category: CommitmentCategory.trabalho,
        date: '2025-11-13',
        originalDate: '2025-11-12',
        startMinute: 840,
        endMinute: 1020,
        status: OccurrenceStatus.moved,
        recurrence: const CommitmentRecurrence(weekdays: [0, 2, 4]),
      );
      final c = await open(moved);
      expect(c.whenLabel, 'Qui, 13/11/2025 · 14:00–17:00');
      await c.pick(OccurrenceActionKind.edit);
      expect(c.scopes.first.description, 'Qua, 12/11/2025');
      final out = await c.confirm();
      expect(out!.edit!.occurrenceDate, '2025-11-12');
    });
  });

  group('busy, erro e descarte', () {
    test('busy durante a chamada; ignora toques repetidos', () async {
      final c = await open(_violao);
      repo.hold = Completer<void>();
      final first = c.pick(OccurrenceActionKind.skip);
      expect(c.busy, isTrue);
      expect(await c.pick(OccurrenceActionKind.skip), isNull);
      expect(await c.keep(), isNull);
      expect(await c.confirm(), isNull);
      repo.hold!.complete();
      expect(await first, isNotNull);
      expect(c.busy, isFalse);
      expect(repo.calls, ['set violao 2025-11-11 cancelled']);
    });

    test('erro: mensagem curta, sem resultado; tentar de novo limpa', () async {
      final c = await open(_violao);
      repo.fail = true;
      expect(await c.pick(OccurrenceActionKind.skip), isNull);
      expect(c.busy, isFalse);
      expect(c.error, 'Não deu pra salvar agora. Tenta de novo.');
      repo.fail = false;
      expect(await c.pick(OccurrenceActionKind.skip), isNotNull);
      expect(c.error, isNull);
    });

    test('descartado no meio da chamada: não notifica depois', () async {
      final c = await open(_violao);
      var notified = 0;
      c.addListener(() => notified++);
      repo.hold = Completer<void>();
      final pending = c.pick(OccurrenceActionKind.skip);
      expect(notified, 1);
      c.dispose();
      repo.hold!.complete();
      await pending;
      expect(notified, 1);
    });

    test('descartado durante o load: não notifica depois', () async {
      final c = CommitmentOccurrenceController(repo, _estagioMovido);
      final pending = c.load();
      c.dispose();
      await pending;
    });

    test(
      'descartado durante uma chamada que falha: não notifica depois',
      () async {
        final c = await open(_violao);
        repo.fail = true;
        repo.hold = Completer<void>();
        final pending = c.pick(OccurrenceActionKind.skip);
        c.dispose();
        repo.hold!.complete();
        expect(await pending, isNull);
      },
    );
  });
}
