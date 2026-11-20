import '../domain/commitment.dart';

/// Compromissos (contrato §5b). Toda mutação recalcula o plano no backend.
abstract class CommitmentsRepository {
  /// `POST /scheduling/commitments`.
  Future<Commitment> create(NewCommitment commitment);

  /// `GET /scheduling/commitments/:id`.
  Future<Commitment> get(String id);

  /// `GET /scheduling/commitments/occurrences?from&to` (datas locais).
  Future<List<CommitmentOccurrence>> listOccurrences(String from, String to);

  /// `PATCH /scheduling/commitments/:id` ("Todas as semanas" ou "Desse dia em
  /// diante"; neste caso devolve a série nova).
  Future<Commitment> update(String id, CommitmentChange change);

  /// `DELETE /scheduling/commitments/:id?scope&fromDate`.
  Future<void> delete(
    String id, {
    required CommitmentScope scope,
    String? fromDate,
  });

  /// `PUT /scheduling/commitments/:id/occurrences/:date` ("Só nesse dia").
  Future<Commitment> setOccurrence(
    String id,
    String date,
    OccurrenceChange change,
  );

  /// `DELETE /scheduling/commitments/:id/occurrences/:date` ("Vai ter sim",
  /// "Voltar pro horário normal").
  Future<Commitment> clearOccurrence(String id, String date);
}
