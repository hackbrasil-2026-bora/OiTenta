import 'dart:async';

import 'package:oitenta/features/profile/data/feedback_repository.dart';

/// Repositório falso de sugestões: grava o que recebeu, pode falhar ou
/// segurar a resposta até o teste liberar ([gate]).
class FakeFeedbackRepository implements FeedbackRepository {
  final List<String> sent = [];
  Object? error;
  Completer<void>? gate;

  @override
  Future<void> send(String message) async {
    sent.add(message);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }
}
