#!/usr/bin/env bash
# Gera apps/mobile/lib/features/legal/legal_texts.dart a partir do texto do site
# (apps/frontend/src/modules/legal/data/legal-texts.ts), para o app e o site
# dizerem a mesma coisa. Rode da raiz do repositório:
#
#   bash apps/mobile/tool/legal/generate_legal_texts.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
JSON="$(mktemp)"
trap 'rm -f "$JSON"' EXIT
(cd "$ROOT/apps/frontend" && npx tsx -e 'import * as L from "./src/modules/legal/data/legal-texts.ts"; console.log(JSON.stringify(L))') > "$JSON"
python3 "$ROOT/apps/mobile/tool/legal/to_dart.py" "$JSON" "$ROOT/apps/mobile/lib/features/legal/legal_texts.dart"
(cd "$ROOT/apps/mobile" && dart format lib/features/legal/legal_texts.dart)
