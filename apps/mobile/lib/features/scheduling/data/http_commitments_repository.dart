import '../../../core/http/api_client.dart';
import '../domain/commitment.dart';
import 'commitments_repository.dart';

/// Compromissos no backend real (contrato §5b). Os erros 400/401/404/422 já
/// chegam convertidos pelo [ApiClient] (`app_errors.dart`).
class HttpCommitmentsRepository implements CommitmentsRepository {
  HttpCommitmentsRepository(this.api);

  final ApiClient api;

  static const _base = '/scheduling/commitments';

  static String _one(String id) => '$_base/${Uri.encodeComponent(id)}';

  static String _occurrence(String id, String date) =>
      '${_one(id)}/occurrences/${Uri.encodeComponent(date)}';

  static Commitment _read(dynamic json) => Commitment.fromJson(
    (json as Map<String, dynamic>)['commitment'] as Map<String, dynamic>,
  );

  @override
  Future<Commitment> create(NewCommitment commitment) async =>
      _read(await api.post(_base, body: commitment.toJson()));

  @override
  Future<Commitment> get(String id) async => _read(await api.get(_one(id)));

  @override
  Future<List<CommitmentOccurrence>> listOccurrences(
    String from,
    String to,
  ) async {
    final json =
        await api.get('$_base/occurrences', query: {'from': from, 'to': to})
            as Map<String, dynamic>;
    return [
      for (final o in json['occurrences'] as List)
        CommitmentOccurrence.fromJson(o as Map<String, dynamic>),
    ];
  }

  @override
  Future<Commitment> update(String id, CommitmentChange change) async =>
      _read(await api.patch(_one(id), body: change.toJson()));

  @override
  Future<void> delete(
    String id, {
    required CommitmentScope scope,
    String? fromDate,
  }) async {
    await api.delete(
      _one(id),
      query: {'scope': scope.name, 'fromDate': ?fromDate},
    );
  }

  @override
  Future<Commitment> setOccurrence(
    String id,
    String date,
    OccurrenceChange change,
  ) async => _read(await api.put(_occurrence(id, date), body: change.toJson()));

  @override
  Future<Commitment> clearOccurrence(String id, String date) async =>
      _read(await api.delete(_occurrence(id, date)));
}
