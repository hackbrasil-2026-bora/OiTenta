import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/clock/clock.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/scheduling/domain/commitment.dart';
import 'package:oitenta/features/scheduling/presentation/commitment_form_controller.dart';

import 'commitment_form_fakes.dart';

/// "Hoje" dos testes: sexta, 20/11/2026 (semana de 16 a 22/11).
final today = DateTime(2026, 11, 20, 10);

CommitmentFormController make({
  FakeCommitmentsRepository? repo,
  FakeWeekPlanRepository? plan,
  String? id,
  CommitmentFormArgs args = const CommitmentFormArgs(),
}) => CommitmentFormController(
  commitments: repo ?? FakeCommitmentsRepository(),
  scheduling: plan ?? FakeWeekPlanRepository(),
  clock: FixedClock(today),
  commitmentId: id,
  args: args,
  semesterEnd: '2026-12-12',
);

/// Preenche um nome válido.
CommitmentFormController named(CommitmentFormController c) =>
    c..setTitle('Aula de Banco de Dados');

void main() {
  group('novo (cpBlank)', () {
    test('começa em "Toda semana" com hoje marcado, 19:00–21:00 e Aula', () {
      final c = make();
      expect(c.mode, CommitmentFormMode.create);
      expect(c.heading, 'Novo compromisso');
      expect(
        c.subtitle,
        'Me conta quando você tá ocupado pra eu não marcar etapa por cima.',
      );
      expect(c.saveLabel, 'Salvar compromisso');
      expect(c.repeat, CommitmentRepeat.weekly);
      expect(c.isWeekly, isTrue);
      expect(c.weekdays, {4}); // sexta
      expect(c.startMinute, 1140);
      expect(c.endMinute, 1260);
      expect(c.category, CommitmentCategory.aula);
      expect(c.until, CommitmentUntil.none);
      expect(c.showName, isTrue);
      expect(c.showRepeat, isTrue);
      expect(c.showFixedName, isFalse);
      expect(c.canDelete, isFalse);
      expect(c.loaded, isTrue);
      expect(c.loadFailed, isFalse);
    });

    test('com a data do dia (cpAddDia): "Só uma vez" naquela data', () {
      final c = make(args: const CommitmentFormArgs(date: '2026-11-24'));
      expect(c.repeat, CommitmentRepeat.once);
      expect(c.isWeekly, isFalse);
      expect(c.date, DateTime(2026, 11, 24));
      expect(c.dateText, 'Ter, 24/11/2026');
      expect(c.weekdays, {1});
    });

    test('sem data: "Escolher data"', () {
      final c = make()..setRepeat(CommitmentRepeat.once);
      expect(c.dateText, 'Escolher data');
    });
  });

  group('validação (cpOk)', () {
    test('nome com menos de 2 letras depois de aparar não salva', () {
      final c = make()..setTitle('  A  ');
      expect(c.canSave, isFalse);
      c.setTitle(' Ab ');
      expect(c.canSave, isTrue);
    });

    test('fim depois do início', () {
      final c = named(make())..setEnd(1140);
      expect(c.timeOk, isFalse);
      expect(c.canSave, isFalse);
      c.setStart(1100);
      expect(c.timeOk, isTrue);
      expect(c.canSave, isTrue);
    });

    test('semanal precisa de pelo menos um dia', () {
      final c = named(make())..toggleWeekday(4);
      expect(c.weekdays, isEmpty);
      expect(c.canSave, isFalse);
      c.toggleWeekday(0);
      expect(c.weekdays, {0});
      expect(c.canSave, isTrue);
    });

    test('"Escolher data" sem data não salva', () {
      final c = named(make())..chooseUntil(CommitmentUntil.date);
      expect(c.canSave, isFalse);
      c.setUntilDate(DateTime(2026, 12, 20));
      expect(c.canSave, isTrue);
    });

    test('único precisa de data', () async {
      final c = named(make());
      await c.setRepeat(CommitmentRepeat.once);
      expect(c.canSave, isFalse);
      await c.setDate(DateTime(2026, 11, 25));
      expect(c.canSave, isTrue);
    });

    test('tipo escolhido', () {
      final c = make()..setCategory(CommitmentCategory.saude);
      expect(c.category, CommitmentCategory.saude);
    });
  });

  group('Até quando?', () {
    test('Sem fim', () {
      final c = make()
        ..chooseUntil(CommitmentUntil.semester)
        ..chooseUntil(CommitmentUntil.none);
      expect(c.until, CommitmentUntil.none);
      expect(c.untilDate, isNull);
      expect(c.untilText, 'Repete até você mudar ou excluir.');
      expect(c.untilDateLabel, 'Escolher data');
    });

    test('Fim do semestre usa o SEMESTER_END', () {
      final c = make()..chooseUntil(CommitmentUntil.semester);
      expect(c.untilDate, DateTime(2026, 12, 12));
      expect(
        c.untilText,
        'Para de repetir depois de 12/12, no fim do semestre.',
      );
    });

    test('Escolher data: pede o dia, depois mostra a data', () {
      final c = make()
        ..chooseUntil(CommitmentUntil.semester)
        ..chooseUntil(CommitmentUntil.date);
      expect(c.untilDate, isNull);
      expect(c.untilText, 'Escolha o último dia.');
      c.setUntilDate(DateTime(2026, 12, 20));
      expect(c.until, CommitmentUntil.date);
      expect(c.untilText, 'Para de repetir depois de Dom, 20/12/2026.');
      expect(c.untilDateLabel, 'Até 20/12');
      // Tocar de novo em "Escolher data" mantém a data.
      c.chooseUntil(CommitmentUntil.date);
      expect(c.untilDate, DateTime(2026, 12, 20));
    });
  });

  group('conflito (MC5)', () {
    test('busca a semana do dia e a seguinte', () async {
      final plan = FakeWeekPlanRepository();
      final c = make(plan: plan);
      await c.load();
      expect(plan.requested, ['2026-11-16', '2026-11-23']);
      // As semanas já buscadas não são pedidas de novo.
      await c.setRepeat(CommitmentRepeat.once);
      await c.setDate(DateTime(2026, 11, 20));
      expect(plan.requested, ['2026-11-16', '2026-11-23']);
      await c.setDate(DateTime(2026, 12, 2));
      expect(plan.requested, [
        '2026-11-16',
        '2026-11-23',
        '2026-11-30',
        '2026-12-07',
      ]);
    });

    test('semanal: primeira etapa sobreposta num dia marcado', () async {
      final plan = FakeWeekPlanRepository(
        weeks: {
          '2026-11-23': [
            block(DateTime(2026, 11, 27), 20, 0, 90), // sexta seguinte
            block(DateTime(2026, 11, 24), 20, 0, 60, title: 'Terça'),
          ],
        },
      );
      final c = make(plan: plan);
      await c.load();
      expect(c.conflict?.stepTitle, 'Implementar Merge Sort');
      expect(
        c.conflictTitle,
        'Bate com "Implementar Merge Sort" (27/11 · 20h)',
      );
      c.toggleWeekday(1); // terça entra e vem antes
      expect(c.conflictTitle, 'Bate com "Terça" (24/11 · 20h)');
    });

    test('semanal: ignora dia não marcado, antes de hoje, fora das 2 '
        'semanas, depois do fim, sem sobreposição e não planejado', () async {
      final plan = FakeWeekPlanRepository(
        weeks: {
          '2026-11-16': [
            block(DateTime(2026, 11, 19), 20, 0, 60), // quinta (não marcada)
            block(DateTime(2026, 11, 13), 20, 0, 60), // antes de hoje
            block(DateTime(2026, 11, 20), 21, 0, 60), // começa no fim
            block(DateTime(2026, 11, 20), 18, 0, 60), // termina no início
            block(DateTime(2026, 11, 20), 20, 0, 30, status: 'done'),
          ],
          '2026-11-23': [
            block(DateTime(2026, 11, 30), 20, 0, 60), // fora das 2 semanas
            block(DateTime(2026, 11, 27), 20, 0, 60), // depois do fim
          ],
        },
      );
      final c = make(plan: plan)
        ..chooseUntil(CommitmentUntil.date)
        ..setUntilDate(DateTime(2026, 11, 26));
      await c.load();
      expect(c.conflict, isNull);
      expect(c.conflictTitle, isNull);
    });

    test('etapa que passa da meia-noite conta até o fim do dia', () async {
      final plan = FakeWeekPlanRepository(
        weeks: {
          '2026-11-16': [block(DateTime(2026, 11, 20), 23, 30, 60)],
        },
      );
      final c = make(plan: plan)
        ..setStart(1420)
        ..setEnd(1435);
      await c.load();
      expect(
        c.conflictTitle,
        'Bate com "Implementar Merge Sort" (20/11 · 23h30)',
      );
    });

    test('único: só na data', () async {
      final plan = FakeWeekPlanRepository(
        weeks: {
          '2026-11-23': [
            block(DateTime(2026, 11, 24), 20, 0, 60, title: 'Outro dia'),
            block(DateTime(2026, 11, 25), 20, 0, 60),
          ],
        },
      );
      final c = make(
        plan: plan,
        args: const CommitmentFormArgs(date: '2026-11-25'),
      );
      await c.load();
      expect(c.conflict?.stepTitle, 'Implementar Merge Sort');
    });

    test('único sem data: sem aviso', () async {
      final plan = FakeWeekPlanRepository();
      final c = make(plan: plan);
      await c.setRepeat(CommitmentRepeat.once);
      expect(c.conflict, isNull);
      expect(plan.requested, isEmpty);
    });

    test('horário inválido esconde o aviso', () async {
      final plan = FakeWeekPlanRepository(
        weeks: {
          '2026-11-16': [block(DateTime(2026, 11, 20), 19, 0, 60)],
        },
      );
      final c = make(plan: plan);
      await c.load();
      expect(c.conflict, isNotNull);
      c.setEnd(1100);
      expect(c.conflict, isNull);
    });

    test('falha ao buscar os blocos: sem aviso', () async {
      final c = make(plan: FakeWeekPlanRepository(fail: true));
      await c.load();
      expect(c.conflict, isNull);
      expect(c.error, isNull);
    });
  });

  group('salvar', () {
    test('novo semanal: create com startDate = hoje', () async {
      final repo = FakeCommitmentsRepository();
      final c = named(make(repo: repo))
        ..setCategory(CommitmentCategory.trabalho)
        ..toggleWeekday(0)
        ..chooseUntil(CommitmentUntil.semester);
      final t = await c.save();
      expect(repo.calls, ['create']);
      final n = repo.created!;
      expect(n.title, 'Aula de Banco de Dados');
      expect(n.category, CommitmentCategory.trabalho);
      expect(n.startDate, '2026-11-20');
      expect(n.startMinute, 1140);
      expect(n.endMinute, 1260);
      expect(n.recurrence!.weekdays, [0, 4]);
      expect(n.recurrence!.endDate, '2026-12-12');
      expect(t!.kind, CommitmentToastKind.saved);
      expect(t.title, 'Compromisso salvo');
      expect(t.subtitle, 'Não vou marcar etapas nesse horário.');
      expect(c.busy, isFalse);
    });

    test('novo único: create com a data e sem recorrência', () async {
      final repo = FakeCommitmentsRepository();
      final c = named(
        make(
          repo: repo,
          args: const CommitmentFormArgs(date: '2026-11-25'),
        ),
      );
      await c.save();
      expect(repo.created!.startDate, '2026-11-25');
      expect(repo.created!.recurrence, isNull);
    });

    test('com conflito: toast "Plano recalculado"', () async {
      final plan = FakeWeekPlanRepository(
        weeks: {
          '2026-11-16': [block(DateTime(2026, 11, 20), 20, 0, 60)],
        },
      );
      final c = named(make(plan: plan));
      await c.load();
      final t = await c.save();
      expect(t!.kind, CommitmentToastKind.recalculated);
      expect(t.title, 'Plano recalculado');
      expect(t.subtitle, 'Mudei "Implementar Merge Sort" pra outro horário.');
    });

    test('inválido: não chama o repositório', () async {
      final repo = FakeCommitmentsRepository();
      final c = make(repo: repo);
      expect(await c.save(), isNull);
      expect(repo.calls, isEmpty);
    });

    test('busy durante o envio', () async {
      final repo = FakeCommitmentsRepository()..gate = Completer<void>();
      final c = named(make(repo: repo));
      final f = c.save();
      expect(c.busy, isTrue);
      expect(c.canSave, isFalse);
      repo.gate!.complete();
      await f;
      expect(c.busy, isFalse);
    });

    test('422 mostra a mensagem do backend', () async {
      final repo = FakeCommitmentsRepository(
        error: ValidationFailure('O horário precisa ser de 5 em 5 minutos.'),
      );
      final c = named(make(repo: repo));
      expect(await c.save(), isNull);
      expect(c.error, 'O horário precisa ser de 5 em 5 minutos.');
    });

    test('404 mostra a mensagem do backend', () async {
      final repo = FakeCommitmentsRepository(
        error: NotFoundFailure('Compromisso não encontrado.'),
      );
      final c = named(make(repo: repo));
      expect(await c.save(), isNull);
      expect(c.error, 'Compromisso não encontrado.');
    });

    test('outro erro: mensagem genérica', () async {
      final repo = FakeCommitmentsRepository(error: StateError('x'));
      final c = named(make(repo: repo));
      expect(await c.save(), isNull);
      expect(c.error, 'Não deu pra salvar o compromisso. Tenta de novo?');
    });

    test('fechar a tela durante o envio não quebra', () async {
      final repo = FakeCommitmentsRepository()..gate = Completer<void>();
      final c = named(make(repo: repo));
      final f = c.save();
      c.dispose();
      repo.gate!.complete();
      expect(await f, isNotNull);
    });
  });

  group('editar todas as semanas', () {
    test('carrega a série e mostra os campos', () async {
      final repo = FakeCommitmentsRepository(
        commitment: sampleCommitment(
          recurrence: const CommitmentRecurrence(
            weekdays: [3, 1],
            endDate: '2026-12-12',
          ),
        ),
      );
      final c = make(
        repo: repo,
        id: 'violao',
        args: const CommitmentFormArgs(scope: CommitmentScope.all),
      );
      expect(c.mode, CommitmentFormMode.editAll);
      expect(c.loaded, isFalse);
      expect(c.canSave, isFalse);
      final f = c.load();
      expect(c.loading, isTrue);
      await f;
      expect(repo.calls, ['get:violao']);
      expect(c.heading, 'Editar compromisso');
      expect(c.subtitle, 'Vale pra todas as semanas.');
      expect(c.saveLabel, 'Salvar alterações');
      expect(c.title, 'Aula de violão');
      expect(c.category, CommitmentCategory.pessoal);
      expect(c.weekdays, {1, 3});
      expect(c.until, CommitmentUntil.semester);
      expect(c.startMinute, 1140);
      expect(c.endMinute, 1200);
      expect(c.showName, isTrue);
      expect(c.showRepeat, isTrue);
      expect(c.canDelete, isTrue);
      expect(c.canSave, isTrue);
    });

    test('sem escopo nem data também é "todas"', () {
      final c = make(id: 'violao');
      expect(c.mode, CommitmentFormMode.editAll);
    });

    test('fim em outra data vira "Escolher data"', () async {
      final c = make(
        repo: FakeCommitmentsRepository(
          commitment: sampleCommitment(
            recurrence: const CommitmentRecurrence(
              weekdays: [1],
              endDate: '2026-12-20',
            ),
          ),
        ),
        id: 'violao',
      );
      await c.load();
      expect(c.until, CommitmentUntil.date);
      expect(c.untilDate, DateTime(2026, 12, 20));
    });

    test('salva com update scope all', () async {
      final repo = FakeCommitmentsRepository(commitment: sampleCommitment());
      final c = make(repo: repo, id: 'violao');
      await c.load();
      c
        ..setTitle('Violão')
        ..setStart(1150);
      final t = await c.save();
      expect(repo.calls.last, 'update:violao');
      final ch = repo.change!;
      expect(ch.scope, CommitmentScope.all);
      expect(ch.fromDate, isNull);
      expect(ch.title, 'Violão');
      expect(ch.category, CommitmentCategory.pessoal);
      expect(ch.startMinute, 1150);
      expect(ch.endMinute, 1200);
      expect(ch.startDate, isNull);
      expect(ch.recurrence!.weekdays, [1, 3]);
      expect(ch.recurrence!.endDate, isNull);
      expect(t!.title, 'Compromisso atualizado');
      expect(t.subtitle, 'Vale pra todas as semanas.');
    });

    test('compromisso único: data e texto próprios', () async {
      final repo = FakeCommitmentsRepository(
        commitment: sampleCommitment(recurrence: null, startDate: '2026-11-25'),
      );
      final c = make(repo: repo, id: 'violao');
      await c.load();
      expect(c.repeat, CommitmentRepeat.once);
      expect(c.date, DateTime(2026, 11, 25));
      expect(c.weekdays, {2});
      expect(c.subtitle, 'Me conta o que mudou.');
      final t = await c.save();
      expect(repo.change!.startDate, '2026-11-25');
      expect(repo.change!.recurrence, isNull);
      expect(t!.subtitle, 'Recalculei seu plano em volta dele.');
    });

    test('carga com erro: mensagem e sem salvar', () async {
      final c = make(
        repo: FakeCommitmentsRepository(
          error: NotFoundFailure('Compromisso não encontrado.'),
        ),
        id: 'x',
      );
      await c.load();
      expect(c.error, 'Compromisso não encontrado.');
      expect(c.loadFailed, isTrue);
      expect(c.canSave, isFalse);
      expect(c.canDelete, isFalse);
      expect(await c.save(), isNull);
    });

    test('carga com erro inesperado: mensagem genérica', () async {
      final c = make(
        repo: FakeCommitmentsRepository(error: StateError('x')),
        id: 'x',
      );
      await c.load();
      expect(c.error, 'Não deu pra carregar o compromisso. Tenta de novo?');
    });

    test('fechar a tela durante a carga não quebra', () async {
      final repo = FakeCommitmentsRepository()..gate = Completer<void>();
      final c = make(repo: repo, id: 'violao');
      final f = c.load();
      c.dispose();
      repo.gate!.complete();
      await f;
      expect(c.loaded, isTrue);
    });
  });

  group('excluir (só em todas)', () {
    test('delete scope all e toast', () async {
      final repo = FakeCommitmentsRepository(commitment: sampleCommitment());
      final c = make(repo: repo, id: 'violao');
      await c.load();
      final t = await c.delete();
      expect(repo.calls.last, 'delete:violao');
      expect(repo.deletedScope, CommitmentScope.all);
      expect(t!.kind, CommitmentToastKind.deleted);
      expect(t.title, 'Compromisso excluído');
      expect(t.subtitle, 'Liberei esses horários pro seu plano.');
      expect(c.busy, isFalse);
    });

    test('fora do "todas" não exclui', () async {
      final repo = FakeCommitmentsRepository();
      final c = make(repo: repo);
      expect(await c.delete(), isNull);
      expect(repo.calls, isEmpty);
    });

    test('erro mostra a mensagem', () async {
      final repo = FakeCommitmentsRepository(commitment: sampleCommitment());
      final c = make(repo: repo, id: 'violao');
      await c.load();
      repo.error = StateError('x');
      expect(await c.delete(), isNull);
      expect(c.error, 'Não deu pra excluir o compromisso. Tenta de novo?');
      repo.error = NotFoundFailure('Compromisso não encontrado.');
      expect(await c.delete(), isNull);
      expect(c.error, 'Compromisso não encontrado.');
    });
  });

  group('desse dia em diante (MC12)', () {
    CommitmentFormController following(FakeCommitmentsRepository repo) => make(
      repo: repo,
      id: 'violao',
      args: const CommitmentFormArgs(
        scope: CommitmentScope.following,
        occurrenceDate: '2026-11-24',
      ),
    );

    test('textos e campos', () async {
      final c = following(
        FakeCommitmentsRepository(commitment: sampleCommitment()),
      );
      await c.load();
      expect(c.mode, CommitmentFormMode.editFollowing);
      expect(
        c.subtitle,
        'Vale a partir de Ter, 24/11/2026. Antes disso fica como era.',
      );
      expect(c.saveLabel, 'Salvar alterações');
      expect(c.showName, isTrue);
      expect(c.showRepeat, isFalse);
      expect(c.isWeekly, isTrue);
      expect(c.canDelete, isFalse);
    });

    test('conflito a partir da ocorrência', () async {
      final plan = FakeWeekPlanRepository(
        weeks: {
          '2026-11-23': [block(DateTime(2026, 11, 26), 19, 0, 30)],
        },
      );
      final c = make(
        repo: FakeCommitmentsRepository(commitment: sampleCommitment()),
        plan: plan,
        id: 'violao',
        args: const CommitmentFormArgs(
          scope: CommitmentScope.following,
          occurrenceDate: '2026-11-24',
        ),
      );
      await c.load();
      expect(plan.requested, ['2026-11-23', '2026-11-30']);
      expect(
        c.conflictTitle,
        'Bate com "Implementar Merge Sort" (26/11 · 19h)',
      );
    });

    test('salva com update scope following e fromDate', () async {
      final repo = FakeCommitmentsRepository(commitment: sampleCommitment());
      final c = following(repo);
      await c.load();
      c.setEnd(1230);
      final t = await c.save();
      final ch = repo.change!;
      expect(ch.scope, CommitmentScope.following);
      expect(ch.fromDate, '2026-11-24');
      expect(ch.title, 'Aula de violão');
      expect(ch.endMinute, 1230);
      expect(ch.recurrence!.weekdays, [1, 3]);
      expect(t!.title, 'Mudança salva');
      expect(t.subtitle, 'Vale a partir de 24/11.');
    });
  });

  group('só nesse dia', () {
    CommitmentFormController only(FakeCommitmentsRepository repo) => make(
      repo: repo,
      id: 'violao',
      args: const CommitmentFormArgs(occurrenceDate: '2026-11-24'),
    );

    test('nome fixo, sem Tipo/Repete, data e horário da ocorrência', () async {
      final c = only(FakeCommitmentsRepository(commitment: sampleCommitment()));
      await c.load();
      expect(c.mode, CommitmentFormMode.editOnly);
      expect(
        c.subtitle,
        'Mudando só Ter, 24/11/2026. As outras semanas continuam iguais.',
      );
      expect(c.saveLabel, 'Salvar só nesse dia');
      expect(c.showName, isFalse);
      expect(c.showFixedName, isTrue);
      expect(c.showRepeat, isFalse);
      expect(c.isWeekly, isFalse);
      expect(c.title, 'Aula de violão');
      expect(c.date, DateTime(2026, 11, 24));
      expect(c.startMinute, 1140);
      expect(c.endMinute, 1200);
      expect(c.canDelete, isFalse);
    });

    test('dia já movido: a nova data e o novo horário', () async {
      final c = only(
        FakeCommitmentsRepository(
          commitment: sampleCommitment(
            exceptions: const [
              CommitmentException(
                date: '2026-11-24',
                type: CommitmentExceptionType.moved,
                newDate: '2026-11-25',
                startMinute: 1200,
                endMinute: 1260,
              ),
            ],
          ),
        ),
      );
      await c.load();
      expect(c.date, DateTime(2026, 11, 25));
      expect(c.startMinute, 1200);
      expect(c.endMinute, 1260);
    });

    test('salva com setOccurrence move', () async {
      final repo = FakeCommitmentsRepository(commitment: sampleCommitment());
      final c = only(repo);
      await c.load();
      await c.setDate(DateTime(2026, 11, 26));
      c
        ..setStart(1080)
        ..setEnd(1140);
      final t = await c.save();
      expect(repo.calls.last, 'setOccurrence:violao');
      expect(repo.occurrenceDate, '2026-11-24');
      final o = repo.occurrence!;
      expect(o.status, OccurrenceStatus.moved);
      expect(o.newDate, '2026-11-26');
      expect(o.startMinute, 1080);
      expect(o.endMinute, 1140);
      expect(t!.title, 'Só esse dia mudou');
      expect(t.subtitle, 'As outras semanas continuam iguais.');
    });
  });
}
