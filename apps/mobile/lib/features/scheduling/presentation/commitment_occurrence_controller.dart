import 'package:flutter/foundation.dart';

import '../../../core/format/bora_format.dart';
import '../data/commitments_repository.dart';
import '../domain/commitment.dart';
import 'commitment_occurrence_view.dart';

/// Ações do menu do sheet (`ocAcoes` do protótipo).
enum OccurrenceActionKind { edit, skip, restore, delete }

class OccurrenceActionView {
  const OccurrenceActionView(this.kind, this.name, this.description);

  final OccurrenceActionKind kind;
  final String name;
  final String description;
}

/// Escopo da edição/exclusão da série (`ocEscopos`).
enum OccurrenceScopeChoice { day, following, all }

class OccurrenceScopeView {
  const OccurrenceScopeView({
    required this.choice,
    required this.name,
    required this.description,
    required this.selected,
  });

  final OccurrenceScopeChoice choice;
  final String name;
  final String description;
  final bool selected;
}

/// Ícone do toast (a tela escolhe o Phosphor).
enum OccurrenceToastKind { freed, back, restored, deleted, ended }

class OccurrenceToast {
  const OccurrenceToast(this.kind, this.title, this.subtitle);

  final OccurrenceToastKind kind;
  final String title;
  final String subtitle;
}

/// Abrir o formulário de edição (M46/M52) com o escopo escolhido.
class OccurrenceEditRequest {
  const OccurrenceEditRequest({
    required this.commitmentId,
    required this.scope,
    required this.occurrenceDate,
  });

  final String commitmentId;

  /// `null` com [occurrenceDate] = "Só nesse dia".
  final CommitmentScope? scope;
  final String? occurrenceDate;
}

/// O que o sheet devolve ao fechar: um toast (e a tela recarrega) ou o
/// pedido de abrir o formulário.
class OccurrenceOutcome {
  const OccurrenceOutcome.toast(OccurrenceToast this.toast) : edit = null;

  const OccurrenceOutcome.edit(OccurrenceEditRequest this.edit) : toast = null;

  final OccurrenceToast? toast;
  final OccurrenceEditRequest? edit;
}

/// Sheet da ocorrência tocada na Semana ou no Hoje (`sheetCpOcc`).
class CommitmentOccurrenceController extends ChangeNotifier {
  CommitmentOccurrenceController(this._repo, this.occurrence);

  final CommitmentsRepository _repo;
  final CommitmentOccurrence occurrence;

  bool busy = false;
  String? error;
  bool scopeStep = false;
  OccurrenceActionKind? _pending;
  OccurrenceScopeChoice scope = OccurrenceScopeChoice.day;

  /// A série, buscada só no dia movido (para o horário normal).
  Commitment? _series;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (!occurrence.isMoved) return;
    try {
      _series = await _repo.get(occurrence.commitmentId);
    } catch (_) {
      _series = null;
    }
    _notify();
  }

  // --- Cabeçalho ------------------------------------------------------------

  String get title => occurrence.title;

  CommitmentCategory get category => occurrence.category;

  bool get isRecurring => occurrence.isRecurring;

  bool get isCancelled => occurrence.isCancelled;

  String get repetition => commitmentRepetitionLabel(occurrence.recurrence);

  static String _date(String key) =>
      BoraFormat.fullDate(BoraFormat.parseDateKey(key));

  static String _ddmm(String key) =>
      BoraFormat.dayMonth(BoraFormat.parseDateKey(key));

  /// `Ter, 11/11/2025 · 19:00–20:00`.
  String get whenLabel =>
      '${_date(occurrence.date)} · '
      '${commitmentClock(occurrence.startMinute)}–'
      '${commitmentClock(occurrence.endMinute)}';

  /// Horário normal da série (`13:00–15:30`), quando conhecido.
  String? get _normalHours {
    final s = _series;
    if (s == null) return null;
    return '${commitmentClock(s.startMinute)}–${commitmentClock(s.endMinute)}';
  }

  String? get statusLabel {
    if (occurrence.isCancelled) return 'Não vai ter nesse dia';
    if (!occurrence.isMoved) return null;
    final normal = _normalHours;
    return normal == null
        ? 'Horário alterado'
        : 'Horário alterado · normal é $normal';
  }

  // --- Menu -----------------------------------------------------------------

  List<OccurrenceActionView> get actions {
    if (scopeStep || isCancelled) return const [];
    final rec = isRecurring;
    final normal = _normalHours;
    return [
      OccurrenceActionView(
        OccurrenceActionKind.edit,
        'Editar',
        rec ? 'Horário, nome ou dias' : 'Data, horário ou nome',
      ),
      if (rec && !occurrence.isMoved)
        const OccurrenceActionView(
          OccurrenceActionKind.skip,
          'Não vai ter nesse dia',
          'Libero esse horário só dessa vez',
        ),
      if (occurrence.isMoved)
        OccurrenceActionView(
          OccurrenceActionKind.restore,
          'Voltar pro horário normal',
          normal == null
              ? 'Como nas outras semanas'
              : '$normal, como nas outras semanas',
        ),
      OccurrenceActionView(
        OccurrenceActionKind.delete,
        'Excluir',
        rec
            ? 'Tirar da agenda: um dia, daqui pra frente ou tudo'
            : 'Tirar da sua agenda',
      ),
    ];
  }

  Future<OccurrenceOutcome?> pick(OccurrenceActionKind kind) async {
    if (busy) return null;
    switch (kind) {
      case OccurrenceActionKind.skip:
        return _cancelDay();
      case OccurrenceActionKind.restore:
        final normal = _normalHours;
        return _run(
          () => _repo.clearOccurrence(
            occurrence.commitmentId,
            occurrence.originalDate,
          ),
          OccurrenceToast(
            OccurrenceToastKind.restored,
            'Horário normal de volta',
            normal == null
                ? 'Esse dia segue o horário de sempre.'
                : '$normal nesse dia.',
          ),
        );
      case OccurrenceActionKind.edit || OccurrenceActionKind.delete
          when !isRecurring:
        if (kind == OccurrenceActionKind.edit) {
          return OccurrenceOutcome.edit(
            OccurrenceEditRequest(
              commitmentId: occurrence.commitmentId,
              scope: CommitmentScope.all,
              occurrenceDate: null,
            ),
          );
        }
        return _deleteAll('Liberei esse horário pro seu plano.');
      case OccurrenceActionKind.edit || OccurrenceActionKind.delete:
        _pending = kind;
        scope = OccurrenceScopeChoice.day;
        scopeStep = true;
        _notify();
        return null;
    }
  }

  /// "Vai ter sim" (dia cancelado).
  Future<OccurrenceOutcome?> keep() async {
    if (busy) return null;
    return _run(
      () => _repo.clearOccurrence(
        occurrence.commitmentId,
        occurrence.originalDate,
      ),
      const OccurrenceToast(
        OccurrenceToastKind.back,
        'Voltou pra agenda',
        'Esse dia segue o horário de sempre.',
      ),
    );
  }

  // --- Passo de escopo ------------------------------------------------------

  bool get isDeleteStep => _pending == OccurrenceActionKind.delete;

  String get scopeTitle => isDeleteStep ? 'Excluir qual?' : 'Editar qual?';

  List<OccurrenceScopeView> get scopes {
    final d = occurrence.originalDate;
    OccurrenceScopeView view(OccurrenceScopeChoice c, String n, String desc) =>
        OccurrenceScopeView(
          choice: c,
          name: n,
          description: desc,
          selected: scope == c,
        );
    return [
      view(OccurrenceScopeChoice.day, 'Só nesse dia', _date(d)),
      view(
        OccurrenceScopeChoice.following,
        'Desse dia em diante',
        'A partir de ${_ddmm(d)}. Antes fica como era.',
      ),
      view(OccurrenceScopeChoice.all, 'Todas as semanas', 'A série inteira'),
    ];
  }

  void selectScope(OccurrenceScopeChoice choice) {
    scope = choice;
    _notify();
  }

  /// "Voltar": volta ao menu.
  void back() {
    scopeStep = false;
    _pending = null;
    _notify();
  }

  /// "Continuar" (editar) ou "Excluir".
  Future<OccurrenceOutcome?> confirm() async {
    if (busy) return null;
    final date = occurrence.originalDate;
    if (!isDeleteStep) {
      return OccurrenceOutcome.edit(
        OccurrenceEditRequest(
          commitmentId: occurrence.commitmentId,
          scope: switch (scope) {
            OccurrenceScopeChoice.day => null,
            OccurrenceScopeChoice.following => CommitmentScope.following,
            OccurrenceScopeChoice.all => CommitmentScope.all,
          },
          occurrenceDate: date,
        ),
      );
    }
    switch (scope) {
      case OccurrenceScopeChoice.day:
        return _cancelDay();
      case OccurrenceScopeChoice.following:
        final last = BoraFormat.parseDateKey(
          date,
        ).subtract(const Duration(days: 1));
        return _run(
          () => _repo.delete(
            occurrence.commitmentId,
            scope: CommitmentScope.following,
            fromDate: date,
          ),
          OccurrenceToast(
            OccurrenceToastKind.ended,
            'Encerrado',
            'O último foi em ${BoraFormat.dayMonth(last)}.',
          ),
        );
      case OccurrenceScopeChoice.all:
        return _deleteAll('Liberei esses horários pro seu plano.');
    }
  }

  // --- Chamadas -------------------------------------------------------------

  Future<OccurrenceOutcome?> _cancelDay() => _run(
    () => _repo.setOccurrence(
      occurrence.commitmentId,
      occurrence.originalDate,
      const OccurrenceChange.cancel(),
    ),
    const OccurrenceToast(
      OccurrenceToastKind.freed,
      'Horário liberado',
      'Só nesse dia. Posso encaixar etapas aí.',
    ),
  );

  Future<OccurrenceOutcome?> _deleteAll(String subtitle) => _run(
    () => _repo.delete(occurrence.commitmentId, scope: CommitmentScope.all),
    OccurrenceToast(
      OccurrenceToastKind.deleted,
      'Compromisso excluído',
      subtitle,
    ),
  );

  Future<OccurrenceOutcome?> _run(
    Future<void> Function() call,
    OccurrenceToast toast,
  ) async {
    busy = true;
    error = null;
    _notify();
    try {
      await call();
      return OccurrenceOutcome.toast(toast);
    } catch (_) {
      error = 'Não deu pra salvar agora. Tenta de novo.';
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }
}
