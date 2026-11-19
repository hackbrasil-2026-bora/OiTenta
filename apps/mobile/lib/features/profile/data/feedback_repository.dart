/// Sugestão do usuário (M29). Sem endpoint nesta fase (MP9): só existe a
/// implementação de exemplo.
abstract class FeedbackRepository {
  Future<void> send(String message);
}
