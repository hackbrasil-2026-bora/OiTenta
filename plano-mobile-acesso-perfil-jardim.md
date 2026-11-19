# Plano: mobile (Acesso, Perfil e configurações, Jardim)

Criado em 19/11/2026, na rodada de investigação (nenhum código foi alterado). A próxima rodada executa este plano.

**Pedido do usuário:** implementar no app Flutter as telas do zip novo `design/mobile/Bora app anti-procrastinação telas principais.zip`:

- **Perfil**, aberto pelo botão com a inicial do usuário, com as configurações. **Ligado ao backend.**
- **Login** e **Criar conta**. **Ligados ao backend.**
- **Jardim**, igual ao modelo. **Só visual, sem backend.**

Tudo numa branch nova a partir da `developer`, com muitos testes unitários. Só vai para a `developer` com tudo verde; se algo falhar, nada vai para a `developer` e o erro é reportado ao usuário.

---

## Como usar este arquivo

- Cada passo tem uma caixa `- [ ]`. Quem executa o passo marca `- [x]` **assim que terminar**, e não antes.
- Quando um passo falhar, escreva logo abaixo dele `> ERRO: <comando> → <saída resumida>`, **pare** e reporte ao usuário. Não pule o passo e não contorne o erro (regra `processo-desenvolvimento.md`, seções 2, 5 e 6).
- Os blocos marcados **[PARALELO]** rodam em subagentes ao mesmo tempo, cada um na sua worktree e na sua branch. Os demais são do orquestrador, **na ordem**.
- Antes de começar, o orquestrador lê de novo: `CLAUDE.md`, `.agents/rules/*` (todas), `docs/2-decisoes-mvp.md`, `docs/4-contrato-api.md`, `docs/0-casos-de-uso.md` (UC25, UC32), `docs/0-fluxos.md` §7 e `design/mobile/app/SCREENS.md`.
- Cada subagente recebe o que a seção 8 da regra de processo exige: a tarefa (copiada deste arquivo), a branch, as pastas que pode alterar, os testes que escreve primeiro, os arquivos para ler, as skills, os critérios de pronto e a regra de processo inteira.

---

## 1. O que a investigação encontrou

### 1.1 O zip novo

- Só o `Bora App.dc.html` mudou: 209 KB → 263 KB. Os outros arquivos (`bora-data.js`, `support.js`, `Bora Telas.dc.html`, `uploads/`) são idênticos aos de `design/mobile/app/source/`.
- **Telas novas** no painel do protótipo:
  - grupo **Acesso**: Login, Criar conta, Esqueci a senha, Código, Nova senha;
  - aba **Compromissos** e **Novo compromisso**;
  - **Tarefas únicas**.
- **Mudança de navegação:**
  - a tab bar passou a ser **Hoje · Objetivos · Semana · Compromissos**. O Jardim saiu das abas;
  - o Jardim abre pelo **Broto do topo** (`aria-label="Abrir Jardim"`);
  - o topo (Broto + barra gamificada + botão "A") aparece no **Hoje e no Jardim**;
  - o botão "A" abre o **Perfil**. O "voltar" do Perfil leva ao Jardim, e no Perfil nenhuma aba fica ativa.
- **Perfil, Jardim, Redefinir rotina, Idioma e Enviar sugestão** estão **iguais** ao design antigo. As referências continuam sendo `design/mobile/app/screens/04`, `26`, `27`, `28` e `29`.
- **Comportamento do protótipo no Acesso:**
  - **Login:** o botão "Entrar" só habilita com e-mail válido e senha de pelo menos 6 caracteres. Tem olho para mostrar a senha, os links "Esqueci minha senha" e "Criar conta", e "Entrar com Google". Depois de entrar, vai para o Hoje com o toast "Oi de novo, Arthur!".
  - **Criar conta:** os campos são nome ("Como quer ser chamado?", pelo menos 2 caracteres), e-mail, senha (dica "Mínimo de 6 caracteres", com ícone que fica verde), confirmação ("As senhas batem" ou "As senhas ainda não estão iguais") e a caixa dos termos (obrigatória). Depois de criar, vai para o Hoje com o toast "Conta criada! Bem-vindo ao Bora, X.".
  - **Esqueci a senha:** são 3 passos (e-mail → código de 6 dígitos → nova senha). No protótipo, o código fixo é `482915`.
  - **Login e Criar conta não têm "Entrar como demo".**

### 1.2 O app mobile hoje (`apps/mobile`)

- Login e cadastro são **placeholder** (P27):
  - `features/auth/presentation/login_screen.dart` e `register_screen.dart`;
  - o `LoginController` só sabe fazer o demo.
- Jardim é **placeholder**: `features/gamification/presentation/garden_screen.dart`.
- **O Perfil não existe:**
  - o Hoje tem o botão "A" com `onProfile: null` (`features/scheduling/presentation/scheduling_pages.dart:99`);
  - o Broto do topo do Hoje não é botão.
- **Não há tema escuro:** só `BoraColors.light` e `AppTheme.light()`.
- A sessão fica **só em memória** (`SessionStore`). Pendência [DECIDIR] "Token do mobile só em memória" no `afazeres.md`.
- **O que já existe e será reaproveitado:**
  - o `AuthRepository` já tem `login`, `register`, `me` e `loginDemo`, com HTTP e exemplo, e testes;
  - o `SchedulingRepository` já tem `getAvailability` e `setAvailability`;
  - os widgets `BoraInput`, `BoraSwitch`, `BoraSlider`, `OptionCard`, `PrimaryButton`/`SecondaryButton`/`TertiaryButton`, `BoraCard`, `SectionHeader`, `Broto`, `GamifiedBar`, `showBoraToast` e `PlaceholderScreen`.
- Os ponta a ponta (`integration_test/*.dart`) entram pelo botão **"Entrar direto como Arthur (demo)"**.

### 1.3 O backend hoje

- **Endpoints que já existem:**
  - `POST /auth/register` → 201 `{ user }`. **Não devolve token**: o app precisa chamar `POST /auth/login` em seguida, como o web já faz (`apps/frontend/src/modules/auth/pages/login.page.tsx:86`);
  - `POST /auth/login` → `{ token, user }`; com credenciais inválidas, 401;
  - `GET /auth/me`;
  - `POST /auth/demo`;
  - `GET /scheduling/availability` e `PUT /scheduling/availability`. O PUT **já recalcula o plano** e devolve `{ availability, plan }`, que é o que "Salvar e recalcular plano" precisa.
- **Conflitos com o design** (ver as decisões na seção 2):
  - **senha:** o backend exige 8 ou mais caracteres, com maiúscula, minúscula, número e símbolo (`StrongPasswordRule`). O design diz "Mínimo de 6 caracteres";
  - **nome:** o `User` exige pelo menos 3 caracteres e **nome e sobrenome** (`PersonNameRule` exige duas palavras). O design pede "Como quer ser chamado? Ex.: Arthur" e aceita a partir de 2 caracteres. Hoje, "Arthur" sozinho recebe **422**.
- **Não há backend para:** Google, recuperação de senha, preferências (bloquear apps, lembrete, idioma), sugestão e gamificação.
- **Fuso:** o Flutter não dá o nome IANA do fuso sem pacote novo. O cadastro mobile omite `timezone`, e vale o padrão `America/Sao_Paulo` (P1).

### 1.4 Já decidido nos docs (sem pergunta nova)

- **Depois do login:** `GET /scheduling/availability`. Se responder 404, vai para o onboarding; se não, vai para o Hoje (P12).
- **Depois de criar conta:** register → login → **onboarding** (decisão 4b, que prevalece sobre o design, que manda para o Hoje). O toast "Conta criada! Bem-vindo ao Bora, X." aparece ao chegar no onboarding.
- **Jardim** com os valores fixos do protótipo, num repositório de exemplo (P18; [DECIDIR] "Endpoint de gamificação" segue recomendando manter).
- **Mensagens de erro:** 401 no login mostra "E-mail ou senha inválidos" (igual ao web). 409 e 422 do cadastro mostram a `message` do backend, como o web faz.
- Só tokens do tema, nada de cor fixa (`mobile-flutter.md`). Navegação só pelo go_router.

---

## 2. Portão 0: decisões para o usuário confirmar ANTES de executar

**Como responder:** marque `[x]` na opção escolhida de cada item. **Se você responder só "aprovado", vale a opção marcada como (recomendada).** O executor copia cada decisão para `docs/2-decisoes-mvp.md` (passo 0.5) e não começa sem a resposta (regra 5: ninguém decide um [DECIDIR] pelo usuário).

**D1. Regra da senha no cadastro**
- [x] (a) **(recomendada)** Manter a regra do backend (8 ou mais caracteres, maiúscula, minúscula, número e símbolo). A dica da tela muda para "Mínimo de 8 caracteres, com maiúscula, minúscula, número e símbolo", com o ícone verde quando tudo for atendido, e o app confere a mesma regra antes de enviar. Diferença de texto registrada. Motivo: não enfraquecer a segurança, e o web já usa essa regra.
- [ ] (b) Mudar o backend para "mínimo 6, sem outra exigência" (troca a regra no `RegisterUser` e nos testes do domínio e e2e). Afeta o web também.

**D2. Nome com uma palavra só ("Arthur")**
- [x] (a) **(recomendada)** Mudar o domínio: o nome passa a aceitar uma palavra ou mais, só com letras (acentos, hífen e apóstrofo valem), de 2 a 80 caracteres. É uma regra nova no `packages/shared` (`DisplayNameRule`, criada pela skill `shared-validation-rule`) usada pelo `User` no lugar de `PersonNameRule` + `MinLengthRule(3)`. O web também passa a aceitar.
- [ ] (b) Manter o backend: o campo do app continua "Como quer ser chamado?", mas um nome sem sobrenome recebe 422 e a mensagem "Digite nome e sobrenome", o que contradiz o design.

**D3. "Entrar com Google"**
- [x] (a) **(recomendada)** Esconder o botão e o divisor "ou" até existir login com Google. Diferença registrada, e um [EXECUTAR] futuro no `afazeres.md`.
- [ ] (b) Mostrar como no design; o toque mostra o toast "Em breve" (texto que não está no design).

**D4. "Esqueci minha senha" (o backend não envia e-mail)**
- [a] (a) **(recomendada)** O link aparece como no design e abre um **placeholder** "Esqueci minha senha" (nome da tela e "Voltar pro login", regra 4i). As 3 telas do design ficam para quando houver backend de recuperação: [DECIDIR] no `afazeres.md` sobre o provedor de e-mail.
- [ ] (b) Fazer as 3 telas só visuais, com repositório de exemplo (código `482915`). Desvantagem: diz "Senha redefinida!" sem redefinir nada.
- [ ] (c) Esconder o link.

**D5. Botão de demo (a decisão 5.4 e os ponta a ponta dependem dele; o design novo não tem)**
- [ ] (a) **(recomendada)** Manter "Entrar direto como Arthur (demo)" como botão terciário no fim do Login, abaixo de "Ainda não tem conta? Criar conta". Diferença registrada.
- [x] (b) Mostrar só quando `SHOW_DEMO=true` no `env/*.json` (lido no `AppConfig`). Ligado em `local-*` e `developer`, desligado em `prod`.
- [ ] (c) Remover; os ponta a ponta passam a digitar e-mail e senha do demo.

**D6. Subtítulo do Perfil ("Ciência da Computação · 21 anos" não existe no backend)**
- [x] (a) **(recomendada)** Mostrar o e-mail do usuário (`GET /auth/me`).
- [ ] (b) Texto fixo do protótipo (como na P18).
- [ ] (c) Criar os campos curso e idade no `User` (migration, contrato, cadastro). Fora do prazo.

**D7. "Modo escuro" no Perfil**
- [x] (a) **(recomendada)** Funciona de verdade, com a paleta escura do design (`[data-theme="dark"]` do `Bora App.dc.html`, referência `screens/30-hoje-tema-escuro.png`), **guardado só em memória**: fechar o app volta ao claro, igual ao token (pendência já registrada).
- [ ] (b) Interruptor só visual, sem trocar o tema.

**D8. "Bloquear apps durante o foco", "Lembrete da rampa" e "Idioma" (sem backend e sem recurso no app)**
- [x] (a) **(recomendada)** Visual, como no protótipo:
  - "Bloquear apps" é um interruptor que liga e desliga em memória, sem efeito;
  - "Lembrete da rampa" mostra 09:30 fixo;
  - "Idioma" abre o sheet com as 3 opções (M28), marca a escolhida e muda o texto da linha, mas o app continua em português.
  - Cada um vira item no `afazeres.md`.
- [ ] (b) Esconder as três linhas até existirem de verdade.

**D9. "Enviar sugestão" (M29)**
- [ ] (a) **(recomendada)** **Ligar ao backend:**
  - módulo de negócio novo `feedback`, com a entidade `Feedback { userId, message (1–2000), createdAt }`, o caso de uso `SendFeedback` e o endpoint `POST /feedback` `{ message }` → 201 `{ feedback{ id, message, createdAt } }`;
  - erros: 400, 401 e 422;
  - "Anexar print (opcional)" aparece, mas **desabilitado**: o anexo exige pacote novo (`image_picker`) e armazenamento de arquivo, e vira [DECIDIR] no `afazeres.md`;
  - "contato@bora.app" é texto, sem link (abrir o e-mail exigiria `url_launcher`).
- [x] (b) Só visual: o repositório de exemplo não envia nada, mas mostra o toast "Sugestão enviada". Desvantagem: diz que enviou sem enviar.
- [ ] (c) Esconder a linha "Enviar sugestão".

**D10. Tab bar (o design novo troca a aba Jardim por Compromissos)**
- [x] (a) **(recomendada)** Manter **Hoje · Objetivos · Semana · Jardim** e **também** fazer o Broto do topo abrir o Jardim, como no design. Compromissos entra numa rodada própria, porque exige endpoint e migration (pendência da P8 e [DECIDIR] "Compromissos fixos").
- [ ] (b) Seguir o design: a 4ª aba vira Compromissos com placeholder, e o Jardim só abre pelo Broto.

**D11. "Redefinir minha rotina" (M27): a grade do design × a grade do onboarding**
- **Contexto:** o design mostra uma grade de 2 em 2 horas, das 8h às 22h (7 linhas × 7 dias). O onboarding grava janelas de manhã (6–12), tarde (12–18) e noite (18–23).
- [x] (a) **(recomendada)**
  - Ao abrir a tela, uma célula aparece "Livre" se o intervalo inteiro dela estiver dentro de uma janela salva.
  - Ao salvar, células vizinhas do mesmo dia viram uma janela só, e a grade **substitui** a disponibilidade inteira. O que estava fora de 8h–22h (6–8h e 22–23h do onboarding) deixa de valer.
  - A tela mostra exatamente o que será salvo. Regra registrada nas decisões.
- [ ] (b) Preservar as janelas fora da grade, juntando-as às novas. Desvantagem: horário livre que o usuário não vê na tela.

**D12. Sair da conta (o design do Perfil não tem)**
- [x] (a) **(recomendada)** Não criar agora. Como a sessão fica em memória, fechar o app já desloga. Fica um [DECIDIR] no `afazeres.md`, ligado ao do token.
- [ ] (b) Criar a linha "Sair da conta" no fim do Perfil (elemento sem design).

**D13. "Trocar por 50" (guarda-chuva) no Jardim**
- [ ] (a) **(recomendada)** Como no protótipo, só em memória na tela: −50 gotas, +1 guarda-chuva e o toast "−50 gotas · Guarda-chuva guardado · você tem N". O botão fica desabilitado com menos de 50 gotas. Nada é salvo.
- [x] (b) Botão sem ação (como o "Comprar" do web, ainda em [DECIDIR]).

**D14. Atualizar `design/mobile/app/` com o zip** (o `CLAUDE.md` pede autorização para mexer em `design/`)
- [x] (a) **(recomendada)** Sim:
  - substituir `source/Bora App.dc.html` pelo do zip;
  - capturar as telas novas em `screens/` (33 em diante);
  - atualizar o `SCREENS.md`;
  - o zip em si **não** é commitado.
- [ ] (b) Não: os subagentes leem o HTML direto do zip extraído numa pasta temporária.

---

## 3. Mapa de paralelização

```
Fase 0 (orquestrador, sequencial)
  0.1 decisões → 0.2 branch → 0.3 linha de base → 0.4 design → 0.5 docs → 0.6 esqueleto compartilhado (TDD) → 0.7 worktrees
                                                                                      │
Fase 1 [PARALELO] ────────────────────────────────────────────────────────────────────┤
  S1 Backend: nome (D2) + domínio do feedback (D9)      branch feat/mob-r-backend
  S2 Mobile Acesso (login, cadastro, placeholder)       branch feat/mob-r-acesso
  S3 Mobile Perfil + Idioma + preferências              branch feat/mob-r-perfil
  S4 Mobile Redefinir rotina + Enviar sugestão          branch feat/mob-r-rotina-sugestao
  S5 Mobile Jardim (visual)                             branch feat/mob-r-jardim
  S6 Mobile Tema escuro (paleta + AppTheme.dark)        branch feat/mob-r-tema-escuro
                                                                                      │
Fase 2 (orquestrador): integra as branches + prisma do feedback → S1 continua (prisma repo + controller + e2e)
Fase 3 (orquestrador): ponta a ponta no simulador iOS + comparação visual
Fase 4: verificação completa + subagente REVISOR → correções pelos autores
Fase 5: merge na developer (só com tudo verde) + push
Fase 6: relatório, afazeres, diário, COMO-TESTAR
```

- **Branch de integração:** `feat/mobile-acesso-perfil-jardim`, criada da `developer`. As branches dos subagentes saem dela, depois do passo 0.6, e voltam para ela. Só ela vai para a `developer`.
- **Arquivos que só o orquestrador altera** (evitam conflito entre os subagentes):
  - `package.json` e `package-lock.json` da raiz, `turbo.json`, `apps/backend/src/app.module.ts`, `apps/backend/prisma/**`, `packages/contracts/openapi.json`, `afazeres.md`, `docs/**`, `.agents/**` e `design/**`;
  - no mobile: `lib/core/routes/*`, `lib/core/di/app_dependencies.dart`, `lib/app.dart`, `lib/core/widgets/app_shell.dart`, `lib/features/scheduling/presentation/scheduling_pages.dart` e `today_screen.dart`, `pubspec.yaml`, `env/*` e `integration_test/*`.
- Se D9 for (b) ou (c), S1 faz só a parte do nome. Se D2 for (b), S1 faz só o feedback. Se as duas forem (b)/(c), S1 não existe.
- Se D7 for (b), S6 não existe.

---

## Fase 0: preparação (orquestrador)

### 0.1 Decisões
- [x] Usuário respondeu o Portão 0 (seção 2). Anotar aqui as escolhas: D1 a · D2 a · D3 a · D4 a · D5 **b** · D6 a · D7 a · D8 a · D9 **b** · D10 a · D11 a · D12 a · D13 **b** · D14 a (com o zip commitado a pedido do usuário em 19/11)
- [x] Ajustar os passos abaixo que dependem de uma opção diferente da recomendada
  > Ajustes: D5 = b → `SHOW_DEMO` no `AppConfig` e nos `env/*.json` (passo 0.6), `deps.showDemo`; D9 = b → S1 sem a parte B, S4 sem HTTP do feedback, Fase 2 sem a parte "Feedback no backend"; D13 = b → "Trocar por 50" sem ação no S5. (riscar o que não se aplica e anotar o motivo).

### 0.2 Branch
- [x] `git checkout developer && git pull --ff-only origin developer`.
  > A `developer` remota não tinha mudanças (19/11). O plano e o zip, soltos na `developer` local, foram para o primeiro commit da branch (`7b58f43`).
- [x] `git checkout -b feat/mobile-acesso-perfil-jardim`.
- [ ] Confirmar que a `main` não foi tocada: `git log origin/main -1` antes e depois da rodada, com o mesmo hash.

### 0.3 Linha de base (para separar falha antiga de falha nova)
- [x] `npm --workspace apps/backend run db:start` e `npm --workspace apps/backend run prisma:generate`.
- [x] `npm run build`, `npx turbo run lint`, `npm run test --workspaces --if-present`, `npm --workspace apps/backend run test:e2e`.
- [x] `cd apps/mobile && flutter pub get && flutter analyze && flutter test`.
- [x] Anotar aqui o resultado (verde ou a falha exata).
  > Linha de base verde: build, lint (9 workspaces), testes de todos os workspaces, e2e do backend; `flutter analyze` sem problemas; 238 testes do mobile. Se algo já falhar na `developer`, **parar e reportar** antes de mudar qualquer coisa.

### 0.4 Design (se D14 = a)
- [x] Extrair o zip numa pasta temporária vazia e copiar só o `Bora App.dc.html` para `design/mobile/app/source/` (os demais arquivos são idênticos; conferir com `cmp`).
- [x] Capturar as telas novas com Playwright (`node_modules/playwright` da raiz):
  - viewport 390×844, deviceScaleFactor 2, só a moldura do celular, como as capturas anteriores;
  - clicar nos botões do painel "Bora · protótipo" pelo nome;
  - arquivos: `33-acesso-login.png`, `34-acesso-criar-conta.png`, `35-acesso-criar-conta-preenchido.png` (dicas verdes e termos marcados), `36-acesso-esqueci.png`, `37-acesso-codigo.png`, `38-acesso-nova-senha.png`, `39-jardim-pelo-broto.png` (topo com Broto + barra + "A" e a tab bar nova), `40-perfil-tab-bar-nova.png`, `41-compromissos.png`, `42-novo-compromisso.png`, `43-tarefas-unicas.png`;
  - o script fica numa pasta temporária, fora do repositório.
- [x] Atualizar o `design/mobile/app/SCREENS.md`:
  - linhas 33–43;
  - nas Observações: a tab bar nova, o Jardim pelo Broto e o fato de Login e Cadastro agora terem design;
  - corrigir "Não há login, cadastro nem onboarding" para refletir o design novo (o onboarding continua sem).
- [x] Commit `docs(design): telas novas do Bora App
  > `6608513`. (acesso, compromissos, tarefas únicas)`. O zip **não** entra.

### 0.5 Documentação das decisões e do contrato
- [x] `docs/2-decisoes-mvp.md`: nova seção "Decisões da rodada mobile Acesso/Perfil/Jardim (MP1–MP14, numeradas como D1–D14 deste plano), 19/11/2026", com cada D do Portão 0 no formato das P (contexto, decisão, motivo, consequências, status). Atualizar a P27: Login e Cadastro deixam de ser placeholder.
- [x] `docs/4-contrato-api.md`:
  - §1, coluna Mobile: M33/M34 no lugar de "placeholder";
  - se D2 = a, a regra do nome em `POST /auth/register` (422 `display.name`);
  - se D9 = a, nova seção `POST /feedback` (corpo, resposta, erros, caso de uso, tela M29) e a linha no mapa da §6.
- [x] `afazeres.md`, seção Mobile e seção Backend, com referência cruzada: um item para cada diferença e cada pendência criada pelas decisões. São eles: Google (D3); recuperação de senha (D4); idioma, bloquear apps e lembrete (D8); anexo da sugestão (D9); Compromissos e Tarefas únicas com design novo, que ficam para outra rodada (D10); horários fora de 8–22h (D11); sair da conta (D12); fuso IANA no cadastro mobile (pacote).
- [x] `docs/6-diario-execucao.md`: entrada "19/11/2026: início da rodada mobile Acesso/Perfil/Jardim", com o link para este plano.
- [x] Commit `docs: decisões, contrato e afazeres
  > `13890ab`. da rodada mobile acesso/perfil/jardim`.

### 0.6 Esqueleto compartilhado do mobile (TDD: teste vermelho → verde, guardar as saídas)

Objetivo: deixar rotas, dependências e topo prontos para os subagentes mexerem **só** nas pastas deles.

- [x] **Testes primeiro** (`test/core/routes_perfil_jardim_test.dart`
  > Arquivo: `test/core/shell_perfil_jardim_test.dart` (17 testes; inclui `SHOW_DEMO` e `deps.feedback`)., `test/features/gamification/home_top_bar_test.dart`):
  - as rotas `/perfil`, `/perfil/rotina`, `/perfil/sugestao` e `/entrar/esqueci` existem e abrem uma tela com o título certo;
  - `tabFor('/perfil')`, `tabFor('/perfil/rotina')` e `tabFor('/perfil/sugestao')` devolvem `AppTab.garden` (no design, o Perfil pertence ao grupo do Jardim). Se D10 = b, ajustar;
  - no Hoje, tocar o botão "Perfil" (a inicial) leva a `/perfil`, e tocar "Abrir Jardim" (o Broto) leva a `/jardim`;
  - `HomeTopBar` mostra o Broto como botão com o rótulo "Abrir Jardim", a barra gamificada e o botão "Perfil" com a inicial do nome; sem nome, o botão fica sem letra;
  - `ThemeController` começa em `ThemeMode.light`; `toggle()` troca para dark e avisa os ouvintes; `isDark` reflete o modo;
  - `BoraApp` usa `deps.theme.mode` no `MaterialApp.router` (`themeMode`), e trocar o modo reconstrói o app com o tema escuro.
- [x] Rodar e guardar a saída **vermelha**.
  > Vermelho: não compilava (66 erros de símbolos inexistentes: `ThemeController`, `HomeTopBar`, `ProfilePage`, `AppRoutes.profile`…).
- [x] **Implementar:**
  - `core/routes/app_routes.dart`: `profile = '/perfil'`, `profileRoutine = '/perfil/rotina'`, `profileSuggestion = '/perfil/sugestao'`, `forgotPassword = '/entrar/esqueci'`;
  - `core/routes/app_router.dart`: rotas novas; as de perfil ficam **dentro** do `ShellRoute` (tab bar visível, como no design) e `forgotPassword` fica fora. Cada rota aponta para uma *Page* do subagente, ainda como `PlaceholderScreen` com o título da tela: `ProfilePage` (`features/profile/presentation/profile_pages.dart`), `RoutinePage` e `SuggestionPage` (`features/profile/presentation/routine_suggestion_pages.dart`), `ForgotPasswordPage` (em `auth_pages.dart`), e o `GardenPage` (`features/gamification/presentation/garden_pages.dart`) no lugar de `const GardenScreen()`;
  - `tabFor`: `/perfil` → `AppTab.garden`;
  - `core/theme/theme_controller.dart`: `ThemeController extends ChangeNotifier { ThemeMode mode; bool get isDark; void toggle(); }`, só em memória (D7);
  - `core/theme/app_theme.dart`: `static ThemeData dark()` provisório, que devolve `light()`. O S6 troca pela paleta escura;
  - `core/di/app_dependencies.dart`: `ThemeController theme` (padrão novo) e, se D9 = a, `FeedbackRepository feedback`: `SampleFeedbackRepository` no modo `sample` e `HttpFeedbackRepository(api)` no modo `http`. Interface e classes vazias criadas em `features/profile/data/`, que o S4 completa;
  - `app.dart`: `AnimatedBuilder`/`ListenableBuilder` em `deps.theme`, com `theme: AppTheme.light()`, `darkTheme: AppTheme.dark()` e `themeMode: deps.theme.mode`;
  - `features/gamification/presentation/home_top_bar.dart`: o widget `HomeTopBar({gamification, userName, onBroto, onProfile})`, extraído do `TodayScreen`;
  - `TodayScreen` passa a usá-lo, e o `TodayPage` liga `onProfile: () => context.push(AppRoutes.profile)` e `onBroto: () => context.go(AppRoutes.garden)`.
- [x] Rodar e guardar a saída **verde**.
  > Verde: `+17: All tests passed!`; suíte inteira 255 testes; `flutter analyze` sem problemas. Rodar `flutter analyze` e `flutter test` (tudo verde, inclusive os testes antigos do Hoje).
- [x] Commit `feat(mobile): rotas, tema e topo compartilhado
  > `82273f3`. para perfil e jardim`.

### 0.7 Worktrees
- [x] Uma worktree por subagente da Fase 1
  > Em `/Users/arthursetragni/Hackaton/OiTenta-wt/<nome>`., cada uma com a sua branch criada a partir da `feat/mobile-acesso-perfil-jardim` (nomes na seção 3).
- [x] Em cada worktree (P28): `npm ci` na raiz e `flutter pub get` em `apps/mobile`. Nas do backend, também `npm --workspace apps/backend run prisma:generate`.

---

## Fase 1 [PARALELO]: subagentes

Regras comuns a todos:
- TDD com prova (saída vermelha e depois verde no relatório).
- Nada de `npm install` nem dependência nova.
- Nenhum merge ou push.
- Só tokens do tema.
- Telas só recebem dados e callbacks; um `ChangeNotifier` por tela; backend só em `data/`.
- Relatório fixo: branch, arquivos, vermelho→verde, comandos com saída, pendências e problemas, estes já no formato do `afazeres.md`.

### S1. Backend e domínio (`feat/mob-r-backend`)

**Pastas permitidas:** `packages/shared/src/validation/**`, `modules/auth/**`, `modules/feedback/**` (depois que o orquestrador criar o módulo), `apps/backend/src/modules/feedback/**` e `apps/backend/test/*.e2e-spec.ts`.

**Parte A: nome com uma palavra (se D2 = a)**
- [x] Skill `shared-validation-rule` para criar a `DisplayNameRule` (código `display.name`). Testes primeiro, com 100% de cobertura:
  - aceita "Arthur", "Ana Souza", "João-Pedro", "D'Ávila" e "Ana  Souza" (espaços extras no meio, mesmo comportamento da `PersonNameRule`);
  - recusa "", "   ", "Arthur2", "@na", "Ana_" e valor que não é string (mesmo contrato das outras regras).
- [x] `modules/auth/src/user/model/user.entity.ts`: `name` com `RequiredRule`, `MinLengthRule(2)`, `MaxLengthRule(80)` e `DisplayNameRule` (sai a `PersonNameRule` e a `MinLengthRule(3)`). Testes primeiro: "Arthur" é válido; "A" é inválido; os testes antigos de nome continuam ou são ajustados, com o motivo anotado.
- [x] `RegisterUser`: teste de que "Arthur" cadastra.
- [x] `apps/backend/test/auth.e2e-spec.ts`: `POST /auth/register` com `name: "Arthur"` responde 201, e com `name: "A"` responde 422.
- [x] `npm run test --workspace @oitenta/shared` e `--workspace @oitenta/auth`, com cobertura de 100%.

**Parte B: domínio do feedback (se D9 = a).** O orquestrador roda antes a skill `config-new-module` (`feedback`, namespace `@oitenta`), porque ela mexe no `package.json` da raiz e no `app.module.ts`. Passo F1.0 abaixo.
- [x] ~~ **F1.0 (orquestrador, antes de liberar a parte B):** `config-new-module feedback @oitenta` na branch de integração; build e testes do módulo verdes; commit; rebase da `feat/mob-r-backend`.~~ — não se aplica (D9 = b, sem backend de sugestão)
- [x] ~~ Skill `module-aggregate`: agregado `feedback` (`model/`, `provider/`, `usecase/`).~~ — não se aplica (D9 = b, sem backend de sugestão)
- [x] ~~ Skill `module-entity`: `Feedback { userId (uuid), message (1–2000, sem só espaços), createdAt }`. Testes primeiro: válido; mensagem vazia, só espaços ou com 2001 caracteres é inválida; `userId` obrigatório.~~ — não se aplica (D9 = b, sem backend de sugestão)
- [x] ~~ Skill `module-repository`: `FeedbackRepository` (só `create`, com o `userId` na entidade) + implementação em memória para os testes.~~ — não se aplica (D9 = b, sem backend de sugestão)
- [x] Skill `module-use-case`: `SendFeedback({ userId, message })` → `{ feedback{ id, message, createdAt } }`. Testes primeiro: grava com o `userId` recebido; mensagem com espaços nas pontas é aparada; mensagem inválida dá `ValidationException` e não grava nada; o `userId` nunca vem do corpo (o caso de uso recebe o `userId` já separado).
- [x] ~~ `npm run test --workspace @oitenta/feedback`, com cobertura de 100%.~~ — não se aplica (D9 = b, sem backend de sugestão)
- [x] Grep de framework no domínio (seção 4 da regra) sem nada novo.
- [x] ~~ **Parar aqui** e reportar. A parte de prisma, controller e e2e é a Fase 2.~~ — não se aplica (D9 = b, sem backend de sugestão)

### S2. Mobile Acesso (`feat/mob-r-acesso`)

**Pastas permitidas:** `apps/mobile/lib/features/auth/**` e `apps/mobile/test/features/auth/**`.
**Ler antes:** o template `<!-- LOGIN -->` e `<!-- CRIAR CONTA -->` do `Bora App.dc.html` e a lógica `loginOk`, `cdOk`, `cdConf*` e `cdSenha*` (procurar `const loginOk`); `screens/33–35`; `test/features/auth/*`; `apps/frontend/src/modules/auth/pages/login.page.tsx` (fluxo register → login).

- [x] **Testes do `LoginController` primeiro** (`test/features/auth/login_controller_test.dart`, ampliado):
  - `canSubmit` é falso com e-mail inválido (`"a@b"`, `"arthur"`, vazio) ou senha com menos de 6 caracteres, e verdadeiro com e-mail válido e senha de 6 ou mais;
  - os espaços em volta do e-mail são aparados antes de validar e de enviar;
  - `toggleObscure()` troca `obscure` e avisa os ouvintes;
  - `submit()` com sucesso salva a sessão; sem disponibilidade (`null`) devolve `AfterLogin.onboarding`, e com ela devolve `AfterLogin.today`;
  - `submit()` com `UnauthorizedFailure` mostra "E-mail ou senha inválidos", não salva a sessão e termina com `busy = false`;
  - `submit()` com `NetworkFailure` mostra "Não deu pra entrar agora. Tenta de novo?";
  - `submit()` enquanto `busy` é ignorado (o repositório é chamado uma vez só);
  - `submit()` com `canSubmit` falso não chama o repositório;
  - `enterDemo()` mantém os testes atuais (D5 = a).
- [x] **Testes do `RegisterController` primeiro** (`test/features/auth/register_controller_test.dart`):
  - `nameOk`: 2 ou mais caracteres depois de aparar (D2). Se D2 = b, exige duas palavras;
  - `passwordOk` segue a D1 (a: 8 ou mais caracteres com maiúscula, minúscula, número e símbolo; b: 6 ou mais);
  - `confirmVisible` só aparece com a confirmação preenchida; `confirmOk` exige `passwordOk` e as duas senhas iguais; `confirmText` é "As senhas batem" ou "As senhas ainda não estão iguais";
  - `toggleTerms()`; `canSubmit` exige nome, e-mail, senha, confirmação e termos;
  - `submit()` chama `register(name aparado, email aparado, password)` sem `timezone`, depois `login(email, password)`, salva a sessão e devolve `true`. A ordem das chamadas é verificada;
  - `ConflictFailure` (409) e `ValidationFailure` (422) mostram a `message` do backend e não salvam a sessão;
  - se o `register` funcionar e o `login` falhar: mensagem de erro e nenhuma sessão salva;
  - `firstName` ("Ana Souza" → "Ana") alimenta o toast "Bem-vindo ao Bora, Ana.".
- [x] Rodar e guardar o **vermelho**.
- [x] **Implementar:** `login_controller.dart` (estende o atual) e `register_controller.dart` (novo).
- [x] **Widget tests primeiro** (`login_screen_test.dart` e `register_screen_test.dart`):
  - **Login:**
    - Broto, "Que bom te ver!" e "Entra aí pra continuar de onde parou.", os rótulos "E-mail" e "Senha" e os placeholders "seu@email.com" e "Sua senha";
    - "Entrar" desabilitado até os dados serem válidos;
    - o olho alterna o texto oculto (rótulo de acessibilidade "Mostrar senha"/"Esconder senha");
    - "Esqueci minha senha" chama `onForgot`, e "Criar conta" chama `onRegister`;
    - o erro aparece com `Semantics(liveRegion)`;
    - "Entrar com Google" e o "ou" **não** aparecem (D3 = a);
    - o botão de demo aparece (D5 = a).
  - **Criar conta:**
    - voltar; "Criar sua conta" e o subtítulo; os 4 campos com os rótulos do design ("Como quer ser chamado?", "E-mail", "Senha", "Confirme sua senha");
    - a dica da senha (texto da D1) fica verde quando a senha vale;
    - as mensagens da confirmação; a caixa dos termos ("Li e aceito os Termos de uso e a Política de privacidade");
    - "Criar conta" desabilitado até tudo valer; "Já tem conta? Entrar" chama `onLogin`.
- [x] **Implementar as telas** a partir do `.dc.html` + `screens/33–35`:
  - `login_screen.dart` e `register_screen.dart` (saem do `PlaceholderScreen`);
  - campo de senha com olho: estender o `BoraInput` **dentro** de `features/auth/presentation/` (por exemplo, `password_field.dart`). Se for preciso mudar `core/widgets/bora_input.dart`, parar e pedir ao orquestrador.
- [x] **Implementar `auth_pages.dart`:**
  - `LoginPage`: Entrar → `context.go(today|onboarding)` + toast "Oi de novo, {nome}!" / "Seu plano tá do jeitinho que você deixou.";
  - `RegisterPage` com `ControllerHost<RegisterController>`: sucesso → `context.go(AppRoutes.onboarding)` + toast "Conta criada!" / "Bem-vindo ao Bora, {primeiro nome}.";
  - `ForgotPasswordPage`: placeholder "Esqueci minha senha" + "Voltar pro login" (D4 = a).
- [x] Teste do fluxo de páginas (`login_flow_test.dart`, com `TestApp` e `SampleAuthRepository`/fakes):
  - login válido sem disponibilidade → onboarding;
  - com disponibilidade → Hoje;
  - Criar conta → onboarding com o toast;
  - Esqueci → placeholder → Voltar → login.
- [x] Verde; `flutter analyze` sem avisos; `flutter test` inteiro verde.

### S3. Mobile Perfil + Idioma + preferências (`feat/mob-r-perfil`)

**Pastas permitidas:** `apps/mobile/lib/features/profile/presentation/profile_*.dart`, `language_sheet.dart`, `apps/mobile/lib/features/profile/domain/**` e `apps/mobile/test/features/profile/profile_*`.
**Ler antes:** o template `<!-- PERFIL -->`, o sheet de idioma (procurar `sheetIdioma`), `screens/26`, `28` e `40`; os repositórios `auth` e `scheduling`; o `core/theme/theme_controller.dart`.

- [x] **Testes do `ProfileController` primeiro** (`test/features/profile/profile_controller_test.dart`, com fakes de `AuthRepository`, `SchedulingRepository` e `ThemeController`):
  - `load()` chama `me()` e `getAvailability()` **em paralelo**; preenche `name`, `initial` (primeira letra maiúscula), `subtitle` = e-mail (D6 = a) e `dailyLimitText` (240 → "4h", 210 → "3h30", 60 → "1h");
  - sem disponibilidade (`null`), `dailyLimitText` = "—";
  - se `me()` falhar, usa o usuário da `SessionStore` e mostra um erro discreto; se `getAvailability()` falhar, mostra "—" e um erro;
  - `loading` é verdadeiro durante a carga e falso no fim, com sucesso ou erro;
  - `isDark` e `themeText` ("Claro"/"Escuro") vêm do `ThemeController`, e `toggleDark()` chama `theme.toggle()`;
  - `blockApps` começa ligado (como no design) e `toggleBlockApps()` alterna, só em memória (D8 = a);
  - `reminderText` = "09:30" (fixo, D8);
  - `language` começa em `pt`; `languageName` é "Português (Brasil)", "English" ou "Español"; `selectLanguage('en')` muda o nome e avisa os ouvintes (o app continua em português, D8).
- [x] Vermelho → implementar `profile_controller.dart` (+ `domain/profile_view.dart`, se ajudar) → verde.
- [x] **Widget tests primeiro** (`profile_screen_test.dart`):
  - avatar com a inicial, o nome e o subtítulo;
  - a seção "Preferências", com "Modo escuro" e "Tema atual: Claro", o interruptor de bloquear apps ligado, "Máximo por dia 4h" e "Lembrete da rampa 09:30";
  - a seção "Configurações": "Redefinir minha rotina" chama `onRoutine`, "Idioma" com "Português (Brasil)" abre o sheet, e "Enviar sugestão" chama `onSuggestion`;
  - o sheet "Idioma" tem as 3 opções, a atual marcada com check, e escolher outra fecha o sheet e muda a linha;
  - o botão voltar chama `onBack`.
- [x] **Implementar** `profile_screen.dart`, `language_sheet.dart` e `profile_pages.dart`:
  - `ProfilePage` com `ControllerHost<ProfileController>(create: ProfileController(deps.auth, deps.scheduling, deps.session, deps.theme))`;
  - voltar: `context.canPop() ? pop : go(garden)`;
  - Redefinir rotina: `context.push(AppRoutes.profileRoutine)`; Enviar sugestão: `context.push(AppRoutes.profileSuggestion)`;
  - ao voltar da rotina, recarregar (o "Máximo por dia" muda).
- [x] Teste de página: tocar "Modo escuro" troca o `ThemeMode` do app (com o `ThemeController` real).
- [x] Verde; `flutter analyze`; `flutter test`.

### S4. Mobile Redefinir rotina + Enviar sugestão (`feat/mob-r-rotina-sugestao`)

**Pastas permitidas:** `apps/mobile/lib/features/profile/presentation/routine_*.dart`, `suggestion_*.dart`, `routine_suggestion_pages.dart`, `apps/mobile/lib/features/profile/data/**` (feedback), `apps/mobile/lib/features/profile/domain/feedback.dart`, `routine_grid.dart` e `apps/mobile/test/features/profile/routine_*`, `suggestion_*` e `*feedback*`.
**Ler antes:** os templates `<!-- REDEFINIR ROTINA -->` e `<!-- ENVIAR SUGESTÃO -->` e a lógica `rotina`, `defaultRotina` e `enviarSug`; `screens/27` e `29`; o `OnboardingController` (como monta as janelas); `docs/4-contrato-api.md` §2 e a seção nova do feedback.

**Redefinir rotina**
- [x] **Testes primeiro** (`routine_grid_test.dart`, classe pura `RoutineGrid` em `domain/routine_grid.dart`):
  - linhas 8h, 10h, …, 20h (7 linhas de 2h) × 7 dias (Seg…Dom = `weekday` 0…6);
  - `fromWindows`: a janela 12:00–18:00 da segunda marca as células 12h, 14h e 16h da segunda; 06:00–12:00 marca 8h e 10h; 18:00–23:00 marca 18h e 20h; 09:00–11:00 não marca nada (cobre só parte das células); janelas de dias diferentes não se misturam;
  - `toWindows`: as células 14h, 16h e 18h da segunda viram **uma** janela 14:00–20:00; células separadas (10h e 14h) viram duas janelas; o resultado vem ordenado por dia e hora;
  - ida e volta `fromWindows(toWindows(x)) == x`;
  - `freeHours` = células × 2 ("52h livres por semana").
- [x] **Testes do `RoutineController` primeiro:**
  - `load()` lê `getAvailability()` e preenche a grade e o limite (240 → 4h); com `null`, grade vazia e limite de 4h;
  - `toggle(dia, linha)` alterna e avisa os ouvintes;
  - `setLimitHours` limita a 1–8;
  - `canSave` é falso com zero células (o backend responde 422 sem janelas);
  - `save()` chama `setAvailability(WeeklyAvailability(windows: grid.toWindows(), dailyLimitMinutes: h*60))` e devolve `true`;
  - com `ValidationFailure`, mostra a mensagem e devolve `false`; `saving` termina falso.
- [x] Implementar `routine_grid.dart` e `routine_controller.dart` → verde.
- [x] **Widget tests primeiro:**
  - título "Redefinir minha rotina" e o subtítulo do design;
  - cabeçalho Seg…Dom e linhas 8h…20h; tocar uma célula pinta e despinta;
  - a legenda "Livre"/"Ocupado" e "Nh livres por semana";
  - "Limite diário" com o valor e o slider;
  - "Salvar e recalcular plano" desabilitado sem células e chamando `onSave` com células.
- [x] Implementar `routine_screen.dart` e a `RoutinePage`: sucesso → toast "Plano recalculado" (o mesmo título já usado no protótipo) + `context.pop()`.

**Enviar sugestão** (D9 = a; se for b, trocar o HTTP pelo exemplo e anotar)
- [x] ~~ **Testes do repositório primeiro** (`http_feedback_repository_test.dart`, com o `fake_api.dart`):~~ — não se aplica (D9 = b, sem backend de sugestão)
  - `send(message)` faz `POST /feedback` com `{ "message": ... }` e o Bearer, e devolve `Feedback`;
  - 422 → `ValidationFailure`; 401 → `UnauthorizedFailure` e a sessão expira;
  - `SampleFeedbackRepository.send` devolve um `Feedback` com id e data e guarda em memória (para os testes e o modo `sample`).
- [x] **Testes do `SuggestionController` primeiro:**
  - `canSend` exige texto não vazio depois de aparar;
  - `send()` chama o repositório com o texto aparado e devolve `true`; com erro, mostra a mensagem e devolve `false`;
  - não envia duas vezes enquanto `busy`.
- [x] Implementar `feedback_repository.dart`, `http_feedback_repository.dart`, `sample_feedback_repository.dart` e `suggestion_controller.dart` → verde.
- [x] **Widget tests primeiro:**
  - "Enviar sugestão" e o subtítulo; "O que podemos melhorar?" com o placeholder "Ex.: queria poder mudar a cor dos objetivos";
  - "Anexar print (opcional)" visível e **desabilitado** (D9 = a);
  - "Enviar" desabilitado sem texto;
  - "Prefere e-mail? Escreve pra gente:" e "contato@bora.app".
- [x] Implementar `suggestion_screen.dart` e a `SuggestionPage`: sucesso → toast "Sugestão enviada" / "Valeu! A gente lê tudo." (do protótipo) + `pop`.
- [x] Verde; `flutter analyze`; `flutter test`.

### S5. Mobile Jardim, só visual (`feat/mob-r-jardim`)

**Pastas permitidas:** `apps/mobile/lib/features/gamification/**` (exceto `home_top_bar.dart`, que é do orquestrador), `apps/mobile/lib/core/sample/bora_sample_data.dart` (só acrescentar dados do Jardim) e `apps/mobile/test/features/gamification/**`.
**Ler antes:** o template `<!-- JARDIM -->` e a lógica `tiles`, `badges`, `xpFalta`, `guardaTxt` e `comprar` (procurar `const tiles`); `screens/04` e `39`; o `bora-data.js`; a P18.

- [x] **Testes primeiro** (`sample_gamification_repository_test.dart`, ampliado, e `garden_controller_test.dart`):
  - `getGarden()` devolve, com os valores fixos do protótipo:
    - Broto "Estágio Broto · Nível 7", com a barra de XP e "70 min de foco até o Nível 8";
    - "Dias regados": 7 dias (Sex, Sáb com guarda-chuva, Dom, Seg, Ter, Qua regados; Hoje vazio, tracejado) e "6 seguidos";
    - "Conquistas": 5, três conquistadas (Primeiro passo; Rampa completa, "Rara · 8% dos usuários"; Voltou da pausa) e duas bloqueadas (7 dias regados "6 de 7"; Entregue com folga "Entregar antes do prazo"), com "3 de 5";
    - guarda-chuva: "Protege 1 dia da sequência · você tem 1";
    - gotas 340.
  - `GardenController.load()` preenche o estado; `loading` é verdadeiro e depois falso;
  - `buyUmbrella()` com 50 gotas ou mais: −50 gotas, +1 guarda-chuva, avisa os ouvintes e devolve `true` (D13 = a);
  - `canBuy` é falso com menos de 50 gotas, e então `buyUmbrella()` devolve `false` sem mudar nada;
  - a barra do topo do Jardim reflete as gotas depois da troca.
- [x] Vermelho → implementar `domain/garden.dart`, `getGarden()` na interface e no exemplo, os dados no `BoraSample` e `presentation/garden_controller.dart` → verde.
- [x] **Widget tests primeiro** (`garden_screen_test.dart`):
  - o `HomeTopBar` (Broto, barra e "A");
  - o título "Jardim";
  - o card do Broto (nome, estágio, barra, texto do XP);
  - "Dias regados" com 7 quadrados e o rótulo de cada dia;
  - "Conquistas" com os 5 itens e o estado (conquistada ou bloqueada);
  - o card do guarda-chuva; "Trocar por 50" chama `onBuy`.
- [x] Implementar `garden_screen.dart` (fiel ao `.dc.html` + `screens/04`, só tokens) e `garden_pages.dart`:
  - `GardenPage` com `ControllerHost<GardenController>`;
  - topo: `onProfile` → `push(profile)`; o Broto no próprio Jardim não faz nada (como no protótipo);
  - troca → toast "−50 gotas" / "Guarda-chuva guardado · você tem N".
- [x] Apagar o `garden_screen.dart` placeholder antigo, ou reescrevê-lo, e ajustar o teste antigo que procurava o placeholder.
- [x] Verde; `flutter analyze`; `flutter test`.

### S6. Mobile Tema escuro (`feat/mob-r-tema-escuro`) (se D7 = a)

**Pastas permitidas:** `apps/mobile/lib/core/theme/**` (exceto `theme_controller.dart`), `apps/mobile/lib/core/widgets/broto.dart` (só se o Broto tiver cor diferente no escuro) e `apps/mobile/test/core/theme/**`.
**Ler antes:** `[data-bora][data-theme="dark"]` no `Bora App.dc.html` (linha ~20); `screens/30-hoje-tema-escuro.png`; `design/tokens.md`.

- [x] **Testes primeiro** (`test/core/theme/bora_colors_dark_test.dart`):
  - `BoraColors.dark` tem **exatamente** os hex do design: bg `#0B1512`, surface `#12201C`, s2 `#1A2C27`, border `#24413A`, tx `#E6F2EE`, tx2 `#9FB8B0`, pri `#34D399`, priTx `#052E22`, lip `#0F8A63`, fill `#34D399`, priSoft `#123A2E`, blue `#38BDF8`, blueFill `#38BDF8`, blueSoft `#0E2A3A`, streak `#FBBF24`, streakInk `#FBBF24`, streakSoft `#3A2E10`, danger `#F87171`, obj1–4 `#34D399`/`#38BDF8`/`#2DD4BF`/`#10B981`, toastIcon `#0369A1`, focusBg `#12201C`, ringTrack `#1A2C27`, shadow transparente, sheetShadow `rgba(0,0,0,.35)`, knob `#FFFFFF`;
  - `bgSoft` e `scrim` no escuro: o design não define. Usar bg e scrim com o tx escuro e anotar como diferença;
  - `AppTheme.dark()` tem `brightness: dark`, `scaffoldBackgroundColor` = `BoraColors.dark.bg` e a extensão `BoraColors.dark`;
  - `lerp`/`copyWith` funcionam para o escuro.
- [x] Vermelho → implementar → verde.
- [x] Widget test: o `TodayScreen` com `AppTheme.dark()` usa o fundo `#0B1512` e o texto `#E6F2EE`.
- [x] Varredura: `grep -rnE "Color\(0x|Colors\.(white|black)" lib/features lib/core/widgets` não pode achar cor fixa em widget. Se achar, **não corrigir fora das pastas permitidas**: reportar a lista ao orquestrador.
- [x] Verde; `flutter analyze`; `flutter test`.

---

## Fase 2: integração (orquestrador)

- [x] Esperar o relatório de todos os subagentes. Conferir em cada um: a prova vermelho→verde, os comandos com saída e as pendências. Qualquer problema reportado vira item no `afazeres.md`.
- [x] Fazer merge das branches na `feat/mobile-acesso-perfil-jardim`, nesta ordem: S6 → S5 → S2 → S3 → S4 → S1. Depois de cada merge: `flutter analyze` + `flutter test` (e `npm run test --workspaces --if-present` depois do S1). **Conflito: não resolver por conta própria.** Parar, reportar o conflito e as opções.
- [x] Trocar os placeholders das rotas do passo 0.6 pelas *Pages* reais, se algum subagente não pôde fazer isso. Rodar os testes de rota do passo 0.6.
- [x] Se S6 achou cor fixa fora das pastas dele: corrigir aqui (arquivos do orquestrador) ou devolver ao subagente dono da pasta.

**Feedback no backend (se D9 = a)**
- [x] ~~ Skill `backend-prisma-sync-module` (`feedback`): `apps/backend/prisma/models/feedback.model.prisma`, a migration `feedback` e a aplicação dela. `npm --workspace apps/backend run prisma:generate`.~~ — não se aplica (D9 = b, sem backend de sugestão)
- [x] ~~ Commit; rebase da `feat/mob-r-backend`. **S1 continua** (mesma conversa, via SendMessage):~~ — não se aplica (D9 = b, sem backend de sugestão)
  - [x] ~~ testes e2e primeiro em `apps/backend/test/feedback.e2e-spec.ts`: 201 com `{ feedback{ id, message, createdAt } }` gravado com o `userId` do token; 401 sem token; 400 com campo a mais (`userId` no corpo) ou `message` que não é texto; 422 com mensagem vazia ou com 2001 caracteres. Rodar e guardar o **vermelho**;~~ — não se aplica (D9 = b, sem backend de sugestão)
  - [x] ~~ skills `backend-prisma-repository` (`FeedbackRepository` → `feedback.prisma.ts`), `backend-provider-implementation` (se o agregado declarar provider) e `backend-nest-controller` (`POST /feedback` com `JwtAuthGuard`, `@CurrentUser('id')`, DTO `SendFeedbackBody` com `@IsString()` e Swagger, e `feedback.integration.http`);~~ — não se aplica (D9 = b, sem backend de sugestão)
  - [x] ~~ e2e verde; `npm --workspace apps/backend run test:e2e` inteiro verde; lint do backend verde.~~ — não se aplica (D9 = b, sem backend de sugestão)
- [x] ~~ Merge da `feat/mob-r-backend` na branch de integração.~~ — feito sem a parte do feedback: merge `9b1365a`
- [x] ~~ `npm --workspace apps/backend run openapi:export` → commit do `packages/contracts/openapi.json`.~~ — não se aplica (D9 = b, sem backend de sugestão)
- [x] ~~ Teste do `HttpFeedbackRepository` (S4) conferido contra o contrato exportado: mesmos campos e status.~~ — não se aplica (D9 = b, sem backend de sugestão)

---

## Fase 3: ponta a ponta e visual (orquestrador, só no simulador iOS)

- [x] Backend local no ar, banco limpo do demo: `npm --workspace apps/backend run db:reset-demo`. Seguir o `docs/mobile/COMO-TESTAR.md`.
- [x] `integration_test/fluxo_principal_test.dart` e `novo_objetivo_ia_test.dart` continuam passando sem mudança (o demo foi mantido, D5 = a). Se D5 ≠ a, ajustar a entrada e anotar.
- [x] **Teste novo primeiro:** `integration_test/acesso_perfil_test.dart`:
  > Escrito depois das telas (o e2e depende delas); passou na 1ª execução depois de corrigir a leitura da resposta `{ availability }`. 28 s.
  - [x] cadastro real: e-mail único (`e2e.<timestamp>@teste.local`), nome "Arthur" (D2) e senha válida pela D1 → cai no **onboarding** com o toast;
  - [x] completar o onboarding → Hoje → tocar "Perfil" (a inicial) → o Perfil mostra o nome e o e-mail digitados e "Máximo por dia" com o limite escolhido;
  - [x] "Redefinir minha rotina" → pintar células → limite 3h → "Salvar e recalcular plano" → voltar ao Perfil com "Máximo por dia 3h", e o `GET /scheduling/availability` (com o token do teste) confere as janelas;
  - [x] "Enviar sugestão" → texto → Enviar → toast, e a sugestão consta no banco (consulta via Prisma no teste do backend ou endpoint; se não houver como ler, anotar que a conferência foi pelo e2e do backend); — **D9 = b:** confere o `SampleFeedbackRepository` em memória, não o banco.
  - [x] "Modo escuro" liga → o fundo muda para o escuro → desliga;
  - [x] Broto do topo → Jardim → "Trocar por 50" → toast;
  - [x] login real: reiniciar o app (sessão em memória), entrar com o e-mail e a senha criados → Hoje (já tem disponibilidade, P12); senha errada → "E-mail ou senha inválidos".
- [x] Rodar o novo teste e os antigos: `flutter test integration_test -d <simulador iOS> --dart-define-from-file=env/local-simulator.json`. Todos verdes.
  > Os 3 verdes contra o backend novo na porta 4100 (a 4000 tinha um backend antigo que eu não tinha permissão de encerrar): `acesso_perfil` 28 s, `fluxo_principal` 47 s, `novo_objetivo_ia` 30 s (este com `AI_PROVIDER=rules`, na porta 4101, como o teste exige).
- [x] **Comparação visual** com o design (simulador 390×844), em `docs/mobile/comparacoes/`, em JPEG, só a rodada atual (prática do [DECIDIR] das comparações): `m33-login-r1.jpg`, `m34-cadastro-r1.jpg`, `m35-cadastro-preenchido-r1.jpg`, `m26-perfil-r1.jpg`, `m28-idioma-r1.jpg`, `m27-rotina-r1.jpg`, `m29-sugestao-r1.jpg`, `m04-jardim-r1.jpg`, `m30-hoje-escuro-r1.jpg` e `m26-perfil-escuro-r1.jpg`. Apagar o `jardim-placeholder.jpg` antigo.
  > Salvas: m33, m34, m01-hoje-topo, m26, m28, m27, m29, m26-escuro, m30-hoje-escuro, m39-jardim-escuro, m04, m04-rolado. **Faltou a m35** (digitar pelo simulador falhou; afazeres).
- [x] Listar no relatório cada diferença visual em relação ao design (as intencionais das decisões D3, D4, D5, D9 e D10, e as não intencionais). Não intencional = corrigir, com volta ao subagente dono, antes da Fase 4.

---

## Fase 4: verificação completa + revisor

- [x] Trazer a `developer` mais recente: `git fetch origin && git merge origin/developer` na branch de integração. Conflito: parar e reportar.
  > A `developer` remota não tinha commits novos.
- [x] Verificação completa (regra, seção 4). Colar a saída resumida de cada uma:
  - [x] `npm run build`
  - [x] `npx turbo run lint`
  - [x] `npm run test --workspaces --if-present` (100% de cobertura em `shared`, `auth` e `feedback`, e nenhum módulo abaixo de 100%)
  - [x] `npm --workspace apps/backend run test:e2e` (Postgres no ar)
  > 139/139 em 71 s na execução final. Antes, 4 execuções falharam por estouro de tempo de 5 s com a máquina carregada/saindo do repouso (afazeres, [INVESTIGAR]).
  - [x] `cd apps/mobile && flutter analyze` (zero problemas)
  - [x] `cd apps/mobile && flutter test` (todos verdes; anotar o número de testes antes e depois da rodada)
  - [x] `flutter test integration_test` no simulador iOS (Fase 3)
  - [x] `grep -rnE "@nestjs|@prisma/client|from ['\"]express|bcrypt|jsonwebtoken" modules/*/src packages/shared/src` (só o falso positivo conhecido `BcryptHashRule`)
- [x] Subagente **REVISOR** (não escreveu código; só aponta). Recebe o diff `developer...feat/mobile-acesso-perfil-jardim` e confere:
  > 1ª tentativa caiu por falta de internet; a 2ª concluiu: 1 bloqueante (rotina salvava sem ter carregado) e 7 não bloqueantes.
  - as regras de `.agents/rules/*`: as 4 regras do mobile (tela sem HTTP, `data/`, um `ChangeNotifier` por tela, go_router), só tokens, domínio sem framework, `userId` só do token;
  - escopo: nada além deste plano e das decisões do Portão 0;
  - todos os testes listados aqui existem, e nenhum foi escrito depois do código (pela ordem dos commits e pela prova vermelho→verde);
  - o contrato (`docs/4-contrato-api.md`, `openapi.json`) bate com o código;
  - a cobertura;
  - a fidelidade ao design (as comparações da Fase 3);
  - textos iguais ao design, exceto os das decisões.
- [x] Cada apontamento do revisor: corrigido pelo subagente original (SendMessage) ou, se for discordância, levado ao usuário. Repetir a verificação completa depois das correções.
  > Bloqueante corrigido pelo S4 (`3c05b33`, merge `a622f91`); item 6 (Broto sem ação anunciado como botão) corrigido pelo orquestrador (`3627792`); os demais no `afazeres.md`; item 8 (barra de status no escuro) verificado no simulador e fechado.

---

## Fase 5: integrar na `developer` (só com a Fase 4 inteira verde)

- [ ] Conferir: verificação completa verde, revisor ok e nenhuma pendência bloqueante.
- [ ] `git checkout developer && git pull --ff-only origin developer && git merge --no-ff feat/mobile-acesso-perfil-jardim`.
- [ ] Na `developer`, rodar de novo o mínimo: `npm run build`, `npm run test --workspaces --if-present`, `flutter analyze` e `flutter test`. Tudo verde.
- [ ] `git push origin developer`.
- [ ] Confirmar que a `main` não mudou (mesmo hash do passo 0.2).
- [ ] **Se qualquer passo da Fase 4 ou 5 falhar: NÃO fazer merge nem push.** Deixar a branch como está, anotar o erro exato aqui e reportar ao usuário.

---

## Fase 6: fechamento (orquestrador)

- [ ] `docs/mobile/COMO-TESTAR.md`: como testar login real, cadastro, Perfil (tema, rotina, sugestão) e Jardim no simulador.
- [ ] `docs/6-diario-execucao.md`: o resumo da rodada (o que foi feito, as decisões, os problemas e como ficaram).
- [ ] `afazeres.md`: fechar com `[x]` + commit o que esta rodada resolveu (por exemplo, a parte "login e cadastro sem sessão" do item da P27) e conferir que todos os itens novos da 0.5 e da Fase 1 estão lá.
- [ ] Atualizar o `CLAUDE.md` só se a estrutura mudou (o módulo `feedback` entra na tabela "Mapa", se D9 = a).
- [ ] Marcar `[x]` neste plano em tudo o que foi feito e anotar o hash do merge na `developer`.
- [ ] Relatório ao usuário no formato da seção 9 da regra de processo:
  - (a) o que foi entregue, por subagente e por branch;
  - (b) a saída da verificação;
  - (c) a prova do TDD;
  - (d) o revisor;
  - (e) as diferenças em relação ao design;
  - (f) as pendências;
  - (g) o estado da `developer` e da `main`;
  - (h) a próxima etapa sugerida: Compromissos e Tarefas únicas, que já têm design novo.
