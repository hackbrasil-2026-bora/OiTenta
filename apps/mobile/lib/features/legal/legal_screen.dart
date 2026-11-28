import 'package:flutter/material.dart';

import '../../core/theme/bora_colors.dart';
import '../../core/theme/bora_text.dart';
import '../../core/widgets/bora_scaffold.dart';
import 'legal_texts.dart';

/// Termos de uso e Política de privacidade (28/11/2026). **Sem design**:
/// texto corrido no `BoraPage`, com o aviso de versão preliminar.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc, required this.onBack});

  final LegalDocument doc;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    final body = BoraText.nunito(16, 24, weight: FontWeight.w400, color: c.tx);
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: onBack)),
      children: [
        Text(
          'Atualizado em ${doc.updated}'.toUpperCase(),
          style: BoraText.label(c.tx2),
        ),
        const SizedBox(height: 4),
        Text(doc.title, style: BoraText.h1(c.tx)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.bgSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Text(
            legalDraftNotice,
            style: BoraText.nunito(
              14,
              20,
              weight: FontWeight.w700,
              color: c.tx2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(doc.intro, style: body),
        for (final s in doc.sections) ...[
          const SizedBox(height: 20),
          Text(s.heading, style: BoraText.h3(c.tx)),
          for (final p in s.paragraphs) ...[
            const SizedBox(height: 8),
            Text(p, style: body),
          ],
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Liga a [LegalScreen] à navegação: volta para onde estava.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.doc, required this.onBack});

  final LegalDocument doc;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LegalScreen(doc: doc, onBack: onBack);
}
