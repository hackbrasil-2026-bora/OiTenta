import '../../../core/http/api_client.dart';
import '../domain/commitment.dart';
import 'commitments_repository.dart';

/// Compromissos no backend real (contrato §5b). Esqueleto do passo 0.6:
/// o subagente M1 implementa cada método com testes.
class HttpCommitmentsRepository implements CommitmentsRepository {
  HttpCommitmentsRepository(this.api);

  final ApiClient api;

  @override
  Future<Commitment> create(NewCommitment commitment) =>
      throw UnimplementedError();

  @override
  Future<Commitment> get(String id) => throw UnimplementedError();

  @override
  Future<List<CommitmentOccurrence>> listOccurrences(String from, String to) =>
      throw UnimplementedError();

  @override
  Future<Commitment> update(String id, CommitmentChange change) =>
      throw UnimplementedError();

  @override
  Future<void> delete(
    String id, {
    required CommitmentScope scope,
    String? fromDate,
  }) => throw UnimplementedError();

  @override
  Future<Commitment> setOccurrence(
    String id,
    String date,
    OccurrenceChange change,
  ) => throw UnimplementedError();

  @override
  Future<Commitment> clearOccurrence(String id, String date) =>
      throw UnimplementedError();
}
