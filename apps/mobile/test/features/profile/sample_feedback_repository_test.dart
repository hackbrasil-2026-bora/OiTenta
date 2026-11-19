import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/profile/data/feedback_repository.dart';
import 'package:oitenta/features/profile/data/sample_feedback_repository.dart';

void main() {
  test('é um FeedbackRepository e começa sem mensagens', () {
    final repo = SampleFeedbackRepository();
    expect(repo, isA<FeedbackRepository>());
    expect(repo.sent, isEmpty);
  });

  test('guarda as mensagens em memória, na ordem (MP9)', () async {
    final repo = SampleFeedbackRepository();
    await repo.send('Queria tema roxo');
    await repo.send('O Broto é fofo');
    expect(repo.sent, ['Queria tema roxo', 'O Broto é fofo']);
  });
}
