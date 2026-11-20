# Plano: compromissos no calendário e tarefas únicas (mobile + backend)

Criado em 20/11/2026, na rodada de análise (nenhum código foi alterado). A próxima rodada executa este plano.

**Pedido do usuário:** basear-se **só** no design novo, `design/mobile/Bora app anti-procrastinação telas principais-project.zip`.
- O cadastro de compromissos é feito pelo botão **"+ Compromisso"** da aba Semana (calendário), e não mais numa página dedicada.
- Implementar compromissos e tarefas únicas de ponta a ponta. Isso exige backend.

Fluxo de trabalho:
- tudo numa branch nova a partir da `developer`, com TDD e muitos testes;
- só vai para a `developer` com tudo verde;
- se algo falhar, nada vai para a `developer` e o erro é reportado ao usuário.

---

## Como usar este arquivo

- Cada passo tem uma caixa `- [ ]`. Quem executa marca `- [x]` **assim que terminar**, e não antes.
- Passo que não se aplica (por causa de uma decisão) vira `- [x] ~~texto~~ — não se aplica (motivo)`.
- Quando um passo falhar, escreva logo abaixo `> ERRO: <comando> → <saída resumida>`, **pare** e reporte. Não pule o passo nem contorne o erro (regra `processo-desenvolvimento.md`, seções 2, 5 e 6).
- Os blocos **[PARALELO]** rodam em subagentes ao mesmo tempo, cada um na sua worktree e na sua branch. Os demais são do orquestrador, **na ordem**.
- Antes de começar, o orquestrador relê:
  - `CLAUDE.md` e `.agents/rules/*`;
  - `docs/2-decisoes-mvp.md` (4b, 4c, 4e, P3, P8, P9, P20, MP1–MP14);
  - `docs/3-modelagem-dominio.md` (§3.2, §3.4, §3.5);
  - `docs/4-contrato-api.md`;
  - `docs/0-casos-de-uso.md` (UC01, UC07, UC13, UC30);
  - `design/mobile/app/SCREENS.md`;
  - a rodada anterior, `plano-mobile-acesso-perfil-jardim.md`, como modelo de execução.
- Cada subagente recebe:
  - a tarefa copiada deste arquivo;
  - a branch e as pastas que pode alterar;
  - os testes que escreve primeiro;
  - os arquivos para ler e as skills;
  - os critérios de pronto;
  - a regra de processo inteira.
- Relatório fixo de cada subagente: branch e hash, arquivos, saídas vermelha e verde, verificação, cobertura de linhas e pendências no formato do `afazeres.md`.

---

## 1. O que a investigação encontrou

### 1.1 O zip novo (20/11)

- **Mudou só o `Bora App.dc.html`** (263 KB → 285 KB).
  - O `Bora Telas.dc.html` mudou só a origem dos ícones (agora lidos de `./vendor/phosphor`).
  - Entrou a pasta `vendor/` com as fontes do Phosphor, além de um `README.md`.
  - `bora-data.js`, `support.js`, `doc-page.js` e `uploads/` são idênticos.
- **Navegação:**
  - a tab bar voltou a ser **Hoje · Objetivos · Semana · Jardim**, igual à MP10 que já está no app;
  - o ícone do Jardim passou a ser `leaf` (no app é `plant`);
  - a **página dedicada de Compromissos (M41) foi removida**.
- **Hoje, Objetivos, Semana, Jardim, Perfil, Login, Cadastro, Tarefas leves e Preencher à mão** estão idênticos ao design anterior. Só o template do "Novo compromisso" mudou.
- **Compromissos (o que o protótipo faz):**
  - **Na Semana**, no modo Execução, o título do dia ("HOJE, QUINTA, 6 DE NOVEMBRO") ganha à direita o botão **"+ Compromisso"**.
    - O botão abre o formulário já em **"Só uma vez"**, com a data do dia selecionado.
  - Na lista do dia, os compromissos aparecem misturados às etapas, ordenados pela hora:
    - card com fundo `--s2`, ícone do tipo, linha "Compromisso · {repetição}" (ex.: "Toda terça", "Toda seg, qua e sex", "Só uma vez"), título, "08:00–09:00" e um chevron;
    - pílula **"Não vai ter"** (cancelado nesse dia, título riscado e borda tracejada) ou **"Horário alterado"**.
  - **Tocar no compromisso** abre um sheet (`cpOcc`) com:
    - o cabeçalho: ícone, nome, "Ter, 11/11/2025 · 19:00–20:00" e a pílula da repetição;
    - **Editar**: "Horário, nome ou dias" ou, no compromisso único, "Data, horário ou nome";
    - **Não vai ter nesse dia**: "Libero esse horário só dessa vez" (só no recorrente sem exceção);
    - **Voltar pro horário normal** (só quando o dia foi alterado);
    - **Excluir**: "Tirar da agenda: um dia, daqui pra frente ou tudo" ou, no único, "Tirar da sua agenda".
  - No **recorrente**, Editar e Excluir pedem o **escopo** ("Editar qual?" / "Excluir qual?"):
    - **Só nesse dia**;
    - **Desse dia em diante** ("A partir de dd/mm. Antes fica como era.");
    - **Todas as semanas** ("A série inteira");
    - depois o botão "Continuar" ou "Excluir".
  - **Dia cancelado:** o sheet mostra "Liberei esse horário só nesse dia. As outras semanas continuam iguais." e o botão **"Vai ter sim"**.
  - **Formulário** "Novo compromisso" / "Editar compromisso" (um template só):
    - **Nome** (placeholder "Ex.: Aula de Banco de Dados", pelo menos 2 caracteres);
    - **Tipo**: Aula, Trabalho, Saúde ou Pessoal, com os ícones graduation-cap, briefcase, barbell e user;
    - **Repete?**: "Toda semana" (Aulas, estágio, treino) ou "Só uma vez" (Consulta, reunião, viagem);
    - **Dias da semana**: S T Q Q S S D, com pelo menos 1 marcado;
    - **Até quando?**:
      - "Sem fim" ("Repete até você mudar ou excluir.");
      - "Fim do semestre" ("Para de repetir depois de 12/12, no fim do semestre.");
      - "Escolher data" ("Para de repetir depois de dd/mm.");
    - **Data** (no "Só uma vez"), escolhida pelo date picker que já existe;
    - **Horário**: início "até" fim, com o erro "O fim precisa ser depois do início";
    - **Aviso de conflito**: "Bate com "{etapa}" (dd/mm · 20h)" / "Sem estresse: quando você salvar, eu mudo essa etapa pra outro horário livre.";
    - botões **"Salvar compromisso"** (no Editar: "Salvar alterações"; no "só nesse dia": "Salvar só nesse dia"), **"Cancelar"** e **"Excluir compromisso"** (este só no Editar de todas as semanas);
    - subtítulos que mudam conforme o escopo: "Me conta quando você tá ocupado pra eu não marcar etapa por cima.", "Mudando só dd/mm. As outras semanas continuam iguais.", "Vale a partir de dd/mm. Antes disso fica como era.", "Vale pra todas as semanas." e "Me conta o que mudou.";
    - no "só nesse dia", o nome aparece fixo e não há Tipo nem Repete.
  - **Toasts:**
    - "Compromisso salvo / Não vou marcar etapas nesse horário.";
    - "Só esse dia mudou / As outras semanas continuam iguais.";
    - "Mudança salva / Vale a partir de dd/mm.";
    - "Compromisso atualizado / Vale pra todas as semanas." (ou "Recalculei seu plano em volta dele.");
    - "Compromisso excluído / Liberei esses horários pro seu plano.";
    - "Horário liberado / Só nesse dia. Posso encaixar etapas aí.";
    - "Voltou pra agenda / Esse dia segue o horário de sempre.";
    - "Horário normal de volta";
    - "Encerrado / O último foi em dd/mm.";
    - "Plano recalculado / Mudei "{etapa}" pra outro horário." (quando havia conflito).
  - **O modelo do protótipo**, comentado no próprio HTML: "série (regra semanal tipo RRULE) + exceções por ocorrência, como no Google Agenda". As exceções podem ser `cancelada` ou `modificada` (outra data e horário). "Desse dia em diante" **divide a série**: a antiga termina no dia anterior e uma nova começa no dia escolhido, levando as exceções futuras.
- **Tarefas únicas (M43):**
  - título "Tarefas únicas" e o subtítulo "Coisas rápidas que não precisam virar objetivo. Eu encaixo nos seus horários livres.";
  - campo "Ex.: Arrumar o guarda-roupa" com o botão "+";
  - ao digitar, aparecem "Quanto tempo leva?" (15 min, 30 min, 1h, 2h; padrão 30 min), "Quando?" (Hoje, Amanhã, Sem data, Escolher dia) e o botão "Adicionar tarefa";
  - lista em grupos **Hoje**, **Próximos dias**, **Sem data** e **Feitas**, com "N tarefas";
  - cada item tem caixa de marcar ("Marcar como feita"/"Desmarcar"), título, "30 min · Sáb, 08/11/2025" e lixeira ("Excluir tarefa");
  - toasts:
    - "Tarefa anotada / Encaixei num horário livre de hoje." (ou "Eu encaixo quando sobrar um tempinho.");
    - "Feito! / Uma coisa a menos na cabeça.".
  - **No protótipo, nada leva a esta tela.** Só o painel abre, e o "voltar" vai ao Hoje.
- **Hoje:** não mostra compromissos.

### 1.2 Domínio e backend hoje

- `modules/scheduling/src/commitment/`:
  - `Commitment { userId, title, kind: 'commitment', startDate, startMinute, durationMinutes, recurrence: { weekdays, endDate? } | null }`, com **horário em múltiplos de 15 min**;
  - `RecurrenceExpander`, **sem exceções**;
  - `CommitmentBusySource`;
  - `CommitmentRepository.findAllByUser`;
  - **nenhum caso de uso**.
- Backend: `apps/backend/src/modules/scheduling/commitment.empty.ts`, um `EmptyCommitmentRepository` que sempre devolve uma lista vazia (P8).
- Os orquestradores que recalculam o plano (`set-availability`, `create-goal`, `goals-view`, `record-progress`) **já usam o `CommitmentBusySource`**. Com um repositório Prisma de verdade, o compromisso passa a bloquear etapas sem mudar o motor.
- **Não existem** tabela de compromissos nem endpoints de compromisso.
- **Tarefa avulsa:**
  - é um `Goal` com `kind: 'single'` e 1 etapa (D 4d), criado por `POST /goals` com `deadline` opcional (P3);
  - pela **P9, não se agenda trabalho no dia do prazo**;
  - não existem endpoints para **excluir** objetivo nem para **marcar como feito** sem sessão de foco.
- O módulo `activation` tem o `UpdateStepProgress`, usado pelo registro da rampa.

### 1.3 Mobile hoje

- Semana (`features/scheduling/presentation/week_*`, `calendar_widgets.dart`): só blocos de etapa, vindos de `GET /scheduling/plan/week`.
- Já existe o `date_picker_sheet.dart` (em `features/goals/presentation/`). **Não existe** seletor de horário.
- "Preencher à mão" (M16) cria `kind: 'single'`, e essas tarefas aparecem em Objetivos.
- Tab bar: o Jardim usa o ícone `plant`.

### 1.4 Já decidido nos docs (sem pergunta nova)

- `Commitment` com recorrência opcional, expandido no domínio; o motor usa as ocorrências como ocupação (4b, 4e, 3.5).
- Todo dado pertence ao `userId` do token; recurso de outro usuário responde 404; 400 formato; 422 regra (P19).
- Só tokens do tema, rotas no go_router, um `ChangeNotifier` por tela e HTTP só em `data/` (`mobile-flutter.md`).
- Orquestrador "só encadeia casos de uso" (5.9); cada fluxo num arquivo próprio.
- Toda mudança de compromisso **recalcula o plano**, como faz o `PUT /scheduling/availability`.

---

## 2. Portão 0: decisões para o usuário confirmar ANTES de executar

**Como responder:** marque `[x]` na opção escolhida. **Se você responder só "aprovado", vale a (recomendada).** O executor copia as decisões para `docs/2-decisoes-mvp.md` como **MC1–MC14** e não começa sem a resposta.

**C1. Onde guardar as exceções por dia ("Não vai ter", "Horário alterado")**
- [x] (a) **(recomendada)** Dentro do agregado `Commitment`, como as `Step` dentro do `Goal`: `exceptions: [{ date, type: 'cancelled' | 'moved', newDate?, startMinute?, endMinute? }]`. Tabela filha `commitment_exceptions` (cascata ao excluir). O `RecurrenceExpander` aplica as exceções. Motivo: uma regra de negócio por agregado e o mesmo modelo do protótipo ("série + exceções").
- [ ] (b) Entidade separada `OccurrenceRecord` (citada na 4b para "conclusão ou pulo"), com repositório próprio. Desvantagem: duas fontes para montar uma ocorrência.

**C2. Granularidade do horário do compromisso** (o domínio exige múltiplos de 15 min; o protótipo tem aula das 08:00 às 09:40)
- [x] (a) **(recomendada)** Compromisso em **múltiplos de 5 min**, com seletor de horário de 5 em 5. O motor continua alinhando os horários livres em 15 min (o `AvailabilityCalculator` já arredonda), então uma aula que termina às 09:40 libera a partir de 09:45.
- [ ] (b) Manter 15 min. A aula das 09:40 vira 09:45 no cadastro (o seletor anda de 15 em 15).
- [ ] (c) Minuto livre (1 em 1).

**C3. "Fim do semestre"** (o protótipo usa 12/12 fixo)
- [x] (a) **(recomendada)** Data fixa de configuração do app, `SEMESTER_END` no `env/*.json` (lida no `AppConfig`), inicialmente `2026-12-12`. Atualizar a cada semestre; item no `afazeres.md`.
- [ ] (b) Esconder o chip "Fim do semestre" (ficam "Sem fim" e "Escolher data").
- [ ] (c) Campo "fim do semestre" no perfil do usuário (backend, migration e tela sem design).

**C4. Como a Semana recebe os compromissos**
- [x] (a) **(recomendada)** Endpoint próprio `GET /scheduling/commitments/occurrences?from=YYYY-MM-DD&to=YYYY-MM-DD`, que devolve as ocorrências já expandidas (com exceções). O app pede junto com o `GET /scheduling/plan/week`. Motivo: os endpoints de plano não mudam e o caso de uso é do próprio módulo `scheduling`.
- [ ] (b) Acrescentar `commitments` na resposta do `GET /scheduling/plan/week` e do `/day`. Desvantagem: muda dois contratos e o web.

**C5. Aviso de conflito no formulário** ("Bate com "{etapa}"...")
- [x] (a) **(recomendada)** Calculado **no app** com os blocos já carregados na Semana (a semana visível e a seguinte): mostra a primeira etapa que se sobrepõe ao horário. Ao salvar, o backend recalcula e a etapa muda de lugar (toast "Plano recalculado").
- [ ] (b) Endpoint de pré-visualização no backend (simula o plano). Mais preciso, mas é um endpoint a mais.
- [ ] (c) Sem aviso no formulário; só o toast depois de salvar.

**C6. Compromissos no Hoje**
- [ ] (a) **(recomendada)** Não mostrar (o design do Hoje não mostra). O compromisso só aparece na Semana.
- [x] (b) Mostrar na linha do tempo do Hoje (elemento sem design).

**C7. Modelo da tarefa única** (pela P9, uma tarefa "Hoje" com prazo hoje nunca seria encaixada)
- [x] (a) **(recomendada)** `Goal` com `kind: 'single'` ganha `plannedDate` (data local opcional), usado só nas tarefas únicas:
  - o `PlanCalculator` encaixa a tarefa **a partir** desse dia (nunca antes) e dá prioridade pela data;
  - "Sem data" fica no fim da fila, como objetivo sem prazo (P3);
  - `deadline` fica nulo.
  - Motivo: o texto "Encaixei num horário livre de amanhã" fica verdadeiro, e a regra do prazo continua valendo para os objetivos.
- [ ] (b) Sem campo novo: "Hoje" e "Amanhã" viram `deadline = dia + 1` sem folga. Desvantagem: uma tarefa de "Amanhã" pode cair hoje, e o texto do toast fica falso.
- [ ] (c) Tarefa como `Commitment` do tipo `task` (4b). Desvantagem: compromisso tem horário fixo e não é encaixado pelo motor.

**C8. Onde as tarefas únicas aparecem**
- [x] (a) **(recomendada)** Só na tela Tarefas únicas. **Objetivos** passa a listar só `kind: 'goal'`. As tarefas criadas pelo "Preencher à mão" (M16) também vão para Tarefas únicas. Os blocos delas continuam no Hoje e na Semana, como hoje.
- [ ] (b) Nas duas telas (Tarefas únicas e Objetivos).

**C9. Como o usuário chega às Tarefas únicas** (o design não tem caminho; o "voltar" do protótipo vai ao Hoje)
- [x] (a) **(recomendada)** Botão terciário **"Tarefas únicas"** à direita do título "SEU DIA" do Hoje, no lugar do resumo "N etapas · N tarefas leves", que passa para a linha de baixo. Elemento sem design, registrado como diferença.
- [ ] (b) Linha "Tarefas únicas" nas Configurações do Perfil.
- [ ] (c) Opção dentro do "Novo objetivo" (o chat), ao lado de "Preencher à mão".
- [ ] (d) Pedir o caminho ao design e deixar a tela sem entrada até lá.

**C10. Marcar tarefa como feita ou desfazer**
- [x] (a) **(recomendada)** `PATCH /goals/:goalId/done` com `{ done: boolean }`, só para `kind: 'single'` (422 em objetivo comum). Põe a etapa em 100% (ou volta a 0%), apaga os blocos futuros dela e recalcula o plano. Caso de uso novo `SetSingleTaskDone`, reaproveitando `Step`/`GoalProgressCalculator`.
- [ ] (b) Reaproveitar `POST /activation/sessions` com "Concluí". Desvantagem: exige um bloco e uma sessão de foco que o usuário não fez, e não desfaz.

**C11. Excluir tarefa**
- [x] (a) **(recomendada)** `DELETE /goals/:goalId` (qualquer `kind`; o app usa só nas tarefas únicas): apaga o objetivo, as etapas e os blocos futuros e recalcula o plano. Os blocos e sessões passados ficam no histórico (P17/4h). Caso de uso `DeleteGoal`.
- [ ] (b) Excluir só `kind: 'single'`.

**C12. Escopo "Desse dia em diante"**
- [x] (a) **(recomendada)** Como o protótipo: **dividir a série**. A antiga ganha `endDate = dia − 1` e leva as exceções anteriores; uma nova começa no dia escolhido com os dados editados e as exceções futuras. Se a antiga ficar sem nenhum dia, é apagada. "Excluir desse dia em diante" = só encerrar a antiga.
- [ ] (b) Não oferecer "Desse dia em diante" (só "Só nesse dia" e "Todas as semanas"). Diferença do design.

**C13. Atualizar `design/mobile/app/` com o zip novo**
- [x] (a) **(recomendada)** Sim:
  - substituir `source/` (Bora App, Bora Telas, `vendor/` e `README.md`);
  - capturar as telas novas em `screens/` (44 em diante);
  - no `SCREENS.md`, marcar a M41 (página Compromissos) como **removida do design**;
  - commitar o zip, como na rodada anterior.
- [ ] (b) Não mexer em `design/`; os subagentes leem do zip extraído.

**C14. Ícone da aba Jardim** (o design novo usa `leaf`)
- [ ] (a) **(recomendada)** Trocar para `leaf` (Phosphor `PhosphorIconsRegular.leaf` / `Fill.leaf`), como no design.
- [x] (b) Manter `plant`.

---

## 3. Contrato proposto (fixado na Fase 0, antes do paralelo)

Vale com as recomendações; se uma decisão mudar, o executor ajusta esta seção no passo 0.5. Formato de erro, 400/401/404/422 e `userId` do token conforme `docs/4-contrato-api.md` (Regras gerais). **Toda mutação recalcula o plano** e devolve `plan` (mesmo formato do `PUT /scheduling/availability`).

**Compromissos** (nova seção §7 do contrato; controller no módulo `scheduling`, mutações por orquestradores):

| Método e rota | Corpo / query | Resposta | Erros | Caso de uso |
|---|---|---|---|---|
| `POST /scheduling/commitments` | `{ title, category: aula\|trabalho\|saude\|pessoal, startDate, startMinute, endMinute, recurrence: { weekdays: number[], endDate?: string } \| null }` | 201 `{ commitment, plan }` | 400, 401, 404 (sem disponibilidade, P12), 422 | `CreateCommitment` → `GeneratePlan` |
| `GET /scheduling/commitments/:id` | — | 200 `{ commitment }` (com `exceptions`) | 401, 404 | `GetCommitment` |
| `GET /scheduling/commitments/occurrences` | `?from=YYYY-MM-DD&to=YYYY-MM-DD` (até 62 dias) | 200 `{ occurrences: [{ commitmentId, title, category, date, originalDate, startMinute, endMinute, status: normal\|cancelled\|moved, recurrence }] }` | 400, 401, 422 (intervalo inválido) | `ListCommitmentOccurrences` |
| `PATCH /scheduling/commitments/:id` | `{ scope: all\|following, fromDate? (obrigatório em following), title?, category?, startDate?, startMinute?, endMinute?, recurrence? }` | 200 `{ commitment, plan }` (em `following`, a série nova) | 400, 401, 404, 422 | `UpdateCommitment` / `SplitCommitmentFrom` → `GeneratePlan` |
| `DELETE /scheduling/commitments/:id` | `?scope=all\|following&fromDate=` | 200 `{ plan }` | 400, 401, 404, 422 | `DeleteCommitment` / `EndCommitmentBefore` → `GeneratePlan` |
| `PUT /scheduling/commitments/:id/occurrences/:date` | `{ status: cancelled }` ou `{ status: moved, newDate, startMinute, endMinute }` | 200 `{ commitment, plan }` | 400, 401, 404 (série ou dia sem ocorrência), 422 | `SetOccurrenceException` → `GeneratePlan` |
| `DELETE /scheduling/commitments/:id/occurrences/:date` | — | 200 `{ commitment, plan }` | 401, 404 | `ClearOccurrenceException` → `GeneratePlan` |

- `endMinute > startMinute`, sem cruzar a meia-noite; os dois em múltiplos de 5 (C2); `title` com 2–80 caracteres; `weekdays` de 0 a 6 sem repetir e não vazio; `endDate ≥ startDate`.
- Um compromisso recorrente criado hoje tem `startDate` = hoje no fuso do usuário (o app manda).
- Mapa de ações da tela:
  - "Não vai ter nesse dia" = `PUT …/occurrences/:date {cancelled}`;
  - "Vai ter sim" e "Voltar pro horário normal" = `DELETE …/occurrences/:date`;
  - "Editar só nesse dia" = `PUT …/occurrences/:date {moved}`;
  - "Excluir só nesse dia" = `{cancelled}`.

**Tarefas únicas** (§3 do contrato):

| Método e rota | Mudança | Erros |
|---|---|---|
| `POST /goals` | aceita `plannedDate?: YYYY-MM-DD` (só com `kind: single`; com `goal` → 422) | os de hoje + 422 |
| `GET /goals` | cada item ganha `kind`, `plannedDate` e `estimatedMinutes` (a soma); a tarefa feita é `status: done` (o `done` numérico já existente continua sendo a contagem de etapas); aceita `?kind=goal\|single` | 400 (`kind` inválido) |
| `PATCH /goals/:goalId/done` | `{ done: boolean }` → 200 `{ goal, plan }`; só `single` | 400, 401, 404, 422 (objetivo comum) |
| `DELETE /goals/:goalId` | → 200 `{ plan }` | 401, 404 |

---

## 4. Mapa de paralelização

```
Fase 0 (orquestrador, sequencial)
  0.1 decisões → 0.2 branch → 0.3 linha de base → 0.4 design → 0.5 docs + contrato → 0.6 esqueleto mobile (TDD) → 0.7 worktrees
                                                                                          │
Fase 1 [PARALELO] (contra o contrato fixado; o mobile usa repositórios de exemplo) ─────────┤
  D1 Domínio compromissos (modules/scheduling/src/commitment)      feat/cp-r-dominio-compromisso
  D2 Domínio tarefas (modules/goals + PlanCalculator plannedDate)  feat/cp-r-dominio-tarefa
  M1 Mobile: compromissos na Semana + sheet da ocorrência          feat/cp-r-mobile-semana
  M2 Mobile: formulário Novo/Editar compromisso                    feat/cp-r-mobile-form
  M3 Mobile: Tarefas únicas                                        feat/cp-r-mobile-tarefas
                                                                                          │
Fase 2 (orquestrador): integra D1, D2 → prisma (tabelas + migration) → [PARALELO]
  B1 Backend compromissos (prisma repo + controller + orquestradores + e2e)   (continua D1)
  B2 Backend tarefas (endpoints de goals + e2e)                               (continua D2)
Fase 3 (orquestrador): integra B1, B2, M1, M2, M3 → HTTP real no mobile → ponta a ponta no simulador + comparação visual
Fase 4: verificação completa + REVISOR → correções pelos autores
Fase 5: merge na developer + push (com a conta do gh, já configurada)
Fase 6: relatório, afazeres, diário, COMO-TESTAR
```

- **Branch de integração:** `feat/compromissos-tarefas-unicas`, criada da `developer`. As branches dos subagentes saem dela depois do passo 0.6 (ou do passo 2.x, no caso de B1 e B2).
- **Arquivos que só o orquestrador altera:**
  - na raiz e no backend: `package.json` e `package-lock.json` da raiz, `turbo.json`, `apps/backend/src/app.module.ts`, `apps/backend/src/orchestrators/orchestrators.module.ts`, `apps/backend/prisma/**`, `packages/contracts/openapi.json`, `afazeres.md`, `docs/**`, `.agents/**` e `design/**`;
  - no mobile: `lib/core/routes/*`, `lib/core/di/app_dependencies.dart`, `lib/core/config/*`, `lib/core/widgets/app_shell.dart`, `lib/app.dart`, `pubspec.yaml`, `env/*` e `integration_test/*`;
  - os arquivos de domínio do mobile criados no passo 0.6 (`features/scheduling/domain/commitment.dart` e `features/goals/domain/single_task.dart`), que os subagentes só leem.
- **Conflitos previsíveis:** D1 e D2 mexem em `modules/scheduling` (D1 em `commitment/`, D2 só em `plan/model/plan.calculator.ts`). Nenhum dos dois altera `modules/scheduling/src/index.ts`; se precisarem exportar algo novo, pedem ao orquestrador.

---

## Fase 0: preparação (orquestrador)

### 0.1 Decisões
- [x] O usuário respondeu o Portão 0. Escolhas: C1 a · C2 a · C3 a · C4 a · C5 a · C6 **b** · C7 a · C8 a · C9 a · C10 a · C11 a · C12 a · C13 a · C14 **b**
- [x] Ajustar a seção 3 (contrato) e os passos que dependem de opções diferentes da recomendada (riscar e anotar o motivo).
  > **C6 = b:** o M1 também mostra os compromissos do dia na linha do tempo do Hoje (mesmo cartão e mesmo sheet), carregando as ocorrências do dia junto com o plano. **C14 = b:** o ícone do Jardim não muda (o item da tab bar sai do 0.6). **Contrato:** o `GET /goals` já tinha `done` numérico (contagem de etapas); a tarefa feita é indicada por `status: done`, sem campo `done` booleano novo.

### 0.2 Branch
- [x] `git checkout developer && git pull --ff-only origin developer` (anotar se a remota trouxe algo).
  > A remota não trouxe nada (20/11).
- [x] `git checkout -b feat/compromissos-tarefas-unicas`.
- [x] Anotar o hash de `origin/main` para conferir no fim que não mudou.
  > `7b8a85e`.
- [x] Commitar este plano e o zip novo (como na rodada anterior), se C13 = a.
  > `ed75505`.

### 0.3 Linha de base
- [x] `npm --workspace apps/backend run db:start` e `npm --workspace apps/backend run prisma:generate`.
- [x] `npm run build`, `npx turbo run lint`, `npm run test --workspaces --if-present` e `npm --workspace apps/backend run test:e2e`, com a máquina livre: sem simulador, sem `flutter run` e sem backends extras (as falhas por estouro de 5 s da rodada anterior vieram de máquina carregada).
- [x] `cd apps/mobile && flutter pub get && flutter analyze && flutter test` (esperado: 582 testes).
- [x] Anotar o resultado aqui. Se algo já falhar, **parar e reportar**.
  > Verde: build e lint (9/9), testes de todos os workspaces, e2e 139/139 em 71 s, `flutter analyze` sem problemas, 582 testes no mobile.

### 0.4 Design (C13 = a)
- [x] Extrair o zip numa pasta temporária; copiar `Bora App.dc.html`, `Bora Telas.dc.html`, `README.md` e `vendor/` para `design/mobile/app/source/`; conferir com `cmp` que os demais são idênticos.
- [x] Capturar com Playwright (390×844, deviceScaleFactor 2, só a moldura `[data-bora]`, botões do painel pelo nome; script numa pasta temporária):
  - `44-semana-botao-compromisso.png` (Semana com "+ Compromisso");
  - `45-semana-com-compromissos.png` (dia 11 com "Consulta no dentista" e as pílulas);
  - `46-novo-compromisso-semanal.png` (com rolagem expandida);
  - `47-novo-compromisso-unico.png`;
  - `48-compromisso-sheet-menu.png`;
  - `49-compromisso-sheet-escopo.png` (Editar qual?);
  - `50-compromisso-sheet-excluir.png` (Excluir qual?);
  - `51-compromisso-cancelado.png` ("Vai ter sim");
  - `52-editar-so-nesse-dia.png`;
  - `53-tarefas-unicas.png`;
  - `54-tarefas-unicas-adicionando.png` (com "Quanto tempo leva?" aberto).
  - Os estados que exigem cliques extras (escopo, cancelado, editar só nesse dia, adicionando) usam interações do Playwright descritas no próprio script.
- [x] Atualizar o `SCREENS.md`: linhas 44–54; a M41 marcada como removida e a M42 substituída pela 46/47; nas Observações, a tab bar sem Compromissos, o ícone `leaf` e a ausência de caminho para as Tarefas únicas (C9).
- [x] Commit `docs(design): compromissos no calendário e tarefas únicas (zip de 20/11)`.
  > `7ca8e4b`. Capturas 44, 45, 46, 46b, 47–54.

### 0.5 Documentação, decisões e contrato
- [x] `docs/2-decisoes-mvp.md`: seção "Decisões da rodada de compromissos e tarefas únicas (MC1–MC14), 20/11/2026", no formato das P. **Atualizar a P8** (compromissos passam a ter tela, endpoint e tabela) e citar a **P9** na MC7.
- [x] `docs/3-modelagem-dominio.md`:
  - na §3.2, os atributos novos de `Commitment` (`category`, `endMinute` ou duração em múltiplos de 5, `exceptions`), as regras, os casos de uso e os cenários de teste (Dado/Quando/Então) de cada um;
  - na §3.4, o `RecurrenceExpander` com as exceções;
  - em `Goal`, o campo `plannedDate` e as regras (só `single`; data local);
  - no `PlanCalculator`, a regra do `plannedDate` (C7);
  - os cenários de `SetSingleTaskDone` e `DeleteGoal`.
  - **Os subagentes de domínio implementam exatamente esses cenários.**
- [x] `docs/4-contrato-api.md`: a nova §7 Compromissos e as mudanças da §3 (seção 3 deste plano), com a lista de testes de integração de cada rota (caminho feliz, 401, 404 de recurso de outro usuário, 400 com campo a mais, 422) e a tabela §6 atualizada.
- [x] `afazeres.md`:
  - fechar `[x]` o "[DECIDIR] Compromissos fixos (Aula/Estágio) fora do contrato" e o "[DECIDIR] Compromissos e Tarefas únicas têm design novo", com a referência às MC;
  - abrir os itens que as decisões criarem (ex.: `SEMESTER_END` a atualizar por semestre; caminho das Tarefas únicas sem design; web sem tela de compromissos).
- [x] `docs/6-diario-execucao.md`: entrada "20/11/2026: início da rodada de compromissos e tarefas únicas".
- [x] Commit `docs: decisões MC, modelagem e contrato de compromissos e tarefas únicas`.
  > `1a3d9a4`. Contrato na §5b (compromissos) e na §3 (tarefas únicas) do `docs/4`; modelagem na §8 do `docs/3`.

### 0.6 Esqueleto compartilhado do mobile (TDD: vermelho → verde, guardar as saídas)

Objetivo: deixar rotas, DI, os modelos de domínio do app e os repositórios (interface + exemplo + HTTP **vazio**) prontos, para M1, M2 e M3 mexerem só nas próprias pastas.

- [x] **Testes primeiro** (`test/core/shell_compromissos_tarefas_test.dart`, `test/features/scheduling/commitment_model_test.dart`, `test/features/goals/single_task_model_test.dart`):
  - **modelos:** `Commitment` e `CommitmentOccurrence` com `fromJson`/`toJson` iguais ao contrato da seção 3, `category` (enum aula/trabalho/saude/pessoal) e `status` (normal/cancelled/moved); `SingleTask` (`id`, `title`, `estimatedMinutes`, `plannedDate?`, `done`) a partir do item de `GET /goals`;
  - **rotas:** `/semana/compromisso` (novo; `extra` com a data inicial) e `/semana/compromisso/:id` (editar; `extra` com escopo e data) abrem `CommitmentFormPage`; `/tarefas` abre `SingleTasksPage`; as três ficam dentro do shell; `tabFor` devolve `week` para `/semana/compromisso*` e `today` para `/tarefas`;
  - **DI:** `deps.commitments` é o exemplo no modo `sample` e o HTTP no modo `http`; `deps.singleTasks` idem;
  - **config:** `AppConfig.semesterEnd` lê `SEMESTER_END` (C3 = a), com padrão `2026-12-12`;
  - ~~**tab bar:** o Jardim usa `leaf`~~ — não se aplica (C14 = b).
- [x] Rodar e guardar o **vermelho**.
  > Não compilava (124 erros de símbolos inexistentes). Os testes dos repositórios de exemplo foram escritos junto com o código de exemplo (dados do protótipo), não antes.
- [x] **Implementar:**
  - `features/scheduling/domain/commitment.dart` (modelos);
  - `features/scheduling/data/commitments_repository.dart` (interface com os 7 métodos da seção 3);
  - `sample_commitments_repository.dart` (com os 5 compromissos do protótipo, `cpDefaults`, e a expansão com exceções em memória, para o modo `sample`);
  - `http_commitments_repository.dart` (**métodos que lançam `UnimplementedError`**; o M1 completa);
  - `features/goals/domain/single_task.dart`, `features/goals/data/single_tasks_repository.dart` + exemplo (com as 6 tarefas do protótipo) + HTTP vazio;
  - páginas esqueleto `CommitmentFormPage` (em `features/scheduling/presentation/commitment_form_pages.dart`) e `SingleTasksPage` (em `features/goals/presentation/single_tasks_pages.dart`), como `PlaceholderScreen`;
  - rotas, DI, `AppConfig.semesterEnd` e `SEMESTER_END` nos `env/*.json`.
- [x] Rodar e guardar o **verde**; `flutter analyze` e `flutter test` inteiros verdes.
- [x] Commit `feat(mobile): esqueleto de compromissos e tarefas únicas (rotas, DI, modelos, repositórios)`.
  > `e317747`; 622 testes. Entrou também `patch`/`delete` no `ApiClient` (com teste antes). O botão "Tarefas únicas" do Hoje (MC9) fica para o orquestrador depois do M1, que mexe na mesma tela (C6 = b).

### 0.7 Worktrees
- [x] Uma worktree por subagente da Fase 1 em `/Users/arthursetragni/Hackaton/OiTenta-wt/<nome>`, cada uma com a sua branch saindo da integração.
- [x] P28: `npm ci` (D1, D2), `npm --workspace apps/backend run prisma:generate` (D1, D2) e `flutter pub get` (M1, M2, M3). Copiar `apps/backend/.env` **antes** do `prisma:generate`, e `apps/mobile/env/local-iphone.json` para as do mobile.

---

## Fase 1 [PARALELO]: subagentes

Regras comuns:
- TDD com prova.
- Sem dependência nova e sem `npm install`/`pub add`.
- Sem merge e sem push; commits só na própria branch.
- Domínio sem framework; só tokens no mobile.
- Relatório fixo.
- Dúvida que o plano não resolve: **parar e reportar**.

### D1. Domínio de compromissos (`feat/cp-r-dominio-compromisso`)

**Pastas:** `modules/scheduling/src/commitment/**`, `modules/scheduling/test/commitment/**` (ou onde o módulo guarda os testes) e, se precisar, `modules/scheduling/src/common/**`. **Skills:** `module-entity`, `module-repository`, `module-use-case`, `shared-validation-rule` (só se faltar uma regra reutilizável).

- [ ] **Entidade `Commitment`** (testes primeiro, cenários da §3.2):
  - `category` obrigatória em `aula|trabalho|saude|pessoal`;
  - `title` de 2 a 80 caracteres;
  - horário em múltiplos de 5 (C2) com `endMinute > startMinute` no mesmo dia (ou `durationMinutes`, conforme a modelagem fixada no passo 0.5);
  - `exceptions` (C1): data local válida; `moved` com `newDate`, `startMinute` e `endMinute` válidos; data da exceção que é uma ocorrência da série; sem duas exceções no mesmo dia;
  - recorrência: `weekdays` não vazio, únicos, de 0 a 6; `endDate ≥ startDate`;
  - métodos puros que devolvem um clone: `withException(date, …)`, `withoutException(date)`, `endingBefore(date)` (null se ficar sem nenhum dia) e `splitFrom(date, changes)` → `[antiga|null, nova]`, levando as exceções ≥ data (C12).
- [ ] **`RecurrenceExpander`**:
  - devolve ocorrências com `status` (normal/cancelled/moved), `date` e `originalDate`;
  - a `cancelled` aparece na listagem, mas **não** conta como ocupação;
  - a `moved` sai do dia original e aparece no `newDate` com o novo horário, mesmo fora da janela original;
  - o único continua igual;
  - testes de fronteira: `endDate`, `startDate`, troca de horário de verão inexistente (o fuso é fixo; manter o teste atual).
- [ ] **`CommitmentBusySource`**: ignora as canceladas e usa o horário movido. Teste com uma etapa que seria encaixada no horário liberado.
- [ ] **Repositório** (`module-repository`): `create`, `update`, `delete`, `findById(userId, id)`, `findAllByUser(userId)`; implementação em memória para os testes; teste negativo de posse (o usuário B não vê nem altera o compromisso de A).
- [ ] **Casos de uso** (`module-use-case`), cada um com os cenários da modelagem e o teste negativo de posse:
  - `CreateCommitment`, `GetCommitment`;
  - `ListCommitmentOccurrences` (intervalo de no máximo 62 dias; `from ≤ to`);
  - `UpdateCommitment` (todas);
  - `SplitCommitmentFrom` (desse dia em diante);
  - `DeleteCommitment`, `EndCommitmentBefore`;
  - `SetOccurrenceException`, `ClearOccurrenceException`.
- [ ] `npm run test --workspace @oitenta/scheduling` com **100%** de cobertura; build e lint do módulo; grep de framework.
- [ ] **Parar** e reportar (a parte do backend é a Fase 2).

### D2. Domínio de tarefas únicas (`feat/cp-r-dominio-tarefa`)

**Pastas:** `modules/goals/**` e `modules/scheduling/src/plan/model/plan.calculator.ts` + o teste dele. **Skills:** `module-use-case`, `module-repository`.

- [ ] **`Goal.plannedDate`** (testes primeiro): data local opcional, só com `kind: 'single'` (`goal` com `plannedDate` → inválido); `CreateGoal` aceita e grava.
- [ ] **`SetSingleTaskDone({ userId, goalId, done })`**: só `single` (comum → `ValidationException`); `done: true` põe a etapa em 100% e o objetivo em concluído; `done: false` volta a 0% e a ativo; teste de posse.
- [ ] **`DeleteGoal({ userId, goalId })`** + `GoalRepository.delete(userId, goalId)` (e na implementação em memória); teste de posse (B não apaga o de A → `NotFoundError`).
- [ ] **`ListGoals`**: aceita filtro `kind` e devolve `kind`, `plannedDate`, `estimatedMinutes` e `done` na visão.
- [ ] **`PlanCalculator`** (C7 = a; testes primeiro):
  - um `single` com `plannedDate` não recebe bloco antes desse dia;
  - recebe no próprio dia, se houver horário livre e limite diário;
  - se não couber no dia, vai para o próximo dia livre;
  - entre `single`s, o de data mais cedo vem antes;
  - um `single` sem data fica depois dos objetivos com prazo (P3);
  - objetivo com prazo **não muda** de comportamento (rodar os testes antigos sem alterar).
- [ ] `npm run test --workspace @oitenta/goals` e `--workspace @oitenta/scheduling` com 100%; grep de framework. **Parar** e reportar.

### M1. Mobile: compromissos na Semana, no Hoje (C6 = b) e sheet da ocorrência (`feat/cp-r-mobile-semana`)

**Pastas:** `features/scheduling/presentation/week_*`, `today_controller.dart`, `today_screen.dart` (C6 = b), `scheduling_pages.dart`, `calendar_widgets.dart`, `commitment_occurrence_sheet.dart` (novo), `commitment_card.dart` (novo), `features/scheduling/data/http_commitments_repository.dart` e os testes correspondentes. **Ler:** template `<!-- SEMANA / CALENDÁRIO -->` (procurar `cpAddDia`, `isCp`), o sheet `sheetCpOcc` e a lógica `ocAcoes`, `ocEscopos` e `ocContinuar` do `Bora App.dc.html`; `screens/44, 45, 48–51`.

- [ ] **`HttpCommitmentsRepository`** (testes primeiro, com o `fake_api.dart`): cada método da seção 3 com rota, verbo, corpo, query e o mapeamento de 401/404/409/422 para as falhas do app.
- [ ] **`WeekController`** (testes primeiro):
  - carrega as ocorrências da semana junto com o plano;
  - `dayItems` mistura etapas e compromissos ordenados pela hora;
  - o compromisso cancelado continua na lista com o estado "Não vai ter";
  - `repetitionLabel` ("Toda terça", "Toda seg, qua e sex", "Toda sábado" → "Todo sábado" e "Todo domingo", como `cpRepTxt`, e "Só uma vez");
  - erro de carga dos compromissos não esconde as etapas (mostra a mensagem);
  - recarrega depois de qualquer ação.
- [ ] **`CommitmentOccurrenceController`** (o sheet; testes primeiro):
  - ações conforme o estado: recorrente sem exceção (Editar, Não vai ter, Excluir); com dia movido (Editar, Voltar pro horário normal, Excluir); único (Editar, Excluir); cancelado ("Vai ter sim");
  - passo de escopo com "Só nesse dia" selecionado por padrão;
  - "Continuar": no editar navega para o formulário com escopo e data; no excluir chama o método certo (`so` → cancelar o dia; `following` → `DELETE ?scope=following`; `all` → `DELETE ?scope=all`);
  - os toasts do design; `busy`; erro.
- [ ] **Hoje (C6 = b)** (testes primeiro): o `TodayController` carrega as ocorrências do dia junto com o plano; a linha do tempo mistura etapas e compromissos pela hora, com o mesmo cartão da Semana; o toque abre o mesmo sheet; ações recarregam o Hoje. Os testes antigos do Hoje continuam passando. Elemento sem design no Hoje: registrar como diferença.
- [ ] **Telas** (widget tests primeiro): botão "+ Compromisso" no título do dia só no modo Execução (abre `/semana/compromisso` com a data do dia e "Só uma vez"); card do compromisso igual ao design; o sheet com os 3 estados e o passo de escopo. Só tokens.
- [ ] `flutter analyze`, `flutter test` e cobertura de 100% nos controladores e no repositório HTTP.

### M2. Mobile: formulário Novo/Editar compromisso (`feat/cp-r-mobile-form`)

**Pastas:** `features/scheduling/presentation/commitment_form_*` (substitui o esqueleto), `features/scheduling/presentation/time_range_field.dart` (novo) e os testes. **Ler:** template `<!-- NOVO COMPROMISSO -->` e a lógica `cpBlank`, `cpEdit`, `cpSalvar`, `cpOk`, `cpAtes`, `cpSubTxt` e `conflito`; `screens/46, 47, 52`; `features/goals/presentation/date_picker_sheet.dart`.

- [ ] **`CommitmentFormController`** (testes primeiro):
  - modos novo, editar todas (`all`), desse dia em diante (`following`) e só nesse dia (`so`), com título, subtítulo, campos visíveis e texto do botão exatamente como `cpSubTxt`/`cpSalvarTxt`;
  - validação (`cpOk`): nome ≥ 2; fim > início; semanal com ≥ 1 dia e data escolhida quando "Escolher data"; único com data;
  - "Até quando?": "Sem fim" → sem `endDate`; "Fim do semestre" → `AppConfig.semesterEnd` (C3); "Escolher data" → date picker;
  - conflito (C5 = a): a primeira etapa dos blocos carregados que se sobrepõe; texto `Bate com "{t}" (dd/mm · HHh)`;
  - `save()` chama o método certo do repositório para cada modo (seção 3) e devolve o toast certo;
  - `delete()` (só em `all`);
  - erros 404/422 mostram a mensagem; `busy`.
- [ ] **`TimeRangeField`**: dois campos "início" e "fim" com seletor de horário de 5 em 5 min (C2). Usar o `CupertinoTimerPicker`/`CupertinoDatePicker` do Flutter em modo hora, **sem pacote novo**, num bottom sheet com os tokens. Erro "O fim precisa ser depois do início".
- [ ] **Tela e página** (widget tests primeiro): tudo do template, com chips de tipo, cards de repetição, dias S T Q Q S S D com rótulos de acessibilidade completos ("Segunda" etc.), "Até quando?", data, horário, aviso de conflito, "Salvar…", "Cancelar" e "Excluir compromisso". Ao salvar, toast e `pop` (ou `go(AppRoutes.week)`).
- [ ] `flutter analyze`, `flutter test` e cobertura de 100% no controlador e no `TimeRangeField`.

### M3. Mobile: Tarefas únicas (`feat/cp-r-mobile-tarefas`)

**Pastas:** `features/goals/presentation/single_tasks_*` (substitui o esqueleto), `features/goals/data/http_single_tasks_repository.dart`, os testes, e (C8 = a) o filtro da lista de Objetivos em `goals_controller.dart`. **Ler:** template `<!-- TAREFAS ÚNICAS -->` e a lógica `uniVals` (tarefas), `screens/53, 54`.

- [ ] **`HttpSingleTasksRepository`** (testes primeiro): `list` (`GET /goals?kind=single`), `create` (`POST /goals` com `kind: single`, 1 etapa com o título, `estimatedMinutes` e `plannedDate`), `setDone` (`PATCH /goals/:id/done`) e `delete` (`DELETE /goals/:id`).
- [ ] **`SingleTasksController`** (testes primeiro):
  - grupos Hoje (data ≤ hoje), Próximos dias (ordenado), Sem data e Feitas, com "1 tarefa"/"N tarefas" e grupos vazios escondidos;
  - adicionar: o painel abre ao digitar; duração padrão 30 min; "Quando?" padrão Hoje; "Escolher dia" abre o date picker; texto ≥ 2;
  - os toasts "Tarefa anotada" com o subtítulo certo para cada caso;
  - marcar e desmarcar (toast "Feito!" só ao marcar); excluir;
  - erros e `busy`; guarda `_disposed`.
- [ ] **Tela e página** (widget tests primeiro), fiéis a `screens/53–54`; voltar → `pop` ou `go(AppRoutes.today)`.
- [ ] **Objetivos** (C8 = a): a lista mostra só `kind: goal`. Teste.
- [ ] `flutter analyze`, `flutter test` e cobertura de 100% no controlador e no repositório HTTP.

---

## Fase 2: backend (orquestrador → [PARALELO] B1, B2)

- [ ] Receber D1 e D2, conferir os relatórios e fazer merge na integração (D1 → D2). Rodar `npm run test --workspaces --if-present` e o build. Conflito: parar e reportar.
- [ ] **Prisma** (skill `backend-prisma-sync-module`):
  - `scheduling.model.prisma` ganha `Commitment` (userId, title, category, startDate, startMinute, endMinute, weekdays `Int[]`, endDate?, createdAt) e `CommitmentException` (commitmentId com `onDelete: Cascade`, date, type, newDate?, startMinute?, endMinute?, único por (commitmentId, date));
  - `goals.model.prisma` ganha `plannedDate String?`;
  - migration incremental nomeada (`compromissos_e_tarefas_unicas`); `prisma migrate dev`; `prisma:generate`.
- [ ] Commit; criar as worktrees de B1 e B2 a partir da integração (P28).

### B1. Backend de compromissos [PARALELO] (`feat/cp-r-backend-compromisso`, continua o D1)

**Pastas:** `apps/backend/src/modules/scheduling/**`, `apps/backend/src/orchestrators/commitment-*.ts` (novos), `apps/backend/test/commitments.e2e-spec.ts` (novo) e `apps/backend/test/scheduling.e2e-spec.ts` (só o que tocar o repositório vazio). **Skills:** `backend-prisma-repository`, `backend-nest-controller`.

- [ ] **e2e primeiro** (`commitments.e2e-spec.ts`), para cada rota da seção 3: caminho feliz; 401; 404 de compromisso de outro usuário; 400 (campo a mais, `userId` no corpo, tipo errado); 422 (regras); **efeito no plano**: um compromisso que cobre o horário de uma etapa faz o `GET /scheduling/plan/day` deixar de ter bloco ali; o "Não vai ter nesse dia" devolve o horário ao plano. Rodar e guardar o **vermelho**.
- [ ] `PrismaCommitmentRepository` no lugar do `EmptyCommitmentRepository` (apagar o vazio e o comentário da P8), registrado no `SchedulingModule`.
- [ ] Controller no módulo `scheduling` (`GET :id`, `GET occurrences`) e orquestradores por fluxo (`commitment-create.orchestrator.ts`, `commitment-update.orchestrator.ts`, `commitment-delete.orchestrator.ts`, `commitment-occurrence.orchestrator.ts`), cada um "caso de uso → `regeneratePlan`". DTOs com `class-validator` e Swagger. `*.integration.http` atualizado.
- [ ] **Pedir ao orquestrador** o registro em `orchestrators.module.ts` (não alterar).
- [ ] e2e verde; `npm --workspace apps/backend run test:e2e` inteiro verde; lint.

### B2. Backend de tarefas únicas [PARALELO] (`feat/cp-r-backend-tarefa`, continua o D2)

**Pastas:** `apps/backend/src/modules/goals/**`, `apps/backend/src/orchestrators/goals-view.*`, `single-task-*.orchestrator.ts` (novos), `goal-delete.orchestrator.ts` (novo) e `apps/backend/test/goals*.e2e-spec.ts`.

- [ ] **e2e primeiro:**
  - `POST /goals` com `plannedDate` (single → 201 e um bloco a partir do dia; goal → 422);
  - `GET /goals?kind=single` e `?kind=xyz` → 400;
  - `PATCH /goals/:id/done` (single → 200 e os blocos futuros somem; desfazer → voltam; objetivo comum → 422; outro usuário → 404; 401; 400);
  - `DELETE /goals/:id` (200 e os blocos somem; outro usuário → 404; 401).
  - Guardar o **vermelho**.
- [ ] Prisma repository (`plannedDate`, `delete`), DTOs, controller/orquestradores e recálculo do plano.
- [ ] **Pedir ao orquestrador** o registro dos orquestradores novos.
- [ ] e2e verde, `test:e2e` inteiro verde e lint.

- [ ] **Orquestrador:** registrar os orquestradores em `orchestrators.module.ts` conforme os pedidos de B1 e B2; fazer merge de B1 e B2 na integração; `npm --workspace apps/backend run openapi:export` e commit do `packages/contracts/openapi.json`; conferir os testes HTTP do M1 e do M3 contra o `openapi.json` (rotas, campos e status).

---

## Fase 3: integração do mobile, ponta a ponta e visual (orquestrador, simulador iOS)

- [ ] Merge de M1, M2 e M3 na integração (ordem M1 → M2 → M3); `flutter analyze` e `flutter test` depois de cada um; conflito: parar e reportar. Ajustar só testes de integração entre telas (como o "conta de leituras" da rodada anterior), registrando o motivo.
- [ ] Backend **novo** no ar (build atual). **Não usar um backend antigo** que esteja na porta 4000: conferir com `lsof` e, se houver um processo antigo, pedir ao usuário para encerrar ou usar outra porta com um `env` temporário.
- [ ] **Teste novo primeiro**, `integration_test/compromissos_tarefas_test.dart` (usuário novo por execução, como o `acesso_perfil_test.dart`):
  - [ ] cadastro e onboarding com a grade inteira livre;
  - [ ] criar um objetivo com uma etapa → anotar o horário do bloco de hoje (ou do próximo dia);
  - [ ] Semana → "+ Compromisso" → "Toda semana" no dia e horário daquele bloco → o aviso "Bate com …" aparece → Salvar → toast "Plano recalculado" → o compromisso aparece na lista e a etapa mudou de horário (conferir no `GET /scheduling/plan/day`);
  - [ ] tocar no compromisso → "Não vai ter nesse dia" → pílula "Não vai ter" → "Vai ter sim" → some a pílula;
  - [ ] Editar → "Só nesse dia" → mudar o horário → "Horário alterado" → "Voltar pro horário normal";
  - [ ] Excluir → "Desse dia em diante" → o compromisso some desse dia e dos seguintes e continua nos anteriores (`GET …/occurrences`);
  - [ ] compromisso "Só uma vez" pelo botão do dia → aparece só naquele dia → Excluir;
  - [ ] Tarefas únicas (pela entrada da C9) → "Pagar a conta" 15 min Hoje → grupo Hoje e um bloco hoje no plano → marcar como feita → grupo Feitas e o bloco some → desmarcar → excluir;
  - [ ] "Sem data" e "Escolher dia" (o dia depois de amanhã) nos grupos certos;
  - [ ] Objetivos não lista as tarefas únicas (C8).
- [ ] Rodar o novo e os 3 antigos (`acesso_perfil`, `fluxo_principal` com `db:reset-demo`, `novo_objetivo_ia` com `AI_PROVIDER=rules`). Todos verdes.
- [ ] **Comparação visual** no simulador com as telas 44–54 (JPEG em `docs/mobile/comparacoes/`, só a rodada atual). Para preencher texto, usar o ponta a ponta ou o modo `sample` (o controle do simulador digitou no campo errado na rodada anterior). Listar as diferenças intencionais (C5, C9) e corrigir as não intencionais com o subagente dono.
- [ ] Encerrar os processos que esta rodada abriu (`flutter run`, backends extras), com `TaskStop`.

---

## Fase 4: verificação completa + revisor

- [ ] Trazer a `developer` mais recente para a integração (conflito: parar e reportar).
- [ ] Verificação completa, com a máquina livre (sem simulador nem backends extras):
  - [ ] `npm run build`
  - [ ] `npx turbo run lint`
  - [ ] `npm run test --workspaces --if-present` (100% no domínio)
  - [ ] `npm --workspace apps/backend run test:e2e` (se falhar só por estouro de tempo de 5 s, confirmar com a suíte sozinha e repetir com a máquina livre antes de concluir qualquer coisa)
  - [ ] `cd apps/mobile && flutter analyze` e `flutter test`
  - [ ] ponta a ponta da Fase 3 (já verdes)
  - [ ] grep de framework no domínio
- [ ] Cobertura de linhas dos arquivos novos ou alterados do mobile (`coverage/lcov.info`, só os arquivos do diff), para o relatório.
- [ ] **REVISOR** (subagente que não escreveu código; só aponta):
  - as regras;
  - as decisões MC1–MC14 cumpridas;
  - o contrato da seção 3 contra o código e o `openapi.json`;
  - os cenários da modelagem com teste (e teste antes do código, pela ordem dos commits);
  - posse em todos os repositórios e rotas;
  - recálculo do plano em toda mutação;
  - bugs (estado `busy`, `dispose`, `context` depois de `await`, edição sem carregar, como o bloqueante da rodada anterior);
  - os textos do design.
- [ ] Bloqueante → corrigido pelo autor original (SendMessage); não bloqueante → `afazeres.md`. Repetir a verificação depois das correções.

---

## Fase 5: integrar na `developer`

- [ ] Conferir: verificação completa verde e revisor sem bloqueante.
- [ ] `git checkout developer && git pull --ff-only origin developer && git merge --no-ff feat/compromissos-tarefas-unicas`.
- [ ] Na `developer`: `npm run build`, `npm run test --workspaces --if-present`, `flutter analyze` e `flutter test`.
- [ ] `git push origin developer`. O git já usa a conta ativa do `gh` (`arthursetragni`, configurada com `gh auth setup-git` em 19/11); se der 403, **parar e perguntar** ao usuário.
- [ ] Confirmar que a `main` não mudou (hash do passo 0.2).
- [ ] **Se qualquer passo da Fase 4 ou 5 falhar: NÃO fazer merge nem push.** Anotar o erro e reportar.

---

## Fase 6: fechamento

- [ ] `docs/mobile/COMO-TESTAR.md` e `docs/backend/COMO-TESTAR.md`: como testar compromissos e tarefas únicas (manual e ponta a ponta) e as rotas novas no Swagger.
- [ ] `docs/6-diario-execucao.md`: o resumo da rodada.
- [ ] `afazeres.md`: fechar o que foi resolvido; conferir que todas as pendências dos subagentes e do revisor estão lá.
- [ ] Apagar as worktrees `OiTenta-wt/*` (depois de conferir que estão limpas e integradas).
- [ ] Marcar `[x]` neste plano e anotar o hash do merge.
- [ ] Relatório ao usuário (seção 9 da regra):
  - (a) o que foi entregue, por subagente e branch;
  - (b) a verificação;
  - (c) a prova do TDD;
  - (d) o revisor;
  - (e) as diferenças em relação ao design;
  - (f) as pendências e as decisões novas;
  - (g) o estado da `developer` e da `main`;
  - (h) a **cobertura de testes de tudo o que foi implementado** (domínio, backend e mobile).
