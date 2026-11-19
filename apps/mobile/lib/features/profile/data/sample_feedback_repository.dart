import 'feedback_repository.dart';

/// Guarda as sugestões só em memória (MP9): nada vai ao backend.
class SampleFeedbackRepository implements FeedbackRepository {
  final List<String> sent = [];

  @override
  Future<void> send(String message) async => sent.add(message);
}
