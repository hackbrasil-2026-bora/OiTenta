"""Converte o JSON dos textos legais (gerado do site) em legal_texts.dart."""
import json
import sys


def q(t):
    return "'" + t.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$") + "'"


def doc(name, d):
    out = [f"const {name} = LegalDocument(", f"  title: {q(d['title'])},", "  updated: legalUpdated,",
           f"  intro: {q(d['intro'])},", "  sections: ["]
    for s in d["sections"]:
        out += ["    LegalSection(", f"      heading: {q(s['heading'])},", "      paragraphs: ["]
        out += [f"        {q(p)}," for p in s["paragraphs"]]
        out += ["      ],", "    ),"]
    out += ["  ],", ");"]
    return "\n".join(out)


L = json.load(open(sys.argv[1]))
src = f"""// Termos de uso e Política de privacidade (decisão do dono do produto, 28/11/2026).
// VERSÃO PRELIMINAR: precisa de revisão do time (e, de preferência, jurídica) antes do lançamento.
// GERADO por apps/mobile/tool/legal/generate_legal_texts.sh a partir de
// apps/frontend/src/modules/legal/data/legal-texts.ts. Não edite aqui: mude lá e gere de novo.

/// Uma seção dos textos legais.
class LegalSection {{
  const LegalSection({{required this.heading, required this.paragraphs}});

  final String heading;
  final List<String> paragraphs;
}}

/// Um texto legal (Termos de uso ou Política de privacidade).
class LegalDocument {{
  const LegalDocument({{
    required this.title,
    required this.updated,
    required this.intro,
    required this.sections,
  }});

  final String title;
  final String updated;
  final String intro;
  final List<LegalSection> sections;
}}

const legalContact = {q(L['LEGAL_CONTACT'])};
const legalUpdated = {q(L['LEGAL_UPDATED'])};
const legalDraftNotice = {q(L['LEGAL_DRAFT_NOTICE'])};

{doc('termsOfUse', L['TERMS'])}

{doc('privacyPolicy', L['PRIVACY'])}
"""
open(sys.argv[2], "w").write(src)
