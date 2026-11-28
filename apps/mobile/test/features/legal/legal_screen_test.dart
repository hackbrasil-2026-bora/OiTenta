import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/legal/legal_screen.dart';
import 'package:oitenta/features/legal/legal_texts.dart';

import '../../helpers/test_app.dart';

/// Termos de uso e Política de privacidade (28/11/2026).
void main() {
  for (final doc in [termsOfUse, privacyPolicy]) {
    testWidgets('${doc.title}: título, rascunho, seções e contato', (
      tester,
    ) async {
      await usePhoneSize(tester);
      await tester.pumpWidget(themed(LegalScreen(doc: doc, onBack: () {})));

      expect(find.text(doc.title), findsOneWidget);
      expect(find.text(legalDraftNotice), findsOneWidget);
      expect(
        find.text('Atualizado em ${doc.updated}'.toUpperCase()),
        findsOneWidget,
      );
      for (final s in doc.sections) {
        await tester.scrollUntilVisible(find.text(s.heading), 200);
        expect(find.text(s.heading), findsOneWidget);
      }
    });
  }

  test('o texto do app é o mesmo do site (gerado)', () {
    expect(legalContact, 'contato@bora.app');
    expect(termsOfUse.sections, hasLength(9));
    expect(privacyPolicy.sections, hasLength(10));
    expect(
      privacyPolicy.sections.expand((s) => s.paragraphs).join(' '),
      contains('apagamos de vez a conta e todos os dados dela'),
    );
  });
}
