# Como configurar a IA do backend

Este guia explica como funciona o assistente do novo objetivo (a "IA") e o que é preciso fazer para ligá-lo **no backend hospedado** (Render, `https://oitenta.onrender.com`) e na sua máquina.

Escrito em 26/11/2026, com testes reais contra o Groq (plano gratuito). Decisões de produto: `docs/7-proposta-ia.md` (IA1–IA7). Medições: `docs/8-avaliacao-ia.md`. Contrato: `docs/4-contrato-api.md` §3. Passos de teste local: `docs/backend/COMO-TESTAR.md` §8b.

## 1. Resumo para quem tem pressa

Para ligar a IA no Render, faça estas 5 coisas:

1. **Código:** confirme que o Render publica uma versão com o commit `feat(backend): AI_REASONING_EFFORT opcional…` (branch `feat/backend-ia-reasoning-effort`, depois `developer`). Sem ele, o resto funciona, mas a variável `AI_REASONING_EFFORT` é ignorada e a cota gratuita rende cerca de metade (seção 6).
2. **Chave:** crie uma chave **só para o Render** em https://console.groq.com/keys (seção 4).
3. **Variáveis:** no painel do Render, no serviço do backend, aba **Environment**, cadastre:

   | Variável | Valor |
   |---|---|
   | `AI_PROVIDER` | `openai-compatible` |
   | `AI_BASE_URL` | `https://api.groq.com/openai/v1` |
   | `AI_MODEL` | `openai/gpt-oss-120b` |
   | `AI_API_KEY` | a chave do passo 2 (começa com `gsk_`) |
   | `AI_REASONING_EFFORT` | `low` |
   | `AI_FALLBACK` | `rules` |
   | `AI_TIMEOUT_MS` | `15000` |

4. **Reiniciar:** salve e faça um novo deploy. O backend só lê as variáveis quando sobe.
5. **Conferir:** gere um rascunho e veja `"engine":"llm"` na resposta (seção 8).

Não precisa mudar nada no web nem no app: eles só chamam o backend.

## 2. O que a IA faz

A rota `POST /goals/assistant/draft` recebe o texto livre do usuário (ex.: `Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação, entrega 24/12`) e devolve um **rascunho** de objetivo: título, prazo, categoria e etapas, cada uma com minutos estimados e micro-passos.

- **Não grava nada.** Quem grava é o `POST /goals`, depois que o usuário revisa o rascunho na tela.
- No web, é a tela "Novo objetivo" (W27 → W29 → W30). No mobile, o chat de "Novo objetivo" (M13 → M15).
- A resposta diz quem gerou o rascunho: `"engine":"llm"` (o modelo de linguagem) ou `"engine":"rules"` (o motor de regras).

## 3. Os dois motores

### 3.1 Motor de regras (`AI_PROVIDER=rules`, o padrão)

É o que roda quando **nenhuma** variável `AI_*` está configurada (situação do Render em 26/11/2026).

- Sem rede e sem modelo. Código: `apps/backend/src/modules/goals/assistant/rules-goal-assistant.provider.ts` e `step-templates.ts`.
- **Título:** o trecho até o primeiro separador (`—`, `–`, `,`, `:`, `.` ou quebra de linha).
- **Prazo:** um leitor de datas em português (`pt-br-date.parser.ts`) procura coisas como "24/12", "amanhã", "em 10 dias".
- **Categoria:** a primeira palavra-chave encontrada:
  - `prova`, `teste`, `exame`, `p1`, `p2`, `simulado` → prova (`exam`);
  - `trabalho`, `relatorio`, `lista`, `entrega`, `tp` → trabalho (`assignment`);
  - `projeto`, `app`, `site`, `portfolio`, `tcc` → projeto (`project`);
  - nenhuma → genérico (`generic`).
- **Etapas:** um modelo fixo por categoria. Todo "trabalho" recebe as mesmas 5 etapas, que somam 300 min; o detalhe do texto ("implementar e comparar 3 algoritmos") é ignorado.
- Também é a **reserva**: quando o LLM falha, é ele que responde (seção 7).

### 3.2 LLM (`AI_PROVIDER=openai-compatible`)

Fala com qualquer fornecedor que aceite o formato `POST <AI_BASE_URL>/chat/completions` da OpenAI: Groq, Gemini, OpenRouter, Ollama. Código: `openai-compatible-goal-assistant.provider.ts`. Não usa SDK, só `fetch`.

Cada rascunho faz **duas chamadas**, uma depois da outra:

| Chamada | Prompt (arquivo em `assistant/prompts/`) | O que devolve |
|---|---|---|
| `parseGoal` | `parse-goal.v1.prompt.ts` | título, prazo, categoria e requisitos, em JSON |
| `suggestSteps` | `suggest-steps.v1.prompt.ts` | de 3 a 7 etapas com minutos e micro-passos, em JSON |

O que vai em cada chamada:
- `model` (o `AI_MODEL`), `temperature: 0.2`, `response_format: { "type": "json_object" }`;
- `reasoning_effort`, **só** se `AI_REASONING_EFFORT` estiver preenchida;
- a mensagem de sistema (o prompt, com a data de hoje) e a mensagem do usuário (o texto dele, entre delimitadores).

**Privacidade:** ao fornecedor vão **só o texto do objetivo e a data de hoje**. Nunca nome, e-mail, id ou fuso do usuário.

A saída passa por duas validações: o formato do JSON (`llm-output.dto.ts`) e as regras do domínio (`GoalDraftNormalizer`, em `modules/goals`). Se não passar, conta como falha e cai na reserva.

## 4. Fornecedor recomendado: Groq (gratuito)

Escolhido em 26/11/2026 depois de comparar os planos gratuitos (pesquisa resumida no `afazeres.md`, item "Fornecedor de IA do backend hospedado (Render)").

- **Por quê:** gratuito sem cartão, compatível com o formato OpenAI sem adaptador, muito rápido e, por padrão, não guarda os textos enviados.
- **Modelo:** `openai/gpt-oss-120b`. Alternativa mais leve e rápida: `openai/gpt-oss-20b`.

### 4.1 Criar a chave

1. Entre em https://console.groq.com (Google, GitHub ou e-mail).
2. Vá em **API Keys** (https://console.groq.com/keys) → **Create API Key**.
3. Dê um nome que diga onde a chave é usada (ex.: `oitenta-render`) e deixe sem expiração.
4. Marque a verificação "Confirme que é humano" e confirme.
5. **Copie a chave na hora.** Ela só aparece uma vez. Se perder, crie outra.

Use **uma chave por lugar** (uma para o Render, outra para cada máquina). Assim dá para apagar uma sem derrubar as outras. Os limites são da conta inteira, não de cada chave.

### 4.2 Limites do plano gratuito (conferidos em 26/11/2026)

Valem por modelo e para a conta inteira. Lidos nos cabeçalhos `x-ratelimit-*` da própria API:

| Limite | Valor |
|---|---|
| Pedidos por minuto | 30 |
| Pedidos por dia | 1.000 |
| Tokens por minuto | **8.000** |
| Tokens por dia | 200.000 |

O que aperta é o de **tokens por minuto**. Medido com `AI_REASONING_EFFORT=low`:
- cada rascunho gasta cerca de **1.300 tokens** e leva de **1,2 a 1,7 s**;
- isso dá cerca de **6 rascunhos por minuto** e **150 por dia**.

Sem o `low`, eram ~2.300 tokens e ~3,5 s por rascunho (cerca de 4 por minuto).

Quando o limite estoura, o Groq responde **429** e o backend usa o motor de regras naquele rascunho (seção 7). Para uma demo com muita gente ao mesmo tempo, veja as alternativas na seção 9.

Os limites reais da sua conta ficam em https://console.groq.com/settings/limits. Planos gratuitos mudam com frequência: confira na semana da demo.

## 5. Todas as variáveis

Ficam no `apps/backend/.env` (local) ou na aba **Environment** do Render (hospedado). Modelo comentado em `apps/backend/.env.example`.

| Variável | Valores | Padrão | Para que serve |
|---|---|---|---|
| `AI_PROVIDER` | `rules` ou `openai-compatible` | `rules` | escolhe o motor |
| `AI_BASE_URL` | URL `http://` ou `https://` | — | endereço do fornecedor. Obrigatória com `openai-compatible` |
| `AI_MODEL` | nome do modelo no fornecedor | — | obrigatória com `openai-compatible` |
| `AI_API_KEY` | a chave | vazio | **segredo**. Vazio só serve para o Ollama local |
| `AI_REASONING_EFFORT` | `none`, `low`, `medium` ou `high` | vazio | esforço de raciocínio, só para modelos que raciocinam (os `gpt-oss`). Vazio → o campo não vai ao fornecedor. Não use com o Ollama `qwen2.5` |
| `AI_TIMEOUT_MS` | inteiro de 1 a 120000 | `15000` | tempo máximo do rascunho inteiro (as duas chamadas), em milissegundos |
| `AI_FALLBACK` | `rules` ou `none` | `rules` | o que fazer quando o LLM falha (seção 7) |
| `AI_LOG_CONTENT` | `true` ou `false` | `false` | `true` põe o texto do usuário e a resposta do modelo no log. **Só na sua máquina, nunca no Render** |

Regras de leitura:
- Valor vazio conta como ausente.
- Valor desconhecido (ex.: `AI_PROVIDER=fake`, `AI_REASONING_EFFORT=max`) ou `openai-compatible` sem `AI_BASE_URL`/`AI_MODEL` → **o backend não sobe** e diz no log qual variável está errada. A mensagem nunca mostra a chave.
- As variáveis só são lidas na **subida** do backend. Mudou alguma, reinicie.

## 6. Passo a passo no backend hospedado (Render)

### 6.1 Antes de começar

- **Acesso:** você precisa poder editar o serviço do backend no painel do Render (https://dashboard.render.com).
- **Versão do código:** confira qual branch o serviço publica (**Settings → Build & Deploy → Branch**) e se ela já tem o commit do `AI_REASONING_EFFORT` (o último deploy aparece em **Events**, com o commit). Se não tiver, a IA funciona do mesmo jeito, mas sem o `low`: ~2.300 tokens por rascunho e cerca de 4 rascunhos por minuto.
- **Chave:** uma chave nova do Groq só para o Render (seção 4.1).

### 6.2 Cadastrar as variáveis

1. No painel do Render, abra o serviço do backend (o que responde em `https://oitenta.onrender.com`).
2. Vá em **Environment**.
3. Em **Environment Variables**, adicione uma linha para cada variável da tabela da seção 1. Os valores vão **sem aspas**.
4. A `AI_API_KEY` é segredo: nunca a coloque em arquivo do repositório, em print ou em mensagem.
5. Não cadastre `AI_LOG_CONTENT=true` no Render: o log de lá guardaria os textos dos usuários.
6. Salve escolhendo a opção que também faz o deploy. Se salvar sem deploy, use **Manual Deploy → Deploy latest commit** depois.

### 6.3 Conferir a subida

- Em **Logs**, a subida termina sem erro. Se aparecer `AI_PROVIDER inválido`, `exige AI_BASE_URL e AI_MODEL`, `AI_BASE_URL inválida` ou `AI_REASONING_EFFORT inválido`, corrija a variável indicada e faça o deploy de novo.
- `https://oitenta.onrender.com/docs` abre a página **Bora API**.

Depois, siga a seção 8.

### 6.4 Voltar para o motor de regras

Troque `AI_PROVIDER` para `rules` (ou apague a variável) e faça o deploy. As outras `AI_*` podem ficar: o motor de regras as ignora.

## 7. Quando o LLM falha

O rascunho inteiro tem `AI_TIMEOUT_MS` (15 s) para terminar as duas chamadas. Conta como falha:
- tempo esgotado;
- erro de rede;
- resposta HTTP que não é 2xx (inclusive **429**, limite estourado);
- resposta que não é JSON, ou JSON fora do formato.

O que acontece depende do `AI_FALLBACK`:

| `AI_FALLBACK` | Resultado para o usuário |
|---|---|
| `rules` (recomendado) | o backend refaz **o rascunho inteiro** com o motor de regras e responde normalmente, com `"engine":"rules"`. O usuário não vê erro |
| `none` | o backend responde **503**, e o web e o app abrem o formulário manual vazio |

Não há nova tentativa: com 15 s de orçamento, insistir só atrasaria a resposta. Os apps esperam até 25 s pela rota.

## 8. Como saber qual motor respondeu

### 8.1 Pela resposta da API

Gere um rascunho com um usuário logado:

```bash
TOKEN=<token de login>
```

```bash
curl -s -X POST https://oitenta.onrender.com/goals/assistant/draft -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"text":"Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação, entrega 24/12"}'
```

- Com a IA ligada: `"engine":"llm"`, e as etapas falam dos algoritmos (ex.: "Implementar o primeiro algoritmo de ordenação").
- Com o motor de regras: `"engine":"rules"` e as 5 etapas fixas ("Ler o enunciado e listar requisitos", "Pesquisar e separar o material"…).

O token sai do `POST /auth/login` (ou do `POST /auth/demo`, se o seed tiver rodado nesse banco). Em 26/11/2026 o `/auth/demo` do Render respondia 404: o usuário demo não existe no banco hospedado. Use uma conta criada por `POST /auth/register` ou pela tela "Criar conta".

### 8.2 Pelos logs

O backend escreve uma linha por chamada ao LLM. Nunca aparecem a chave nem o texto do usuário (a não ser com `AI_LOG_CONTENT=true`).

Deu certo (duas linhas, uma por chamada):

```
assistant op=parseGoal provider=openai-compatible model=openai/gpt-oss-120b prompt=parse-goal@v1 ms=789 outcome=ok tokens_in=467 tokens_out=149
assistant op=suggestSteps provider=openai-compatible model=openai/gpt-oss-120b prompt=suggest-steps@v1 ms=824 outcome=ok tokens_in=468 tokens_out=243
```

Falhou e a reserva respondeu: uma linha da chamada com o motivo, mais

```
assistant op=draft provider=openai-compatible model=openai/gpt-oss-120b ms=... outcome=assistant.unavailable fallback=rules
```

Com `AI_PROVIDER=rules`, não há nenhuma linha `assistant`.

## 9. Problemas comuns

| `outcome=` no log | Causa provável | O que fazer |
|---|---|---|
| `http_401` | chave errada, apagada ou faltando | crie outra chave e troque a `AI_API_KEY` |
| `http_404` | nome do modelo errado | confira o `AI_MODEL` (ex.: `openai/gpt-oss-120b`, com o prefixo `openai/`) |
| `http_429` | limite do plano gratuito (tokens por minuto ou por dia) | espere o minuto virar; se for o limite diário, só no dia seguinte. Para demos com muita gente, veja as alternativas abaixo |
| `http_400` | o modelo não aceita algum campo (ex.: `reasoning_effort` num modelo sem raciocínio) | deixe `AI_REASONING_EFFORT` vazia |
| `timeout` | o fornecedor demorou mais que `AI_TIMEOUT_MS` | tente o `openai/gpt-oss-20b`, mais rápido |
| `network` | o backend não alcançou o endereço | confira o `AI_BASE_URL`. `localhost` não funciona no Render |
| `invalid_json` / `invalid_output` | o modelo respondeu fora do formato | normalmente isolado; se for sempre, troque de modelo |
| (nenhuma linha `assistant`) | o backend está com `AI_PROVIDER=rules` ou não foi reiniciado | confira as variáveis e faça o deploy |

**Alternativas ao Groq**, todas com o mesmo código (só mudam as variáveis):

| Fornecedor | `AI_BASE_URL` | `AI_MODEL` | Situação |
|---|---|---|---|
| Groq | `https://api.groq.com/openai/v1` | `openai/gpt-oss-120b` | **testado**, recomendado |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai/` | `gemini-3.1-flash-lite` | não testado. No plano gratuito o Google usa os textos para melhorar produtos. Deixe `AI_REASONING_EFFORT` vazia até testar |
| OpenRouter | `https://openrouter.ai/api/v1` | um modelo com sufixo `:free` | não testado. Só 50 pedidos por dia sem créditos (cerca de 25 rascunhos) |
| Ollama (só local) | `http://localhost:11434/v1` | `qwen2.5:3b` | testado; não serve no Render |

## 10. Na sua máquina

Igual ao Render, só que no arquivo `apps/backend/.env` (está no `.gitignore`, nunca vai para o git):

```
AI_PROVIDER="openai-compatible"
AI_BASE_URL="https://api.groq.com/openai/v1"
AI_MODEL="openai/gpt-oss-120b"
AI_API_KEY="<sua chave local>"
AI_REASONING_EFFORT="low"
AI_FALLBACK="rules"
AI_TIMEOUT_MS="15000"
```

Reinicie o backend (`docs/backend/COMO-TESTAR.md`, passo 6). Para comparar os motores com os 10 textos de referência, sem gravar nada:

```bash
npm --workspace apps/backend run ai:eval
```

O `ai:eval` manda os 10 textos em sequência, então no plano gratuito do Groq os últimos costumam cair nas regras por limite de tokens por minuto (em 26/11/2026: 7 de 10 pelo LLM com `low`). Isso é a reserva funcionando, não um erro.

Os testes automáticos (unitários, integração, Playwright e `integration_test`) usam sempre o motor de regras, sem rede.

## 11. Segurança

- A chave só existe no `apps/backend/.env` local e nas variáveis do Render. Nunca em arquivo do repositório, print, chat ou issue.
- Se uma chave vazar, apague-a em https://console.groq.com/keys e crie outra. Em 26/11/2026 a chave local `oitenta-local` apareceu numa conversa e deve ser trocada.
- Não ligue `AI_LOG_CONTENT=true` no Render.
- A rota exige login, então só usuário autenticado gasta a cota. Não há limite por usuário no MVP (`docs/7-proposta-ia.md` §c.8).
