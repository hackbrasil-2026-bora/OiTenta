# Avaliação do assistente do novo objetivo (`ai:eval`)

**Última rodada:** 16/11/2026 (segunda), com o Ollama local e modelos instalados. A rodada de 12/11 (Ollama sem modelo) está no fim da página.
**Como foi gerado:** `npm --workspace apps/backend run ai:eval` (tarefa 10 da `docs/7-proposta-ia.md` §g), com os 10 textos de referência do script `apps/backend/scripts/ai-eval.ts`, fuso `America/Sao_Paulo`, hoje = 16/11/2026, reserva `rules` (`AI_FALLBACK`). O orçamento é de 15 s (`AI_TIMEOUT_MS`), salvo onde a tabela diz outro valor.
**Máquina:** Mac com Apple M4 Pro e 48 GB de RAM, Ollama 0.40.16 (Homebrew, serviço `brew services`, `OLLAMA_KEEP_ALIVE=24h`). Velocidade de geração: `qwen2.5:3b` 38,6 tokens/s e `qwen2.5:7b` 18,9 tokens/s num teste curto pela API nativa; nas chamadas reais do `suggestSteps`, o 7b ficou em cerca de 20–21,5 tokens/s (ex.: 301 tokens em 14,0 s).

---

## Resumo comparativo (16/11/2026)

| Motor | Respostas do LLM (10 textos, 15 s) | Rascunho com o modelo carregado | Primeiro rascunho (frio) | Qualidade | Situação |
|---|---|---|---|---|---|
| **Motor de regras** (`rules`) | — (não é LLM) | 0–2 ms | 0–2 ms | Prazo certo nos 8 textos com data; etapas genéricas, um modelo por categoria; o título leva a expressão de data (5 de 10) | padrão do projeto |
| **Ollama `qwen2.5:3b`** | **7 de 10**; 3 caem nas regras por tempo (no texto 2, por repetição) | 5,6–9,0 s no texto 1 (5 chamadas); 5,8–12,2 s nos 7 textos do `ai:eval` | 9,7 s | Etapas mais específicas que as regras, mas fracas: título vazio em 4 de 7, um prazo errado ("dia 30" → 30/12), etapas inventadas ("mecânica", "elétrica") e totais de até 11,5 h | **em uso provisório** no `.env` local |
| **Ollama `qwen2.5:7b`** | **0 de 10**: todas passam de 15 s | 17,3–21,1 s no texto 1 (5 chamadas seguidas); 12,1–16,6 s no `ai:eval` com 120 s | 21,9 s | Com o orçamento aberto (120 s), 10 de 10: etapas específicas e úteis (cita QuickSort, MergeSort e BubbleSort; separa derivadas e limites), totais de 3,2 a 7 h; um prazo errado ("sexta" → 17/11) e uma etapa em inglês | **não cabe nos 15 s** |

**O que dá para afirmar hoje:**
1. **A IA real responde de ponta a ponta.** Com o `qwen2.5:3b`, o `POST /goals/assistant/draft` devolve `engine: "llm"` e o log mostra `outcome=ok` nas duas chamadas (seção "Prova da IA real").
2. **Nenhum dos dois modelos locais atende ao mesmo tempo ao orçamento e à qualidade.** O 7b escreve bem, mas leva de 12 a 21 s (passa de 15 s na maioria das medições e em todas as do orçamento de 15 s). O 3b cabe nos 15 s, mas erra mais e, em alguns textos, repete etapas sem parar até o orçamento estourar. A escolha está no [DECIDIR] "Modelo local do Ollama" do `afazeres.md`.
3. **A reserva funciona com um LLM de verdade.** Nos textos em que o modelo estoura o orçamento, o rascunho sai das regras em 15 s, com `engine: "rules"`. O tempo limite não foi aumentado e a validação não foi afrouxada.
4. **O Ollama aceita `response_format: {type: "json_object"}` e devolve `usage`** com `prompt_tokens` e `completion_tokens`. Nenhuma resposta foi recusada pela validação; as falhas foram só de tempo.
5. **Prazo relativo é o ponto fraco dos LLMs:** o 7b leu "sexta" como 17/11 e o 3b leu "dia 30" como 30/12. O motor de regras acertou os dois.

**Para decidir:** o modelo local (ou o fornecedor hospedado, IA6) e o tratamento do prazo relativo ([DECIDIR] no `afazeres.md`).

---

## Tempo de resposta (texto de referência 1, as duas chamadas)

Medido pelo `GoalDraftRunner` com o adaptador real, orçamento aberto só na medição (para ver o tempo bruto). "Frio" é logo depois de `ollama stop <modelo>`. As 5 chamadas do 7b foram seguidas, logo depois da fria; no `ai:eval` de 120 s, mais tarde, o mesmo texto 1 levou 16,2 s. A diferença entre as rodadas (17–21 s contra 12–17 s) não foi investigada; os dois números ficam registrados.

| Modelo | Frio | Carregado, 5 chamadas seguidas | `parseGoal` (carregado) | `suggestSteps` (carregado) | Tokens gerados no `suggestSteps` |
|---|---|---|---|---|---|
| `qwen2.5:3b` | 9.696 ms | 6.451 · 6.509 · 5.619 · 7.327 · 9.037 ms | 1,3–1,5 s | 4,1–7,7 s | 154–274 |
| `qwen2.5:7b` | 21.891 ms | 17.275 · 18.468 · 19.222 · 19.425 · 21.087 ms | 2,3–3,3 s | 14,0–18,5 s | 301–367 |

O `keep_alive` de 24 h no serviço mantém o modelo carregado; o aquecimento (`docs/backend/COMO-TESTAR.md`, passo 6a) carrega o modelo em cerca de 1 s antes do primeiro rascunho.

## A repetição sem fim do `qwen2.5:3b`

No texto 2 ("Prova de Cálculo 1 na sexta, cai derivadas e limites"), o `suggestSteps` não terminou em 3 de 4 tentativas, nem com 120 s. Inspecionado direto no Ollama com o prompt `suggest-steps@v1` e um teto de 700 tokens (só na inspeção):

- 1 de 3: JSON válido em 6,8 s (259 tokens, `finish_reason: stop`);
- 2 de 3: `finish_reason: length` (bateu o teto), JSON cortado. O modelo repete a mesma etapa com variações, por exemplo `{"title": "Estudar respostas", "estimatedMinutes": 30, "microSteps": ["Estudar respostas da prova anterior", "Estudar respostas da prova do colega"]}` várias vezes seguidas, ou "Estudar resoluções de provas anteriores, exercícios anteriores e revisar conceitos novamente", cada vez mais longa.

O `qwen2.5:7b` no mesmo texto: 3 de 3 com JSON válido e `finish_reason: stop` (274–288 tokens), em 13,6–13,8 s só no `suggestSteps`.

## Prova da IA real (`POST /goals/assistant/draft`, 16/11/2026)

Backend com o `apps/backend/.env` local (`AI_PROVIDER=openai-compatible`, `AI_MODEL=qwen2.5:3b`, `AI_TIMEOUT_MS=15000`, `AI_FALLBACK=rules`, `AI_LOG_CONTENT=false`), login demo e 3 textos:

| Texto | HTTP | Tempo | `engine` | Rascunho |
|---|---|---|---|---|
| Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação, entrega 24/11 | 200 | 8,4 s | **llm** | "Trabalho de Algoritmos", 24/11, `assignment`, requisitos "implementar; comparar; ordenar; entregar", 6 etapas, 480 min |
| Prova de Cálculo 1 na sexta, cai derivadas e limites | 200 | 15,0 s | rules (reserva) | `suggestSteps` estourou o orçamento (repetição acima) |
| Montar meu portfólio no GitHub com 3 projetos | 200 | 9,5 s | **llm** | "Montar portfólio", sem prazo (`missingFields: ["deadline"]`), requisito "3 projetos", 8 etapas, 1.080 min |

Log do backend (sem a chave e sem o texto do usuário):

```
assistant op=parseGoal provider=openai-compatible model=qwen2.5:3b prompt=parse-goal@v1 ms=2660 outcome=ok tokens_in=429 tokens_out=54
assistant op=suggestSteps provider=openai-compatible model=qwen2.5:3b prompt=suggest-steps@v1 ms=5750 outcome=ok tokens_in=434 tokens_out=215
assistant op=parseGoal provider=openai-compatible model=qwen2.5:3b prompt=parse-goal@v1 ms=1110 outcome=ok tokens_in=419 tokens_out=46
assistant op=draft provider=openai-compatible model=qwen2.5:3b ms=15003 outcome=assistant.timeout fallback=rules
assistant op=suggestSteps provider=openai-compatible model=qwen2.5:3b prompt=suggest-steps@v1 ms=15003 outcome=timeout tokens_in=- tokens_out=- error="The operation was aborted due to timeout"
assistant op=parseGoal provider=openai-compatible model=qwen2.5:3b prompt=parse-goal@v1 ms=1770 outcome=ok tokens_in=414 tokens_out=31
assistant op=suggestSteps provider=openai-compatible model=qwen2.5:3b prompt=suggest-steps@v1 ms=7696 outcome=ok tokens_in=400 tokens_out=333
```

## `response_format` e `usage` no Ollama (fecha o [INVESTIGAR])

`curl http://localhost:11434/v1/chat/completions` com `response_format: {"type":"json_object"}` e o `qwen2.5:7b`: conteúdo `{"title": "Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação", "deadline": "2026-11-24"}` (JSON válido, sem cercas de markdown), `finish_reason: stop` e `usage: {"prompt_tokens": 82, "completion_tokens": 46, "total_tokens": 128, ...}`. O adaptador lê exatamente `usage.prompt_tokens` e `usage.completion_tokens`: nas chamadas reais, o log mostra `tokens_in` e `tokens_out` preenchidos. Nenhum ajuste no adaptador foi necessário.

---

## (a) Motor de regras, 16/11/2026

| # | Texto | Título | Prazo | Categoria | Etapas | Total (min) | Tempo (ms) | Reserva | Qualidade |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação, entrega 24/11 | Trabalho de Algoritmos | 2026-11-24 | assignment | 5 | 300 | 2 | não | Boa: igual a 12/11 |
| 2 | Prova de Cálculo 1 na sexta, cai derivadas e limites | Prova de Cálculo 1 na sexta | 2026-11-20 | exam | 5 | 300 | 1 | não | Média: prazo certo (sexta, 20/11); título leva "na sexta" |
| 3 | TCC: entregar a primeira versão do capítulo 2 até 3 de dezembro | TCC | 2026-12-03 | project | 5 | 300 | 0 | não | Fraca: igual a 12/11 |
| 4 | Lista de exercícios de Física para amanhã | Lista de exercícios de Física para amanhã | 2026-11-17 | assignment | 5 | 300 | 0 | não | Fraca: igual a 12/11 |
| 5 | Montar meu portfólio no GitHub com 3 projetos | Montar meu portfólio no GitHub com 3 projetos | — | project | 5 | 300 | 1 | não | Média: igual a 12/11 |
| 6 | Apresentação do seminário de História em 10 dias | Apresentação do seminário de História em 10 dias | 2026-11-26 | generic | 4 | 180 | 0 | não | Média: prazo certo (16 + 10) |
| 7 | Estudar inglês para o simulado da semana que vem | Estudar inglês para o simulado da semana que vem | 2026-11-29 | exam | 5 | 300 | 0 | não | Média: igual a 12/11 |
| 8 | Relatório do estágio, entrega dia 30 | Relatório do estágio | 2026-11-30 | assignment | 5 | 300 | 0 | não | Boa: igual a 12/11 |
| 9 | Fazer um app de lista de compras em Flutter até o fim do mês | Fazer um app de lista de compras em Flutter até o fim do mês | 2026-11-30 | project | 5 | 300 | 1 | não | Média: igual a 12/11 |
| 10 | Organizar minhas anotações da faculdade | Organizar minhas anotações da faculdade | — | generic | 4 | 180 | 0 | não | Aceitável: igual a 12/11 |

As etapas são os 4 modelos fixos da rodada de 12/11 (tabela no fim da página).

## (b1) Ollama `qwen2.5:3b`, orçamento de 15 s

| # | Título | Prazo | Categoria | Etapas | Total (min) | Tempo (ms) | Engine | Reserva | Qualidade |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Trabalho de Algoritmos | 2026-11-24 | assignment | 4 | 240 | 5.791 | llm | não | Boa: título, prazo e requisitos certos; etapas específicas (escolher, implementar, comparar, entregar); micro-passos repetem a etapa |
| 2 | Prova de Cálculo 1 na sexta | 2026-11-20 | exam | 5 | 300 | 15.006 | rules | timeout | Reserva: o modelo repetiu etapas até estourar o orçamento |
| 3 | primeiro capítulo | 2026-12-03 | project | 8 | 690 | 11.583 | llm | não | Fraca: o título perdeu "TCC" e "capítulo 2"; "Escrever o primeiro parágrafo" com 120 min; 11,5 h no total |
| 4 | — | 2026-11-17 | assignment | 4 | 180 | 6.768 | llm | não | Fraca: título vazio; etapas inventam seções de "mecânica" e "elétrica" que o texto não cita |
| 5 | — | — | project | 6 | 360 | 7.040 | llm | não | Média: título vazio; etapas concretas de GitHub (repositório, README) |
| 6 | — | — | generic | 10 | 660 | 12.201 | llm | não | Fraca: título e prazo vazios ("em 10 dias" se perdeu); 10 etapas (o prompt pede 3 a 8), 11 h no total |
| 7 | Estudar inglês para o simulado da semana que vem | 2026-11-29 | exam | 5 | 300 | 15.002 | rules | timeout | Reserva |
| 8 | Relatório do estágio | 2026-12-30 | assignment | 5 | 630 | 7.980 | llm | não | Fraca: **prazo errado** ("dia 30" virou 30/12); "Escrever o primeiro parágrafo" com 180 min |
| 9 | Fazer um app de lista de compras em Flutter até o fim do mês | 2026-11-30 | project | 5 | 300 | 15.002 | rules | timeout | Reserva |
| 10 | — | — | generic | 7 | 330 | 9.725 | llm | não | Média: título vazio; etapas concretas |

Título vazio vira `missingFields: ["title"]` (IA2): o app abre a tela com o título em branco para o usuário preencher.

## (b2) Ollama `qwen2.5:7b`

Com o orçamento de 15 s, **os 10 textos caíram nas regras** (`assistant.timeout` em 15.002–15.036 ms; o rascunho é o da tabela (a)). Para medir a qualidade do modelo, o mesmo `ai:eval` foi rodado com `AI_TIMEOUT_MS=120000` **só na linha de comando** (o `.env` e o código continuam com 15 s):

| # | Título | Prazo | Categoria | Etapas | Total (min) | Tempo (ms) | Engine | Reserva | Qualidade |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Trabalho de Algoritmos | 2026-11-24 | assignment | 6 | 300 | 16.151 | llm | não | Ótima: escolhe QuickSort, MergeSort e BubbleSort, implementa cada um, compara e revisa |
| 2 | Prova de Cálculo 1 | 2026-11-17 | exam | 6 | 240 | 15.600 | llm | não | Boa nas etapas (definições, exercícios de derivadas e de limites, mistos); **prazo errado**: "sexta" virou 17/11 (terça) em vez de 20/11 |
| 3 | entregar a primeira versão do capítulo 2 do TCC | 2026-12-03 | project | 6 | 300 | 16.158 | llm | não | Boa: prazo certo; etapas de escrita e formatação adequadas |
| 4 | Lista de exercícios de Física | 2026-11-17 | assignment | 7 | 210 | 15.334 | llm | não | Média: título e prazo certos; etapas picadas demais ("Escolha o primeiro exercício", 15 min) |
| 5 | Montar portfólio no GitHub | — | project | 6 | 240 | 15.932 | llm | não | Boa: etapas concretas (repositórios, README de cada projeto) |
| 6 | Apresentação do seminário de História | 2026-11-26 | generic | 6 | 225 | 14.066 | llm | não | Boa: prazo certo; etapas próprias de seminário |
| 7 | Estudar inglês | 2026-11-23 | exam | 7 | 270 | 15.454 | llm | não | Boa: etapas de inglês (vocabulário, gramática, compreensão, escrita, simulado); o título perdeu "simulado"; prazo na segunda da semana que vem (as regras dão o domingo, 29/11) |
| 8 | Relatório do estágio | 2026-11-30 | assignment | 6 | 420 | 13.268 | llm | não | Boa |
| 9 | Fazer um app de lista de compras em Flutter | 2026-11-30 | project | 8 | 300 | 16.604 | llm | não | Boa, com um deslize: a etapa "Polish and refine" veio em inglês |
| 10 | Organizar anotações | — | generic | 5 | 195 | 12.086 | llm | não | Boa |

---

## Rodada de 12/11/2026 (Ollama sem modelo)

Hoje = 12/11/2026 (quinta): os prazos relativos ("sexta", "amanhã", "em 10 dias") contam a partir dessa data. A tabela de custo e privacidade dos fornecedores hospedados continua valendo como insumo da IA6.

### Resumo da rodada de 12/11 (para a reunião de sexta)

| Motor | Qualidade (10 textos) | Latência por rascunho | Custo | Privacidade | Situação |
|

### (a) Motor de regras (`AI_PROVIDER=rules`)

| # | Texto | Título | Prazo | Categoria | Etapas | Total (min) | Tempo (ms) | Reserva | Qualidade |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação, entrega 24/11 | Trabalho de Algoritmos | 2026-11-24 | assignment | 5 | 300 | 2 | não | Boa: título e prazo certos; etapas de trabalho fazem sentido, mas não citam os 3 algoritmos nem a comparação |
| 2 | Prova de Cálculo 1 na sexta, cai derivadas e limites | Prova de Cálculo 1 na sexta | 2026-11-13 | exam | 5 | 300 | 1 | não | Média: prazo e categoria certos; o título leva "na sexta"; etapas de prova coerentes, sem citar derivadas e limites |
| 3 | TCC: entregar a primeira versão do capítulo 2 até 3 de dezembro | TCC | 2026-12-03 | project | 5 | 300 | 0 | não | Fraca: título curto demais ("TCC", cortado no ":"); o modelo de projeto ("Montar a estrutura", "Publicar") não serve para escrever um capítulo |
| 4 | Lista de exercícios de Física para amanhã | Lista de exercícios de Física para amanhã | 2026-11-13 | assignment | 5 | 300 | 0 | não | Fraca: o título leva "para amanhã"; 5 h de etapas de trabalho escrito ("Pesquisar material", "Formatar e enviar") para uma lista de exercícios |
| 5 | Montar meu portfólio no GitHub com 3 projetos | Montar meu portfólio no GitHub com 3 projetos | — | project | 5 | 300 | 0 | não | Média: sem data no texto, prazo vazio como esperado (IA2); etapas de projeto razoáveis |
| 6 | Apresentação do seminário de História em 10 dias | Apresentação do seminário de História em 10 dias | 2026-11-22 | generic | 4 | 180 | 1 | não | Média: prazo certo; o título leva "em 10 dias"; "seminário" não é palavra-chave, então caiu no modelo genérico |
| 7 | Estudar inglês para o simulado da semana que vem | Estudar inglês para o simulado da semana que vem | 2026-11-22 | exam | 5 | 300 | 0 | não | Média: prazo e categoria certos; o título leva "da semana que vem"; "Abra o plano de ensino" não se aplica bem a inglês |
| 8 | Relatório do estágio, entrega dia 30 | Relatório do estágio | 2026-11-30 | assignment | 5 | 300 | 0 | não | Boa: título, prazo e categoria certos; etapas de trabalho escrito servem |
| 9 | Fazer um app de lista de compras em Flutter até o fim do mês | Fazer um app de lista de compras em Flutter até o fim do mês | 2026-11-30 | project | 5 | 300 | 0 | não | Média: prazo certo; "app" venceu "lista" (aparece antes); o título leva "até o fim do mês" |
| 10 | Organizar minhas anotações da faculdade | Organizar minhas anotações da faculdade | — | generic | 4 | 180 | 0 | não | Aceitável: sem data, prazo vazio; etapas genéricas servem |

**Padrões observados:**
- **Prazo:** 8 de 8 textos com data deram a data certa ("24/11", "sexta", "3 de dezembro", "amanhã", "em 10 dias", "semana que vem", "dia 30", "fim do mês"); os 2 sem data deram prazo vazio.
- **Título:** quando não há "—", "," ou ":" antes da data, a expressão de data fica no título (textos 2, 4, 6, 7, 9). Quando o separador vem cedo demais, o título fica curto demais (texto 3).
- **Etapas:** sempre um dos 4 modelos, com o título colado no texto da etapa ("Fazer a primeira versão de Lista de exercícios de Física para amanhã"). Não aproveita nada do conteúdo do pedido (requisitos sempre vazios).
- O revisor da tarefa 4 achou outros casos de borda nas datas (intervalos como "3-5 páginas", "segunda unidade"): estão no [DECIDIR] "Regras de data e categoria do motor de regras" do `afazeres.md`.

Etapas geradas (iguais para todos os textos da mesma categoria, com o título no lugar de `<tema>`):

| Categoria | Etapas (min) e micro-passos |
|---|---|
| assignment | Ler o enunciado e listar requisitos (30) → "Abra o enunciado e copie os itens pedidos numa lista" / "Marque o que ainda não ficou claro" · Pesquisar e separar o material (60) · Fazer a primeira versão de `<tema>` (120) · Revisar e completar (60) · Formatar e enviar (30) |
| exam | Listar os assuntos de `<tema>` (30) · Revisar a teoria (90) · Resolver exercícios (90) · Fazer uma prova antiga ou simulado (60) · Revisar os erros (30) |
| project | Definir o escopo de `<tema>` (30) · Montar a estrutura inicial (60) · Fazer a parte principal (120) · Testar e ajustar (60) · Publicar ou apresentar (30) |
| generic | Entender o que precisa ser feito em `<tema>` (30) · Fazer a primeira parte (60) · Fazer o restante (60) · Revisar e finalizar (30) |

---

### (b) Ollama local (`AI_PROVIDER=openai-compatible`)

- **Conferência:** `curl http://localhost:11434/api/tags` → `{"models":[]}`; `ollama list` → vazio. Pela instrução da rodada, nenhum modelo foi baixado.
- **Configuração usada (só na linha de comando):** `AI_BASE_URL=http://localhost:11434/v1`, `AI_MODEL=llama3.2` (nome qualquer, já que não há modelo), `AI_API_KEY` vazio.
- **Resultado:** nos 10 textos, o `parseGoal` recebeu HTTP 404 (`model 'llama3.2' not found`) em 1–68 ms. O rascunho saiu do motor de regras, com o mesmo conteúdo da tabela (a), `engine: rules` e motivo da reserva `assistant.unavailable`. Tempo total por rascunho: 1–71 ms.
- **Log de cada chamada** (sem chave e sem o texto do usuário): `assistant op=parseGoal provider=openai-compatible model=llama3.2 prompt=parse-goal@v1 ms=68 outcome=http_404 tokens_in=- tokens_out=- error="{"error":{"message":"model 'llama3.2' not found",…}}"`, seguido de `assistant op=draft … outcome=assistant.unavailable fallback=rules`.

### (c) Groq

Não rodado: não há `AI_API_KEY` do Groq no `apps/backend/.env`.

---

### Teste manual do adaptador (`POST /goals/assistant/draft` com o Ollama)

- Backend da tarefa 10 na porta 4100, com `AI_PROVIDER=openai-compatible`, `AI_BASE_URL=http://localhost:11434/v1`, `AI_MODEL=llama3.2` e `AI_API_KEY` vazio.
- Login demo (`POST /auth/demo`) e `POST /goals/assistant/draft` com o texto de referência da `docs/7` §a.3.
- **Resposta:** 200, `engine: "rules"`, título "Trabalho de Algoritmos", prazo `2026-11-24`, 5 etapas, 300 min, em cerca de 0,16 s.
- **Log:** `outcome=http_404` no `parseGoal` (93 ms) e `assistant op=draft … ms=100 outcome=assistant.unavailable fallback=rules`.
- **Conclusão:** não foi possível conferir `engine: 'llm'` nem a validação de uma resposta real (não há modelo). Ficou confirmado que a falha do fornecedor é registrada sem segredo e que a reserva devolve um rascunho válido dentro do orçamento. O tempo limite não foi aumentado e a validação não foi afrouxada.

---

## Como repetir

Comandos completos em `docs/backend/COMO-TESTAR.md`, seção "Assistente do novo objetivo (IA)". Resumo:

```bash
# (a) motor de regras (com o .env no Ollama, zere o modelo e o endereço para o cabeçalho ficar limpo)
AI_PROVIDER=rules AI_MODEL= AI_BASE_URL= npm --workspace apps/backend run ai:eval

# (b) Ollama com o orçamento padrão de 15 s (o modelo precisa aparecer em `ollama list`)
AI_PROVIDER=openai-compatible AI_BASE_URL=http://localhost:11434/v1 AI_MODEL=qwen2.5:3b AI_API_KEY= \
  npm --workspace apps/backend run ai:eval

# (b) Ollama com o orçamento aberto, só para medir a qualidade de um modelo lento (não muda o .env)
AI_PROVIDER=openai-compatible AI_BASE_URL=http://localhost:11434/v1 AI_MODEL=qwen2.5:7b AI_API_KEY= AI_TIMEOUT_MS=120000 \
  npm --workspace apps/backend run ai:eval

# (c) Groq (a chave fica só no .env; nunca na linha de comando compartilhada)
AI_PROVIDER=openai-compatible AI_BASE_URL=https://api.groq.com/openai/v1 AI_MODEL=<modelo> \
  npm --workspace apps/backend run ai:eval
```

O script imprime a tabela em Markdown e as etapas de cada texto; a nota de qualidade é escrita à mão.
