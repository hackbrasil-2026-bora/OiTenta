# Afazeres

Lista única de erros, problemas, perguntas e pendências do projeto. Regras completas em `.agents/rules/processo-desenvolvimento.md` (seção 10).

- Formato: `- [ ] [TAG] Título curto — (origem: arquivo/tarefa/data)`. Concluído vira `- [x]`, com o commit ou a decisão que fechou o item. Itens concluídos não são apagados.
- Tags:
  - **[INVESTIGAR]**: algo deu errado e a causa ainda não é conhecida (sintoma, como reproduzir, erro exato, onde já se olhou).
  - **[DECIDIR]**: o problema é conhecido e há mais de um jeito de resolver; espera decisão do usuário (contexto, problema, alternativas numeradas, recomendação).
  - **[EXECUTAR]**: a decisão já está tomada; falta implementar (o que fazer e critério de pronto).
- Quando um [DECIDIR] for decidido, ele vira [EXECUTAR] com a decisão escrita no item, e a decisão vai também para `docs/2-decisoes-mvp.md`.
- Item que envolve mais de um projeto fica no projeto onde a correção acontece, com referência cruzada nos outros.
- Só o orquestrador edita este arquivo; os subagentes reportam os itens para ele.

Siglas: W = tela do protótipo web (`design/web/SCREENS.md`); M = tela do mobile (`design/mobile/app/SCREENS.md`); P = decisão da Etapa A (`docs/2-decisoes-mvp.md`); "diário" = `docs/6-diario-execucao.md`; "pergunta N" e "problema N" = numeração do diário em 10/11/2026.

---

## Frontend (web)

- [x] [DECIDIR] Trilha da submissão do Hack Brasil — (origem: `docs/9-pitch-e-descricao.md`, 28/11/2026) — vale para o projeto inteiro
  - **Decidido em 28/11/2026: Saúde & bem-estar** (alternativa 2, contra a recomendação). README, prompt do pitch e descrição ajustados ao ângulo de bem-estar; registrado em `docs/2-decisoes-mvp.md` (AT10).
  - **Contexto:** cada projeto concorre em uma trilha só, e o problema e o público precisam estar dentro dela; o júri pode realocar o projeto ou deixá-lo inelegível (regulamento, itens 5.3–5.5). Submissão até 30/11/2026, 23h59.
  - **Alternativas:** (1) **Acesso à educação**: público é o estudante que concilia aula, estágio e entregas; todos os exemplos do app já são acadêmicos. (2) **Saúde & bem-estar**: história sobre sobrecarga, ansiedade e procrastinação; público mais amplo, mas o app não tem nenhuma medida de saúde.
  - **Recomendação:** (1), porque o público e os exemplos já são de estudantes e o impacto é mais fácil de mostrar. O vídeo e a descrição precisam usar a língua da trilha escolhida.
- [ ] [EXECUTAR] Preencher no `README.md` o link do web na Vercel, o link do vídeo e os nomes da equipe — (origem: README reescrito, 28/11/2026). Pronto quando a tabela do topo e a seção "Equipe" não tiverem mais "_a preencher_".

- [ ] [DECIDIR] Modal "7 dias regados" (W40) com valores fixos — (origem: diário, pergunta 8, B4, 10/11/2026)
  - **Contexto:** ao registrar "Não rolou" na rampa do web, o protótipo mostra um modal com confete e "7 dias regados". Gamificação está fora do MVP; pela P18, os elementos de gamificação aparecem com os valores fixos do protótipo.
  - **Problema:** o modal mostra um número que não vem de nenhum dado real. Um usuário pode achar que é a sequência dele.
  - **Alternativas:**
    1. **Manter com valores fixos (como está).** Código: nada. Telas: iguais ao protótipo. Prazo: zero. Vantagem: fidelidade ao design e coerência com a P18. Desvantagem: número falso na tela.
    2. **Remover o modal até a gamificação existir.** Código: tirar o componente e ajustar os testes do fluxo "Não rolou" (cerca de 30 min). Telas: o "Não rolou" vai direto para a mensagem sem culpa. Prazo: curto. Vantagem: nenhum dado falso. Desvantagem: foge do protótipo; o modal volta depois.
  - **Recomendação:** 1. É exatamente o caso que a P18 decidiu, e quando a gamificação entrar só muda a fonte do número.

- [ ] [DECIDIR] Rampa do web sem check-in de energia — (origem: diário, pergunta 9, B4, 10/11/2026)
  - **Contexto:** no web, o check-in de energia (3 níveis) fica no Hoje (W12–W14), não dentro da rampa. Ao abrir a rampa, ela começa no Aquecer.
  - **Problema:** se o usuário não escolheu a energia, a sessão é gravada com `energy: "low"`, um valor que ele não informou. Ligado ao item "energia escolhida se perde" abaixo.
  - **Alternativas:**
    1. **Manter (`low` como padrão).** Código: nada. Telas: iguais. Prazo: zero. Vantagem: simples. Desvantagem: grava dado que o usuário não deu.
    2. **Obrigar o check-in antes de "Vamos começar?"** (botão desabilitado até escolher). Código: estado do Hoje e testes (1–2 h). Telas: um estado novo do botão, que o protótipo não define. Vantagem: dado sempre real. Desvantagem: um passo a mais para quem trava ao começar, contra a proposta do produto; comportamento sem design.
    3. **Usar a energia escolhida quando houver e `low` só quando não houver**, marcando no código que é padrão. Código: passar a energia do Hoje para a rampa (o mesmo trabalho do item "energia se perde"). Telas: iguais. Prazo: 1–2 h junto com aquele item. Vantagem: sem atrito e sem tela nova. Desvantagem: ainda grava `low` quando o usuário pula o check-in.
  - **Recomendação:** 3, resolvido junto com o item "energia escolhida se perde": não cria atrito nem tela sem design.

- [ ] [DECIDIR] Título "Quebrei em etapas pra você" no objetivo manual (W30 vazia) — (origem: diário, pergunta 10, B4, 10/11/2026)
  - **Contexto:** pela P20, o objetivo manual do web usa a tela W30 (etapas sugeridas pela IA) começando vazia. O título da tela é o texto da IA do protótipo.
  - **Problema:** o texto diz que a IA quebrou as etapas, mas no fluxo manual quem monta é o usuário.
  - **Alternativas:**
    1. **Manter o texto do protótipo.** Código: nada. Prazo: zero. Vantagem: fidelidade. Desvantagem: frase falsa no fluxo manual.
    2. **Trocar por "Monte as etapas" no fluxo manual**, mantendo o do protótipo quando a IA preencher a lista. Código: uma condição e um teste (cerca de 30 min). Telas: só o título muda. Vantagem: texto verdadeiro e já preparado para a IA. Desvantagem: texto que não está no design.
  - **Recomendação:** 2. É uma mudança mínima e evita uma frase falsa.

- [ ] [DECIDIR] A energia escolhida no Hoje se perde ao abrir a rampa pela trilha ou pelo calendário — (origem: diário, problema 11, E-web, 10/11/2026)
  - **Contexto:** o check-in de energia do web fica no Hoje. A rampa também abre pela trilha ("Começar próxima etapa") e pelo detalhe do bloco no calendário.
  - **Problema:** nessas entradas, a energia escolhida no Hoje não chega à rampa, que começa no Aquecer como se fosse energia baixa.
  - **Alternativas:**
    1. **Guardar a energia do dia num estado compartilhado do web** (contexto React ou `sessionStorage`) e passá-la à rampa em qualquer entrada. Código: um provedor de estado e testes (1–2 h). Telas: iguais. Vantagem: a escolha vale para o dia todo. Desvantagem: mais um estado global para manter.
    2. **A rampa aberta fora do Hoje pergunta a energia antes.** Código: um passo novo no modal. Telas: um check-in dentro da rampa, que o protótipo web não tem. Vantagem: dado sempre atual. Desvantagem: tela sem design.
    3. **Manter.** Vantagem: zero trabalho. Desvantagem: a rampa ignora o que o usuário disse.
  - **Recomendação:** 1. Usa só o que existe e resolve também a pergunta 9 (item "Rampa do web sem check-in").

- [ ] [DECIDIR] "Vamos começar?" não faz nada quando não há bloco no dia — (origem: diário, problema 10, E-web/E-mobile, 10/11/2026) — também afeta o Mobile (ver o item "Entrada para a rampa pela trilha")
  - **Contexto:** o botão "Vamos começar?" do Hoje abre a rampa do próximo bloco do dia. Sem bloco no dia, aparece "Nada agendado".
  - **Problema:** sem bloco, o botão não faz nada (web e mobile). No web dá para começar pela trilha; no mobile não há outra entrada.
  - **Alternativas:**
    1. **Esconder ou desabilitar o botão quando não há bloco.** Código: uma condição por app e testes (cerca de 1 h nos dois). Telas: estado novo, sem design. Vantagem: não promete o que não faz. Desvantagem: o usuário que quer adiantar trabalho fica sem caminho no mobile.
    2. **Sem bloco no dia, o botão abre a rampa da próxima etapa pendente** (a do `nextBlock` mais próximo, que o `GET /goals/:goalId` já devolve). Código: escolher a etapa no controlador do Hoje de cada app e testes (2–3 h nos dois). Telas: iguais. Vantagem: sempre há como começar, usando só o contrato atual; o ponta a ponta do mobile deixa de depender do relógio. Desvantagem: a tela precisa buscar os objetivos para achar a etapa.
    3. **Manter.** Desvantagem: botão morto.
  - **Recomendação:** 2. Mantém a proposta do produto (sempre dá para começar), sem tela nova e sem endpoint novo.

- [ ] [DECIDIR] Valor padrão do `NEXT_PUBLIC_DATA_SOURCE` no desenvolvimento — (origem: diário, pergunta 16, D1, 10/11/2026)
  - **Contexto:** o web escolhe a fonte de dados por variável: `http` (backend real, padrão) ou `example` (dados de exemplo).
  - **Problema:** `npm run dev` sem backend no ar mostra telas vazias e erros.
  - **Alternativas:**
    1. **Manter `http` como padrão.** Código: nada. Vantagem: o desenvolvimento acontece contra o produto real, e erros como os do problema 14 aparecem cedo. Desvantagem: precisa subir o backend para ver qualquer tela.
    2. **`example` como padrão de desenvolvimento**, com `http` explícito no ponta a ponta e na produção. Código: o padrão da variável e o `COMO-TESTAR` (cerca de 30 min). Vantagem: qualquer pessoa vê as telas sem backend. Desvantagem: risco de achar que algo funciona quando só funciona com os dados de exemplo.
  - **Recomendação:** 1. O `COMO-TESTAR` e a skill `teste-manual-local` já sobem o backend, e o `example` continua a uma variável de distância.

- [ ] [DECIDIR] Relógio do web no servidor (`SERVER_NOW`) — (origem: diário, pergunta 17, D1, 10/11/2026)
  - **Contexto:** o Next renderiza as telas no servidor; o relógio do servidor e o do navegador diferem e causavam erro de hidratação. O contorno atual (`SERVER_NOW`) funciona porque as telas não mostram a hora antes de carregar os dados.
  - **Problema:** o contorno é frágil: uma tela nova que mostre a hora antes dos dados volta a quebrar.
  - **Alternativas:**
    1. **Manter o contorno.** Código: nada. Vantagem: zero trabalho agora. Desvantagem: armadilha para quem criar telas novas.
    2. **Ler o relógio dentro de um efeito (`useEffect`) nas telas**, numa tarefa separada. Código: telas que usam o relógio e os testes delas (2–4 h). Telas: iguais. Vantagem: solução definitiva. Desvantagem: mexe em várias telas.
    3. **Desligar a renderização no servidor das telas privadas.** Código: pequeno. Vantagem: rápido. Desvantagem: perde o carregamento inicial no servidor e esconde o problema em vez de resolvê-lo.
  - **Recomendação:** 2, numa tarefa própria depois das telas do mínimo obrigatório.

- [ ] [DECIDIR] Guardar só a última rodada das comparações de tela, em JPEG — (origem: diário, pergunta 14 e "decisões que tomei sem você", B4/B5, 10/11/2026) — vale também para o Mobile
  - **Contexto:** cada tela foi comparada com o screenshot do design em até 3 rodadas. As comparações estão em `docs/frontend/comparacoes/` e `docs/mobile/comparacoes/`.
  - **Problema:** validar a decisão já implementada: só a última rodada foi guardada, em JPEG reduzido (cerca de 6 MB no total; os PNGs originais passavam de 40 MB).
  - **Alternativas:**
    1. **Manter (última rodada, JPEG).** Vantagem: repositório leve e o estado final documentado. Desvantagem: não dá para ver a evolução entre as rodadas.
    2. **Guardar todas as rodadas em PNG no git.** Vantagem: histórico completo. Desvantagem: repositório 40 MB maior, e cresce a cada rodada.
    3. **Guardar as rodadas intermediárias fora do git** (pasta compartilhada do time). Vantagem: histórico sem pesar o repositório. Desvantagem: mais um lugar para manter.
  - **Recomendação:** 1. O que importa para avaliar é o estado final e as diferenças justificadas no README de cada pasta.

- [x] [INVESTIGAR] Erro de hidratação no Hoje do web (`Hydration failed`) — (origem: diário, E-web, 10/11/2026) — corrigido na E-web (`131b401`); o Hoje não mostra a data antes de carregar os dados. Solução definitiva no item "Relógio do web no servidor".

- Ver também no Backend: "Textos da rampa vindos do catálogo do domínio" (pergunta 11), "Nome do usuário demo" (pergunta 20), "Script `db:reset-demo`" (pergunta 21).
- Ver também no Mobile: "Dados de exemplo diferentes do backend real" (problema 14).


### Rodada de ajustes visuais (11/11/2026)

- [x] [EXECUTAR] Menu lateral: Objetivos, Jardim e Configurações navegam para W21, W25 e W26 — (origem: pedido do usuário, tarefa W1, 11/11/2026) — fechado em `4f20b04` (branch `feat/web-navegacao-objetivos`).
- [x] [INVESTIGAR] Depois de cadastrar um objetivo, o botão "Novo objetivo" não abria o modal de novo — (origem: pedido do usuário, tarefa W1, 11/11/2026) — causa no web: o Hoje guardava a URL do modal fechado (`closedUrl = "novo=1"`) e nunca a esquecia; com o `cacheComponents` do Next, o Hoje fica montado entre navegações e `/hoje?novo=1` não reabria. O backend respondeu 201 em todos os `POST /goals`. Corrigido com teste de regressão em `c112d9f` (integrado em `4f20b04`).
- [x] [EXECUTAR] Calendário web: troca Dia/Semana/Mês e Execução/Prazos nas três visualizações — (origem: pedido do usuário, tarefa W2, 11/11/2026) — fechado em `d6024ea` (branch `feat/web-calendario`).
- [x] [INVESTIGAR] Ponta a ponta do web falhava de manhã: "strict mode violation" na trilha — (origem: verificação da Tarefa 0, 11/11/2026) — causa: logo depois da navegação Hoje → trilha, o card do Hoje (um `button` com o título da etapa 2, que cai hoje de manhã) ainda está no DOM, e o seletor `getByText(etapa2).locator("..")` achava 2 elementos. Falhou 2× seguidas às ~10h na developer (`157a920`), sem relação com a rodada. Corrigido em `62d7555`; ver o [DECIDIR] abaixo, porque mexeu num teste existente.

- [ ] [DECIDIR] Validar decisão já implementada: correção do seletor no ponta a ponta do web — (origem: verificação da Tarefa 0, `apps/frontend/e2e/fluxo-principal.spec.ts`, 11/11/2026)
  - **Contexto:** a regra da rodada diz "não altere teste para passar". O ponta a ponta do web estava vermelho na própria developer, por um defeito do teste (seletor ambíguo de manhã), e a regra do processo proíbe merge sem a verificação verde: nenhuma tarefa da rodada poderia ser integrada.
  - **Problema:** o orquestrador alterou um teste existente sem a sua autorização. A asserção é a mesma (a etapa 2 tem horário "hh:mm · 30 min" e não "Ainda sem horário"); só o seletor passou a mirar a linha da trilha (`xpath=parent::div`) em vez de qualquer pai do texto.
  - **Alternativas:**
    1. **Validar.** Código: nada. Vantagem: a verificação volta a ser confiável em qualquer horário. Desvantagem: nenhuma.
    2. **Reverter e corrigir de outro jeito** (ex.: esperar o Hoje sair do DOM antes de procurar a etapa). Código: o teste (30 min). Vantagem: nenhuma real; a asserção seria a mesma.
  - **Recomendação:** 1.

- [ ] [DECIDIR] Saudação fixa "Boa noite" no Hoje — (origem: `apps/frontend/src/modules/today/logic/today.logic.ts`, observado no ponta a ponta às 10h, 11/11/2026) — vale também para o Mobile ("Bom dia" fixo)
  - **Contexto:** o protótipo web traz "Boa noite, Arthur" (`AppHoje.dc.html`) e o mobile "Bom dia, Arthur"; as telas copiaram o texto fixo.
  - **Problema:** às 10h o web diz "Boa noite"; à noite o mobile diz "Bom dia".
  - **Alternativas:**
    1. **Manter o texto do protótipo.** Vantagem: fidelidade. Desvantagem: parece erro para o usuário.
    2. **Saudação pela hora local** (Bom dia até 12h, Boa tarde até 18h, Boa noite depois). Código: uma função pura e testes em cada app (1 h no total). Vantagem: correto. Desvantagem: texto variável que o design não mostra (só mostra um dos três).
  - **Recomendação:** 2.

- [ ] [DECIDIR] Tema escuro do web app não é aplicado — (origem: W1, `settings.page.tsx`, 11/11/2026)
  - **Contexto:** a W26 mostra Claro/Escuro. A escolha fica guardada (repositório de exemplo), mas o app não muda de cor: o `globals.css` só tem um `.theme-dark` parcial, usado na landing.
  - **Problema:** o botão "Escuro" não tem efeito visível.
  - **Alternativas:**
    1. **Implementar `[data-theme="dark"]`** com os tokens do `design/tokens.md`, aplicado no `<html>` pelo shell. Código: CSS e um efeito no shell (cerca de 2 h). Telas: todas, com risco de aparecerem cores fixas. Vantagem: fiel ao protótipo. Desvantagem: revisar todas as telas no escuro.
    2. **Manter até depois do MVP.** Vantagem: zero risco. Desvantagem: botão parece quebrado.
    3. **Esconder a seção Tema.** Código: 10 min. Desvantagem: foge do protótipo.
  - **Recomendação:** 2 agora, 1 depois do MVP (a fatia não depende de tema).

- [ ] [DECIDIR] Configurações: gravação da disponibilidade falha em silêncio — (origem: W1 e revisor, `settings.page.tsx`, 11/11/2026)
  - **Contexto:** a W26 grava a grade e o limite sozinha, 400 ms depois da última mudança, e diz "O plano se reorganiza na hora".
  - **Problema:** com a grade vazia ("Limpar") nada é gravado (o contrato dá 422 sem janela), e um erro do `PUT` é ignorado. Nos dois casos o usuário não é avisado e, ao voltar, vê a grade antiga. O design não define esses estados.
  - **Alternativas:**
    1. **Manter.** Vantagem: simples. Desvantagem: o usuário acha que salvou.
    2. **Aviso com o toast que já existe** no erro e na grade vazia. Código: 30 min com testes. Desvantagem: texto e visual sem design (precisa do seu texto).
  - **Recomendação:** 2, com o texto aprovado por você.

- [ ] [DECIDIR] "Tarefas leves" no menu e "Comprar" guarda-chuva no Jardim sem ação — (origem: W1, 11/11/2026)
  - **Contexto:** "Tarefas leves" (W24) não estava no pedido da rodada; o "50 · Comprar" do Jardim é gamificação (fora do MVP).
  - **Alternativas:**
    1. **Manter sem ação.** Vantagem: zero custo. Desvantagem: parecem botões quebrados.
    2. **Tela W24 com dados de exemplo e compra só visual.** Prazo: cerca de 2 h. Desvantagem: mais dado falso.
  - **Recomendação:** 1 no MVP.

- [ ] [EXECUTAR] "Ver jardim" no Hoje navegar para `/jardim` — (origem: W1, `today.page.tsx`, 11/11/2026)
  - **O que fazer:** o botão de "Conquistas recentes" no Hoje não tem ação; ligar com `router.push("/jardim")`, como no protótipo.
  - **Critério de pronto:** teste que clica e confere a navegação; verificação completa verde.

- [ ] [DECIDIR] "Voltar" do navegador depois de encaixar um objetivo reabre o modal Novo objetivo vazio — (origem: revisor da W1, `today.page.tsx` `onCreated`, 11/11/2026)
  - **Contexto:** ao encaixar, o web vai para `/calendario` com `router.push`, e `/hoje?novo=1` fica no histórico. Já era assim antes da rodada.
  - **Alternativas:**
    1. **Manter.** Desvantagem: o modal reabre vazio ao voltar.
    2. **Trocar a URL por `/hoje` (`router.replace`) antes de ir ao calendário.** Código: 1 linha e um teste (30 min). Vantagem: "Voltar" leva ao Hoje sem modal.
  - **Recomendação:** 2.

- [ ] [DECIDIR] "Sair" mantém telas em memória — (origem: revisor da W1, `settings.page.tsx` logout, 11/11/2026)
  - **Contexto:** o "Sair" descarta o token e faz `router.replace("/entrar")`; com o `cacheComponents`, telas como o Hoje e a sidebar (com o nome do usuário) continuam em memória.
  - **Problema:** se outra conta entrar em seguida, dados da anterior podem aparecer por um instante. Hoje só há o demo.
  - **Alternativas:** 1. **manter** (impacto baixo no MVP); 2. **recarregar a página no logout** (`window.location.assign("/entrar")`, 1 linha e teste, 15 min).
  - **Recomendação:** 2, pela segurança com custo mínimo.

- [ ] [DECIDIR] Cor fixa da sombra do interruptor do e-mail diário (W26) — (origem: W1, `settings.page.tsx:190`, 11/11/2026)
  - **Contexto:** o interruptor usa `0 1px 2px rgba(14,31,26,.2)`, do protótipo; não há token de sombra equivalente (`--shadow-card` e `--shadow-float` são outras).
  - **Alternativas:** 1. **manter** a cor do protótipo; 2. **criar o token** no `design/tokens.md` e no `globals.css` (15 min).
  - **Recomendação:** 2, para seguir a regra de não usar cor fixa.

- [ ] [DECIDIR] Mostrar objetivo concluído em Prazos — (origem: W2 `calendar.logic.ts` `SHOW_DONE_DEADLINES` e M2 `week_controller.dart` `showDoneGoalsInDeadlines`, 11/11/2026) — vale também para o Mobile
  - **Contexto:** o calendário Prazos mostra a entrega de cada objetivo com prazo, vindo do `GET /goals`, que devolve também os `done`. O protótipo não filtra; o detalhe web diz "Pronto antes do prazo".
  - **Alternativas:**
    1. **Mostrar com "100%/concluído" (como está nos dois apps).** Vantagem: o usuário vê que entregou. Desvantagem: o calendário acumula entregas resolvidas.
    2. **Esconder os concluídos.** Código: uma constante por app e 2–3 testes (15 min). Desvantagem: a entrega some de uma data passada.
  - **Recomendação:** 1.

- [ ] [DECIDIR] Limites de navegação do calendário web — (origem: W2 e revisor, `calendar.logic.ts` `HORIZON_DAYS`/`HORIZON_WEEKS`, 11/11/2026)
  - **Contexto:** seguindo o protótipo, a Semana vai da atual até +3, o Dia de hoje a hoje+27, e o Mês fica fixo no mês atual (setas desligadas), igual ao horizonte de 28 dias do plano.
  - **Problema:** não dá para ver semanas passadas; no Mês, prazos de meses seguintes não aparecem; perto do fim do mês, parte dos 28 dias do plano nunca aparece no Mês.
  - **Alternativas:**
    1. **Manter (fiel ao protótipo).** Desvantagem: prazos distantes ficam invisíveis no Mês.
    2. **Liberar as setas no Mês** (e, se quiser, no passado). Código: lógica e testes (cerca de 1 h; o carregamento por semana já existe). Desvantagem: foge do protótipo.
  - **Recomendação:** 2 só no Mês de Prazos, onde a limitação esconde dado real.

- [ ] [DECIDIR] Texto do detalhe de um prazo já vencido — (origem: W2, `deadline-detail-panel.component.tsx`, 11/11/2026)
  - **Contexto:** o painel "Prazo final" mostra "Entrega · Sexta, 20/11 · em 4 dias". O protótipo não define o prazo passado (mostraria "em -2 dias"); hoje o web mostra só a data.
  - **Alternativas:** 1. **só a data** (atual); 2. **"venceu há N dias"** (10 min com teste).
  - **Recomendação:** 2, mais claro.

- [ ] [DECIDIR] Ações do detalhe do bloco sem efeito (Mover, Marcar parcial, Não vou conseguir) — (origem: W2, `block-detail-panel.component.tsx`, 11/11/2026)
  - **Contexto:** o W16 mostra esses botões; o contrato (§4) deixa essas ações fora do mínimo. Eles continuam visíveis e sem ação, como antes da rodada.
  - **Alternativas:**
    1. **Manter visíveis sem ação.** Vantagem: fidelidade. Desvantagem: botões mortos.
    2. **Esconder até existirem.** Código: 15 min. Desvantagem: foge do design.
    3. **Implementar** (precisa de endpoints novos de bloco: mover, registrar parcial/falta). Prazo: 1–2 dias entre backend e web.
  - **Recomendação:** 1 no MVP; "Marcar parcial" e "Não vou conseguir" já existem como registro de sessão e podem ser ligados depois pelo `POST /activation/sessions`.

- [ ] [DECIDIR] Calendário (web e mobile) não avisa erro de carregamento — (origem: revisores da W2 e do M2, `calendar.page.tsx` e `week_screen.dart`, 11/11/2026) — vale também para o Mobile
  - **Contexto:** se `GET /scheduling/plan/week`, `/plan/day` ou `GET /goals` falharem (ex.: 404 sem disponibilidade), o web deixa a promessa rejeitada sem tratamento e o mobile guarda o erro sem mostrar. O usuário vê uma grade vazia ou "Nenhuma entrega neste dia.", o que engana.
  - **Problema:** o design não tem estado de erro no calendário.
  - **Alternativas:**
    1. **Manter.** Desvantagem: falha silenciosa e enganosa.
    2. **Aviso com o toast que já existe nos dois apps.** Código: 1 h por app com testes. Desvantagem: texto e estado sem design.
  - **Recomendação:** 2, com um texto único aprovado por você para todas as telas.

- Ver também no Backend: "Tipo do prazo e nome curto do objetivo" (calendário e lista de objetivos), "Preferências do usuário", "Endpoint de gamificação", "Próxima etapa no `GET /goals`", "Compromissos fixos no contrato".

### Proposta de IA (11/11/2026)

- [x] [EXECUTAR] Entrada do caminho manual no web quando o Novo objetivo tiver IA — (origem: `docs/7-proposta-ia.md` §d.4, 11/11/2026; decidido em 12/11/2026, IA3, **provisório**)
  - **Decisão (IA3):** alternativa 1 com o texto do mobile: link discreto **"Prefiro preencher à mão"** na W27, abaixo do "Analisar com IA", com a mesma intenção do M16, usando só os tokens existentes. Abre a W30 vazia. Tarefa 8 do `docs/7` §g.
  - **Pronto quando:** o link aparece na W27, abre a W30 vazia, tem teste da lógica do modal e o ponta a ponta do web continua verde.
  - **Fechado** em `7f74653` (tarefa 8, branch `feat/web-ia-novo-objetivo`). Continua **provisório** até o desenho (item abaixo).
  - **Contexto:** hoje o "Novo objetivo" do web abre direto a W30 vazia (objetivo manual com etapas, P20). Com a IA, o modal passa a abrir na W27 (Escrever / Colar link, "Analisar com IA"), como no protótipo. O design web não tem "Preencher à mão" (`design/web/SCREENS.md`, notas); o mobile tem (M16).
  - **Problema:** sem uma entrada, o objetivo manual com etapas (mínimo obrigatório, 4a) só fica acessível quando a IA falha.
  - **Alternativas:**
    1. **Link "Montar sem IA" na W27**, que abre a W30 vazia. Código: 1 h com teste. Telas: um link sem design, no estilo do botão secundário. Vantagem: o caminho manual fica a um clique. Desvantagem: elemento fora do protótipo.
    2. **"Analisar com IA" com o texto vazio abre a W30 vazia.** Código: 30 min. Telas: nenhuma nova. Vantagem: nada fora do design. Desvantagem: comportamento escondido.
    3. **Manter a W30 vazia como entrada e a IA atrás de um botão "Usar IA" na W30.** Código: 2 h. Telas: inverte o protótipo. Vantagem: o manual continua o padrão. Desvantagem: foge do fluxo do design (F §4: o chat com IA é o padrão).
  - **Recomendação:** 1, igual ao "Preencher à mão" do mobile.

- [ ] [EXECUTAR] Desenhar no Claude Design o link "Prefiro preencher à mão" da W27 — (origem: IA3, 12/11/2026)
  - **O que fazer:** desenhar o estado da W27 com o link abaixo do "Analisar com IA" (posição, estilo e texto), para substituir a versão provisória feita só com os tokens existentes.
  - **Pronto quando:** o design estiver em `design/web/` e a tela implementada seguir o desenho.

- [ ] [DECIDIR] Validar decisão já implementada: testes do web adaptados ao modal que abre na W27 — (origem: tarefa 8, `feat/web-ia-novo-objetivo`, 12/11/2026)
  - **Contexto:** com a IA (IA1, IA3), o "Novo objetivo" do web abre na W27, e não mais direto na W30 vazia. Testes que abriam a W30 direto quebrariam.
  - **O que foi feito sem a sua autorização explícita** (a IA4 autorizou só os testes do mobile): o orquestrador autorizou acrescentar **só** o clique em "Prefiro preencher à mão" antes do fluxo manual em `new-goal-modal.component.test.tsx` (4 testes), `today-new-goal.page.test.tsx` (4 pontos) e `e2e/fluxo-principal.spec.ts` (1 linha). O que os testes provam continua igual. O revisor conferiu que a mudança foi só essa. Antes e depois no relatório da rodada.
  - **Alternativas:** 1. **validar** (nada a fazer); 2. **reverter** e decidir outro jeito de abrir o manual (o ponta a ponta volta a quebrar).
  - **Recomendação:** 1.

- [ ] [DECIDIR] "Voltar" da W30: fecha o modal ou volta à W27? — (origem: tarefa 8 e revisor, `new-goal-modal.component.tsx`, 12/11/2026)
  - **Contexto:** no protótipo, o "Voltar" da W30 volta à W27 (com o texto preservado). Antes da IA não havia W27, e o web fazia o "Voltar" fechar o modal. Dois testes (`today-new-goal.page.test.tsx`) usam o "Voltar" para fechar.
  - **Alternativas:**
    1. **Seguir o protótipo:** volta à W27. Código: 30 min; os 2 testes passam a fechar pelo "Fechar" (precisa da sua autorização). Vantagem: fiel ao design; quem quer reescrever o pedido não perde o texto.
    2. **Manter fechando** (atual). Vantagem: nada a fazer. Desvantagem: diverge do protótipo.
  - **Recomendação:** 1.

- [ ] [DECIDIR] "Analisar com IA" desabilitado sem estilo de desabilitado — (origem: tarefa 8 e revisor, 12/11/2026)
  - **Contexto:** o botão fica desabilitado com o texto vazio e na aba "Colar link" (evita o 422), mas o `PRIMARY_BTN` não tem visual de desabilitado: parece ativo e não faz nada. O protótipo nunca desabilita.
  - **Alternativas:** 1. **manter** (atual); 2. **esmaecer com tokens** quando desabilitado (15 min; estado sem design); 3. **mensagem** ao clicar com o texto vazio (30 min; texto sem design).
  - **Recomendação:** 2, junto com o desenho da W27 no Claude Design.

- [ ] [DECIDIR] Texto do link manual: "Prefiro preencher à mão" (web) × "Preencher à mão" (mobile) — (origem: tarefa 8, IA3 × `goal_chat_screen.dart`, 12/11/2026)
  - **Contexto:** a IA3 diz "com o texto do mobile" e cita "Prefiro preencher à mão"; o mobile usa "Preencher à mão". O web ficou com "Prefiro preencher à mão", como escrito na IA3.
  - **Alternativas:** 1. **manter os dois**; 2. **igualar ao mobile** (10 min: string, testes e ponta a ponta); 3. **igualar o mobile ao web**.
  - **Recomendação:** decidir junto com o desenho no Claude Design (item acima).

- Na W30 manual o subtítulo passou a "Novo objetivo · 3 de 3" (passo "result" do protótipo); cruza com o [DECIDIR] "Título 'Quebrei em etapas pra você' no objetivo manual".

- Ver também no Backend: "Aprovar a proposta de IA", "O que fazer quando a IA falha", "Leitura de link e anexo (UC03)" (aba "Colar link" da W28) e "Perguntas de esclarecimento no chat". Ver também no Frontend (acima): "Título 'Quebrei em etapas pra você' no objetivo manual", que fica verdadeiro quando a IA preencher a W30.
- Ver também no Backend, rodada do Ollama local (16/11/2026): "Modelo local do Ollama" (o "IA analisando…" da W29 dura de 6 a 21 s conforme o modelo; o web desiste aos 25 s) e "Prazo relativo errado quando o LLM responde" (o prazo da W30 pode vir errado).

## Mobile

- [ ] [DECIDIR] Para onde ir depois de criar um objetivo ou tarefa — (origem: diário, pergunta 12, B5, 10/11/2026)
  - **Contexto:** no mobile, ao encaixar um objetivo novo (M15) ou salvar uma tarefa (M16), o app volta para a Semana, como no protótipo.
  - **Problema:** o usuário pode querer ver a trilha do que acabou de criar.
  - **Alternativas:**
    1. **Voltar para a Semana (como está e como no protótipo).** Código: nada. Vantagem: fidelidade; mostra onde o objetivo foi encaixado. Desvantagem: a trilha fica a dois toques.
    2. **Abrir a trilha do objetivo criado (M18).** Código: trocar a rota de destino e o teste (cerca de 30 min). Vantagem: mostra as etapas e datas. Desvantagem: foge do protótipo; não vale para a tarefa única.
  - **Recomendação:** 1. É o que o design pede, e a Semana mostra o efeito do encaixe.

- [ ] [DECIDIR] Slider "Máximo de estudo por dia" na M15 — (origem: diário, pergunta 13, B5, 10/11/2026)
  - **Contexto:** a M15 do protótipo (resposta da IA) tem um slider "Máximo de estudo por dia". Na versão manual vazia (P20), ele saiu junto com os elementos da IA.
  - **Problema:** o `POST /goals` não tem campo para esse limite; o limite diário mora na disponibilidade (`PUT /scheduling/availability`).
  - **Alternativas:**
    1. **Manter fora.** Código: nada. Vantagem: a tela só mostra o que o contrato suporta. Desvantagem: diferença em relação ao design.
    2. **Voltar como visual, sem efeito** (dado de exemplo). Código: o widget (cerca de 1 h). Vantagem: fidelidade. Desvantagem: controle que não faz nada.
    3. **Voltar ligado ao limite diário da disponibilidade.** Código: a tela de objetivo passa a chamar também o `PUT /scheduling/availability` (2–3 h). Vantagem: funciona. Desvantagem: mistura duas responsabilidades numa tela, e o limite é do usuário, não do objetivo.
  - **Recomendação:** 1, até o design dizer se o limite é por objetivo (o que exigiria campo novo no backend).

- [ ] [DECIDIR] Token do mobile só em memória (fechar o app desloga) — (origem: diário, pergunta 18, D2, 10/11/2026)
  - **Contexto:** o token JWT do mobile fica só em memória.
  - **Problema:** fechar o app desloga o usuário. Persistir exige um pacote novo, e pacote novo só entra com aprovação.
  - **Alternativas:**
    1. **Aprovar `flutter_secure_storage`** (Keychain no iOS). Código: guardar e ler o token no cliente HTTP e um teste (1–2 h). Vantagem: sessão persistente e segura. Desvantagem: pacote nativo novo (pods).
    2. **Aprovar `shared_preferences`.** Código: igual. Vantagem: pacote simples. Desvantagem: o token fica sem criptografia no aparelho.
    3. **Manter em memória.** Vantagem: nada a fazer. Desvantagem: login a cada abertura (no demo é um toque).
  - **Recomendação:** 1. É o jeito seguro e o custo é pequeno.

- [ ] [DECIDIR] Entrada para a rampa pela trilha no mobile (M18) — (origem: diário, pergunta 19 e problema 10, E-mobile, 10/11/2026)
  - **Contexto:** no web, a trilha tem "Começar próxima etapa". A trilha do mobile (M18) não tem esse botão no design; a rampa só abre pelo "Vamos começar?" do Hoje, que depende de bloco no dia.
  - **Problema:** sem bloco no dia, o usuário do mobile não consegue começar; o ponta a ponta do mobile depende do horário.
  - **Alternativas:**
    1. **Criar "Começar próxima etapa" na trilha do mobile.** Código: botão, rota para a rampa e testes (2 h). Telas: elemento que não está no design. Vantagem: mesma entrada do web. Desvantagem: tela sem design.
    2. **Resolver pelo Hoje** (item do Frontend "'Vamos começar?' não faz nada…", alternativa 2). Código: só no controlador do Hoje. Vantagem: sem tela nova e com a mesma regra nos dois apps. Desvantagem: o usuário não escolhe qual etapa começar.
    3. **Manter.**
  - **Recomendação:** 2, decidida junto com o item do Frontend.

- [ ] [INVESTIGAR] Tempo da rampa inconsistente: "Rampa de 25 min até o foco" no Hoje × "6 min de rampa" na escada — (origem: diário, problema 15, E-mobile, 10/11/2026)
  - **Sintoma:** o card do Hoje diz "Rampa de 25 min até o foco"; a escada (M06) diz "6 min de rampa".
  - **Como reproduzir:** mobile no simulador com `DATA_SOURCE=http`, login demo com plano criado; ver o card do Hoje e tocar em "Vamos começar?" → "Montar minha rampa".
  - **Erro exato:** nenhum erro; os dois números não batem.
  - **Onde já se olhou:** nada; ficou fora do escopo da Etapa E. Suspeita (não confirmada): um dos textos vem fixo do protótipo e o outro é calculado a partir das opções da rampa.

- [ ] [DECIDIR] Ponta a ponta do mobile depende do relógio — (origem: diário, problema 16, E-mobile, 10/11/2026)
  - **Contexto:** o `integration_test` do mobile percorre Hoje → rampa e precisa de um bloco no dia atual.
  - **Problema:** falha depois de cerca de 22h45 e na noite de domingo ("sem bloco hoje"). O do web já tem um caminho alternativo pela trilha.
  - **Alternativas:**
    1. **Manter e rodar no horário certo.** Vantagem: zero trabalho. Desvantagem: verificação noturna falha sem bug.
    2. **Caminho alternativo, como no web**, depois que existir a entrada da rampa sem bloco (item "Entrada para a rampa pela trilha"). Código: o teste (1 h). Vantagem: roda a qualquer hora. Desvantagem: depende daquela decisão.
    3. **Relógio injetável por `--dart-define`** só no teste. Código: `AppConfig` e o relógio do app (2 h). Vantagem: teste determinístico. Desvantagem: configuração de teste dentro do app.
  - **Recomendação:** 2, depois da decisão da entrada da rampa.

- [ ] [DECIDIR] Dados de exemplo diferentes do backend real — (origem: diário, problema 14, E-mobile, 10/11/2026) — vale também para o Frontend
  - **Contexto:** os testes de tela usam os repositórios de exemplo. Dois bugs do mobile (`log` com opção; `progressPct` dentro de `goal`) só apareceram no ponta a ponta, porque os dados de exemplo tinham outro formato.
  - **Problema:** os testes de tela podem passar com um formato que o backend não devolve.
  - **Alternativas:**
    1. **Manter e confiar no ponta a ponta.** Vantagem: nada a fazer. Desvantagem: o erro aparece tarde.
    2. **Respostas reais gravadas** (JSON capturados do backend) usadas pelos testes dos repositórios HTTP e como base dos dados de exemplo. Código: arquivos de fixture e ajuste dos testes (meio dia por app). Vantagem: o formato fica preso ao real. Desvantagem: as fixtures precisam ser regravadas quando o contrato muda.
    3. **Teste que confere os `fromJson`/tipos contra o `openapi.json`.** Vantagem: automático. Desvantagem: mais complexo de montar.
  - **Recomendação:** 2. É simples e pega exatamente o tipo de erro que aconteceu.

- [ ] [DECIDIR] Validar decisão já implementada: tarefas leves vazias no modo real do mobile — (origem: diário, "decisões que tomei sem você", D2, 10/11/2026)
  - **Contexto:** tarefas leves (UC13) não têm endpoint no contrato do MVP. No modo `http`, o repositório devolve a lista vazia; no modo `example`, a lista do protótipo.
  - **Problema:** no app real, a seção de tarefas leves (Hoje e M22) aparece vazia.
  - **Alternativas:**
    1. **Manter vazia.** Vantagem: nenhum dado falso. Desvantagem: a seção parece quebrada.
    2. **Dados de exemplo fixos também no modo `http`**, marcados como "example" no código (como a P18 faz com a gamificação). Código: o repositório (cerca de 30 min). Vantagem: tela fiel ao design. Desvantagem: tarefas que não são do usuário.
    3. **Esconder a seção no modo `http`.** Vantagem: sem dado falso nem seção vazia. Desvantagem: foge do design.
  - **Recomendação:** 2. É a mesma regra usada para dados sem endpoint (P18 e regra 3 da rodada de ajustes visuais de 11/11).

- [ ] [DECIDIR] Validar pendências aceitas da B5 (telas mobile) — (origem: diário, tabela de tarefas, B5, 10/11/2026)
  - **Contexto:** o revisor da B5 aceitou estas adaptações:
    - "cerca de Xh" no onboarding conta 2 h por período (o design diz "10 períodos · cerca de 20h");
    - a resposta do T01 ("O que mais te trava?") fica só no controlador (não há campo no backend);
    - tarefas leves só de exemplo;
    - etapas concluídas aparecem como "Concluída";
    - títulos curtos;
    - plano inviável (M17) fora;
    - login e cadastro sem sessão, exceto o demo (são placeholder pela P27).
  - **Problema:** são escolhas feitas sem você.
  - **Alternativas:**
    1. **Aceitar todas como estão.** Vantagem: nada a fazer. Desvantagem: nenhuma imediata.
    2. **Reabrir as que quiser**, cada uma vira um [EXECUTAR] próprio. Vantagem: controle item a item. Desvantagem: trabalho extra.
  - **Recomendação:** 1, revendo o plano inviável (M17) quando o mínimo obrigatório estiver pronto.

- [ ] [DECIDIR] Validar mudanças fora do escopo aceitas na D2 — (origem: diário, tabela de tarefas, D2, 10/11/2026)
  - **Contexto:** a D2 (mobile ligado ao backend) também mudou: `main.dart` passou a usar `fromConfig()`; criou `env/*.json`; acrescentou `me()` à interface do repositório de auth.
  - **Problema:** escolhas aceitas pelo orquestrador sem você.
  - **Alternativas:** 1. aceitar (são necessárias para a escolha de ambiente da regra do mobile); 2. reverter alguma e refazer de outro jeito.
  - **Recomendação:** 1. São o mínimo para a configuração por ambiente que a regra do mobile exige.

- Ver também no Frontend: "'Vamos começar?' não faz nada quando não há bloco no dia" (problema 10) e "Guardar só a última rodada das comparações" (pergunta 14).
- Ver também no Backend: "Nome do usuário demo" (pergunta 20), "Textos da rampa vindos do catálogo do domínio" (pergunta 11).


### Rodada de ajustes visuais (11/11/2026)

- [x] [EXECUTAR] Calendário do mobile: arrastar o traço expande para o mês e recolhe para a semana; Execução/Prazos na semana e no mês — (origem: pedido do usuário, tarefa M2, 11/11/2026) — fechado em `8090025` (branch `feat/mobile-calendario`).
- [x] [EXECUTAR] Rampa: a tag "Sugerido pra você" ficava coberta pelos degraus — (origem: pedido do usuário, tarefa M1, 11/11/2026) — a tag passou para uma camada acima dos degraus, como o `z-index` do protótipo; fechado em `fe71502` (branch `feat/mobile-chat-objetivo`).
- [x] [EXECUTAR] Chat do novo objetivo (M13–M15) com a "IA" de exemplo — (origem: pedido do usuário, tarefa M1, 11/11/2026) — **parcial**: o chat, o repositório de exemplo (`SampleGoalAssistantRepository`, atrás de `GoalAssistantRepository`) e a M15 preenchida estão integrados em `fe71502`, na rota `/objetivos/chat`, mas o botão "Novo objetivo" ainda abre a M15 direto. Falta o item abaixo. — **Fechado** em `4748903` (tarefa 7: o botão abre o chat e o modo `http` usa o `POST /goals/assistant/draft`).

- [x] [EXECUTAR] Ligar "Novo objetivo" (M02) ao chat: exige alterar 2 testes existentes — (origem: M1 e revisor, 11/11/2026; decidido em 12/11/2026, IA4)
  - **Decisão (IA4):** alternativa 1. O botão "Novo objetivo" abre o chat. Autorizado alterar `test/features/goals/goals_screens_test.dart` e `integration_test/fluxo_principal_test.dart` (tocar em "Preencher à mão" depois de "Novo objetivo"). O relatório mostra o antes e o depois. Feito junto com a tarefa 7 do `docs/7` §g.
  - **Pronto quando:** "Novo objetivo" abre o chat; um teste novo prova isso; os dois testes alterados e o ponta a ponta passam.
  - **Fechado** em `4748903` (branch `feat/mobile-ia-http`), com o `integration_test` verde no simulador.
  - **Contexto:** você pediu que o botão abra o chat antes das etapas. Trocar o destino (1 linha em `goals_pages.dart`) muda o fluxo que dois testes existentes verificam: `test/features/goals/goals_screens_test.dart` ("Novo objetivo (M15 vazia)…") e o ponta a ponta `integration_test/fluxo_principal_test.dart:139-140`, que tocam "Novo objetivo" e esperam a M15 vazia ("0 min no total").
  - **Problema:** a regra da rodada proíbe alterar teste para passar; por isso o subagente parou e a entrada não foi ligada.
  - **Alternativas:**
    1. **Autorizar a mudança dos testes.** Patch pronto e verificado pelo revisor (`flutter test` +189 verde) em `/private/tmp/claude-501/-Users-arthursetragni-Hackaton-OiTenta/38e788da-ae14-494a-b00a-834fc4ccb0f8/scratchpad/m1-tdd/entrada-chat-completo.patch`: `onNew` → chat; o teste antigo ganha o toque em "Preencher à mão" depois de "Novo objetivo"; um teste novo prova que "Novo objetivo" abre o chat. No ponta a ponta, acrescentar `await tapText(tester, 'Preencher à mão');` depois da linha 139. Prazo: minutos mais a verificação completa. Vantagem: entrega o que você pediu. Desvantagem: altera dois testes de fluxo (o que eles provam continua igual: o objetivo manual com etapas).
    2. **Manter a entrada direta.** Vantagem: nada muda. Desvantagem: o chat fica sem entrada para o usuário.
  - **Recomendação:** 1. Os testes mudam porque o fluxo pedido mudou, não para esconder um erro.

- [ ] [DECIDIR] Destino do "Preencher à mão" do chat e caminho para a M15 vazia (P20) — (origem: M1, `goals_pages.dart:74`, 11/11/2026)
  - **Contexto:** no protótipo, o "Preencher à mão" do chat leva à M16 (tarefa única). O objetivo manual com etapas (P20, mínimo obrigatório) usa a M15 vazia, e o design não mostra como chegar a ela pelo chat.
  - **Alternativas:**
    1. **(implementada)** Chat → "Preencher à mão" → M15 vazia → o "Preencher à mão" dela → M16. Código: nada. Vantagem: os dois caminhos manuais continuam acessíveis. Desvantagem: a M16 fica a 2 toques.
    2. **Chat → M16, como no design;** a M15 vazia só abre quando a IA falha. Código: 1 linha. Vantagem: fiel ao design. Desvantagem: some a entrada voluntária do objetivo com etapas (P20).
    3. **Chat → M16 e um link novo na M16** ("Objetivo com etapas") para a M15 vazia. Código: 1 h. Desvantagem: elemento sem design.
  - **Recomendação:** 1, até o design definir.

- [ ] [DECIDIR] Aviso quando a IA falha no chat — (origem: M1 e revisor, `goals_pages.dart`, 11/11/2026)
  - **Contexto:** pela 4f, a falha da IA abre o formulário manual. Hoje o app abre a M15 vazia sem dizer nada.
  - **Alternativas:** 1. **sem aviso** (atual); 2. **toast** com texto aprovado por você (30 min); 3. **balão do Broto no chat** com o botão "Preencher à mão" (1 h; estado sem design).
  - **Recomendação:** 2.

- [ ] [DECIDIR] Anexo e áudio do chat (M13/M14) só visuais — (origem: M1, `goal_chat_screen.dart`, 11/11/2026)
  - **Contexto:** o clipe e o microfone aparecem como no design, mas não fazem nada: não há contrato nem pacote aprovado.
  - **Alternativas:** 1. **manter só visuais**; 2. **esconder** (foge do design); 3. **implementar** (pacotes novos, upload no backend e um LLM que leia PDF e áudio; dias de trabalho, depende do provedor).
  - **Recomendação:** 1, até a decisão do provedor de LLM.

- [ ] [DECIDIR] Resposta da IA em tela própria × dentro do chat (M15) — (origem: M1, 11/11/2026)
  - **Contexto:** como pedido, a resposta abre a tela de etapas que já existia, preenchida. O design mostra a resposta dentro do chat, com "Achei N requisitos…", pílulas de requisitos, o slider "Máximo de estudo por dia" e "Cabe com 1 dia de folga"; título e prazo como texto, não campos.
  - **Alternativas:** 1. **manter a tela própria** (pronta); 2. **resposta no chat, editável ali** (1 dia; o endpoint precisaria devolver `requirements`).
  - **Recomendação:** 1 no MVP.

- [ ] [DECIDIR] Calendário do mobile sem navegação entre meses — (origem: revisor do M2, `week_controller.dart`, 11/11/2026)
  - **Contexto:** o mês mostrado é o do dia escolhido; o protótipo não tem setas nem arraste lateral.
  - **Problema:** um objetivo com prazo no mês seguinte nunca aparece em Prazos.
  - **Alternativas:** 1. **setas ou arraste lateral no cabeçalho**, como no web (o controlador já carrega por semana; 2–3 h com testes; elemento sem design); 2. **manter**.
  - **Recomendação:** 1, alinhado ao item do web "Limites de navegação do calendário".

- [ ] [EXECUTAR] Diferenças de design restantes no calendário do mobile — (origem: M2 e revisor, 11/11/2026)
  - **O que fazer:** (a) borda **tracejada** nos estados vazios "Nada planejado" e "Nenhuma entrega neste dia." (`week_screen.dart:132-153`), como no protótipo (`border: 1px dashed`); (b) legenda de Execução **fixa** com todos os objetivos, como `legendKeys` do protótipo (hoje segue o período visível, `week_controller.dart:260-288`).
  - **Critério de pronto:** widget tests da legenda e captura comparada com M19/M20; verificação completa verde.
  - Diferenças aceitas, sem ação: pontos do mês seguem as trilhas de exemplo (o protótipo inventa blocos em `execMonth()`); o arraste vale para o card inteiro, não só para o traço (comportamento do Google Agenda).

- [ ] [EXECUTAR] Largura do balão do usuário no chat conferida só por código — (origem: M1, `goal_chat_screen.dart:120`, 11/11/2026)
  - **O que fazer:** o `maxWidth` passou de 280 para 308 depois da última captura; refazer a captura da M14 e comparar.
  - **Critério de pronto:** quebra de linha igual à referência 14 (3 linhas).

- Ver também no Frontend: "Mostrar objetivo concluído em Prazos", "Calendário (web e mobile) não avisa erro de carregamento", "Saudação fixa".
- Ver também no Backend: "Provedor de LLM" e "Endpoint do assistente de novo objetivo", "Tipo do prazo e nome curto do objetivo".

- [ ] [DECIDIR] Validar decisão já implementada: teste do modo `http` passou a esperar o assistente HTTP — (origem: tarefa 7, `test/core/goal_assistant_dependencies_test.dart`, 12/11/2026)
  - **Contexto:** a `docs/7` §d.4 (aprovada na IA1) manda o `AppDependencies.http()` usar a `HttpGoalAssistantRepository`. O teste existente "DATA_SOURCE=http também usa o de exemplo (ainda não há endpoint)" afirmava o contrário e não estava entre os autorizados na IA4; o subagente parou.
  - **O que foi feito:** o orquestrador aplicou a troca, com vermelho → verde: o teste virou "DATA_SOURCE=http usa o assistente HTTP (IA1)" e espera a `HttpGoalAssistantRepository`. Sem isso, o mobile no modo `http` continuaria com a IA de exemplo e a prioridade 1 da rodada (mobile de ponta a ponta) não seria cumprida.
  - **Alternativas:** 1. **validar**; 2. **reverter** (o modo `http` volta à IA de exemplo).
  - **Recomendação:** 1.

- [ ] [DECIDIR] Validar decisão já implementada: espera de 1 s no ponta a ponta do mobile depois de "Preencher à mão" — (origem: verificação da tarefa 7, `integration_test/fluxo_principal_test.dart`, 12/11/2026)
  - **Contexto:** a IA4 autorizou acrescentar o toque em "Preencher à mão" no ponta a ponta. Só com ele, o teste falhou na verificação completa: a transição chat → M15 no iOS dura mais que os 300 ms do `tapText`, e o título era digitado no campo do chat (o primeiro `EditableText` da tela durante a transição). A M15 ficava sem título e "Distribuir no calendário" não enviava nada ("Não apareceu a tempo: 2 etapas no calendário").
  - **O que foi feito:** o orquestrador acrescentou **mais uma linha** ao teste, `await tester.pump(const Duration(seconds: 1));` com um comentário, logo depois de esperar a M15 (commit `4748903`). Nenhuma asserção mudou. Com ela, o ponta a ponta passou na verificação completa.
  - **Alternativas:** 1. **validar**; 2. **trocar** pela busca do campo do título por chave/rótulo (mais robusta; mexe em mais linhas do teste); 3. **reverter** (o ponta a ponta volta a falhar).
  - **Recomendação:** 1.

- [ ] [EXECUTAR] Auxiliares duplicados nos `integration_test` do mobile — (origem: tarefa 11, `feat/e2e-ia`, 12/11/2026)
  - **O que fazer:** `pumpUntil`, `tapText`, `tapLabel` e `inCardOf` foram copiados de `fluxo_principal_test.dart` para `novo_objetivo_ia_test.dart`, para não alterar o teste existente. Mover para `integration_test/support/` e importar nos dois (exige mexer no `fluxo_principal_test.dart`: precisa da sua autorização).
  - **Pronto quando:** os dois arquivos usarem o mesmo auxiliar e continuarem verdes.

- [ ] [DECIDIR] Textos dos micro-passos da IA de exemplo (modo `sample`) — (origem: tarefa 7, `sample_goal_assistant_repository.dart`, 12/11/2026)
  - **Contexto:** o protótipo (`NOVO` em `bora-data.js`) não tem micro-passos; o subagente escreveu um por etapa, marcado EXAMPLE. Nenhuma tela os mostra; só vão no `POST /goals` do modo `sample`.
  - **Alternativas:** 1. **manter**; 2. **`microSteps: []`**; 3. **pedir os textos ao produto**.
  - **Recomendação:** 1.

### Proposta de IA (11/11/2026)

- Ver também no Backend, subseção "Proposta de IA (11/11/2026)": "Aprovar a proposta de IA" (traz a `HttpGoalAssistantRepository` e os campos novos do `GoalSuggestion`: `microSteps`, `aiEstimatedMinutes`, `requirements`, `missingFields`), "O que fazer quando a IA falha" (cruza com "Aviso quando a IA falha no chat", acima), "Leitura de link e anexo (UC03)" (cruza com "Anexo e áudio do chat (M13/M14) só visuais") e "Perguntas de esclarecimento no chat".
- Ver também no Backend, rodada do Ollama local (16/11/2026): "Modelo local do Ollama" (o "analisando" do chat dura de 6 a 21 s conforme o modelo; o app desiste aos 25 s) e "Prazo relativo errado quando o LLM responde" (o prazo da M15 pode vir errado).

- [ ] [DECIDIR] Recuperação de senha de verdade (M36–M38) — (origem: plano-mobile-acesso-perfil-jardim, 19/11/2026)
  - **Contexto:** o design novo tem "Esqueci minha senha" em 3 passos (e-mail → código de 6 dígitos → nova senha). Pela MP4, o link abre só um placeholder.
  - **Problema:** quem esquece a senha não consegue entrar; o backend não envia e-mail nem troca senha.
  - **Alternativas:**
    1. **Backend de recuperação com um provedor de e-mail** (Resend, SendGrid ou SMTP): código com validade de 10 min guardado com hash, `POST /auth/password/forgot`, `POST /auth/password/verify`, `POST /auth/password/reset`, as 3 telas no mobile e no web. Prazo: 1–2 dias. Vantagem: funciona. Desvantagem: dependência e chave de um serviço externo.
    2. **Manter o placeholder até depois do hackathon.** Vantagem: zero trabalho. Desvantagem: sem saída para quem esqueceu.
  - **Recomendação:** 2 até 30/11; 1 logo depois, se houver usuários reais.
- [ ] [EXECUTAR] "Entrar com Google" no login mobile — (origem: plano-mobile-acesso-perfil-jardim, 19/11/2026)
  - **Decisão (MP3):** o botão e o "ou" ficam escondidos até existir OAuth com Google. Pronto quando houver o fluxo no backend e o botão voltar, como em M33.
- [ ] [DECIDIR] Preferências do Perfil só visuais (Bloquear apps, Lembrete da rampa, Idioma) — (origem: plano-mobile-acesso-perfil-jardim, 19/11/2026)
  - **Contexto:** pela MP8 as três linhas do Perfil (M26/M28) são só visuais.
  - **Problema:** "Bloquear apps" não bloqueia (no iOS exige a API Screen Time e permissão da Apple), o lembrete não notifica (notificações estão fora do MVP) e o idioma não traduz (o app não tem i18n).
  - **Alternativas:** 1. **manter visual** (como está); 2. **esconder até existirem**; 3. **implementar cada um** (Screen Time: dias e conta Apple; notificação local: pacote novo e 1 dia; i18n: 1–2 dias).
  - **Recomendação:** 1 até 30/11; depois, 3 começando pelo lembrete (é o que mais ajuda quem trava ao começar).
- [ ] [DECIDIR] "Enviar sugestão" sem backend (M29) — (origem: plano-mobile-acesso-perfil-jardim, 19/11/2026)
  - **Contexto:** pela MP9 a tela mostra "Sugestão enviada", mas o texto fica só em memória (repositório de exemplo); "Anexar print" está desabilitado.
  - **Problema:** o usuário acha que mandou e ninguém recebe.
  - **Alternativas:** 1. **módulo `feedback` com `POST /feedback`** (entidade, caso de uso, prisma, controller, e2e; meio dia); o anexo exige `image_picker` e armazenamento; 2. **abrir o app de e-mail** com `url_launcher` (pacote novo; 1 h); 3. **manter**.
  - **Recomendação:** 1 sem anexo.
- [x] [DECIDIR] Compromissos e Tarefas únicas têm design novo (M41–M43)[DECIDIR] Compromissos e Tarefas únicas têm design novo (M41–M43) — (origem: plano-mobile-acesso-perfil-jardim, 19/11/2026) — ver também Backend, "Compromissos fixos (Aula/Estágio) fora do contrato" — fechado pelas decisões MC1–MC14 (20/11/2026); implementado na rodada `feat/compromissos-tarefas-unicas`.
  - **Contexto:** o zip de 19/11 trouxe a aba Compromissos, o formulário de compromisso e Tarefas únicas. Pela MP10, a tab bar ficou com o Jardim e essas telas ficaram fora da rodada.
  - **Alternativas:** 1. **rodada própria** com `Commitment` persistido (migration, CRUD, contrato) e as telas, trocando a 4ª aba conforme o design; 2. **manter fora do MVP** (P8).
  - **Recomendação:** 1, porque agora existe design e o motor do calendário já usa compromissos no domínio.
- [x] [DECIDIR] Sair da conta no mobile — (origem: plano-mobile-acesso-perfil-jardim, 19/11/2026) — fechado pela AT9 (28/11/2026): "Sair da conta" na Zona de risco do Perfil; a persistência do token continua pendente (D2)
  - **Contexto:** o design do Perfil não tem "Sair"; pela MP12 não foi criado (fechar o app desloga, porque o token fica em memória).
  - **Problema:** se o token passar a persistir (item "Token do mobile só em memória"), não haverá como trocar de conta.
  - **Alternativas:** 1. **criar "Sair da conta" no fim do Perfil junto com a persistência do token**; 2. **pedir o design**.
  - **Recomendação:** 1, decidido junto com o item do token.
- [ ] [DECIDIR] Fuso do usuário no cadastro mobile — (origem: plano-mobile-acesso-perfil-jardim, 19/11/2026)
  - **Contexto:** o cadastro mobile não manda `timezone` (o Flutter não dá o nome IANA sem pacote), e vale `America/Sao_Paulo` (P1).
  - **Alternativas:** 1. **aprovar `flutter_timezone`** (pacote nativo; 1 h); 2. **manter o padrão** (o público do MVP está no Brasil).
  - **Recomendação:** 2 no MVP.
- Ver também no Frontend (web): "Tarefas leves no menu e Comprar guarda-chuva no Jardim sem ação" — o "Trocar por 50" do Jardim mobile também ficou sem ação (MP13).

- [ ] [DECIDIR] Toast "Sua rotina nova vale a partir de amanhã" não bate com o backend — (origem: S4 + orquestrador, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** ao salvar "Redefinir minha rotina" (M27), o app mostra o toast do protótipo: "Plano recalculado" / "Sua rotina nova vale a partir de amanhã".
  - **Problema:** o `PUT /scheduling/availability` recalcula o plano **a partir de agora** (`plan-regeneration.ts` usa `now: new Date()`), então a rotina nova já vale hoje. O texto promete algo diferente do que acontece.
  - **Alternativas:**
    1. **Trocar o subtítulo para "Sua rotina nova já vale a partir de hoje."** Código: um texto e um teste (15 min). Vantagem: verdadeiro. Desvantagem: foge do texto do protótipo.
    2. **Fazer o backend recalcular só a partir de amanhã.** Código: orquestrador e e2e (2–3 h). Vantagem: texto do design. Desvantagem: os blocos de hoje ficam com a rotina antiga.
    3. **Manter.**
  - **Recomendação:** 1.
- [ ] [DECIDIR] Limite diário quebrado (ex.: 3h30) no "Redefinir minha rotina" — (origem: S4, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** o slider do M27 vai de 1h a 8h, de hora em hora; o backend aceita múltiplos de 30 min.
  - **Problema:** um limite gravado como 210 min aparece como 4h e, se o usuário salvar, vira 240 sem ele perceber.
  - **Alternativas:** 1. **manter o arredondamento**; 2. **slider de 30 em 30 min com rótulo "3h30"** (tela, controlador e testes; 1 h).
  - **Recomendação:** 2, se o web grava meias horas; senão 1.
- [ ] [EXECUTAR] Pintar a grade do "Redefinir minha rotina" arrastando o dedo — (origem: S4, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - O protótipo pinta células arrastando; o app só alterna com toque. Fazer: gesto de arrastar em `routine_screen.dart` que pinta com o estado da primeira célula. Pronto quando um widget test de arrastar sobre 3 células deixar as 3 pintadas.
- [ ] [DECIDIR] Textos de erro sem design no Acesso, Perfil, Rotina e Sugestão — (origem: S2, S3, S4, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** o design não define estados de erro. Os subagentes escreveram textos no tom do app:
    - Cadastro, rede: "Não deu pra criar sua conta agora. Tenta de novo?";
    - Cadastro criado mas login falhou: "Sua conta foi criada, mas não deu pra entrar agora. Tenta pelo login." (evita o usuário tentar de novo e cair num 409);
    - Perfil: "Não deu pra carregar o seu perfil." / "Não deu pra carregar o máximo por dia." (linha pequena em `--danger`);
    - Rotina: "Não deu pra carregar sua rotina. Tenta de novo?" / "Não deu pra salvar sua rotina. Tenta de novo?";
    - Sugestão: "Não deu pra enviar agora. Tenta de novo?".
  - **Alternativas:** 1. **aprovar os textos**; 2. **pedir os estados de erro ao design**.
  - **Recomendação:** 1.
- [ ] [DECIDIR] "Anexar print (opcional)" desabilitado em cinza — (origem: S4, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** pela MP9 o anexo não funciona. O app mostra o botão em `--tx2` (cinza), anunciado como desabilitado; o design (M29) mostra em azul.
  - **Alternativas:** 1. **cinza** (como está): deixa claro que não funciona; 2. **azul como no design**: fiel, mas parece tocável e não faz nada.
  - **Recomendação:** 1.
- [ ] [DECIDIR] Linhas do Perfil sem fundo ao toque — (origem: S3, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** no design (M26), as linhas de Configurações escurecem para `--s2` ao toque; no app não mudam (os widgets de linha do app usam `GestureDetector`).
  - **Alternativas:** 1. **manter**; 2. **criar um widget de linha tocável em `core/widgets` com o fundo ao toque** e usar no Perfil (1 h).
  - **Recomendação:** 2 quando houver uma segunda tela com linhas tocáveis.
- [ ] [DECIDIR] Humor do Broto grande do Jardim — (origem: S5, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** no protótipo, o Broto do Jardim segue a energia do check-in; no app está fixo em "ok" (o Jardim não conhece o check-in).
  - **Alternativas:** 1. **manter fixo**; 2. **ler a energia da sessão da rampa** (cria dependência entre gamification e activation).
  - **Recomendação:** 1, até a gamificação sair da P18.
- [ ] [EXECUTAR] Círculo do play do "Vamos começar?" no tema escuro — (origem: orquestrador, comparação visual, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - No escuro (M30), o círculo atrás do play é claro e translúcido; no app sai escuro (`docs/mobile/comparacoes/m30-hoje-escuro-r1.jpg`). O botão já existia antes desta rodada. Fazer: conferir no `.dc.html` a cor do círculo no escuro e usar o token certo. Pronto quando a captura do Hoje escuro bater com `screens/30`.
- [ ] [EXECUTAR] Captura do Cadastro preenchido (M35) no simulador — (origem: orquestrador, comparação visual, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - Digitar pelo controle do simulador mandou o texto para o campo errado; o estado preenchido (dicas verdes e termos marcados) foi verificado pelo ponta a ponta `acesso_perfil_test.dart`, mas falta a imagem `m35-cadastro-preenchido-r1.jpg`. Pronto quando ela estiver em `docs/mobile/comparacoes/`.
- [x] [INVESTIGAR] Ícones da barra de status do iOS no tema escuro — (origem: S6, rodada mobile acesso/perfil/jardim, 19/11/2026) — fechado na comparação visual: no simulador, com o app no escuro, a hora e a bateria ficam claras (`m26-perfil-escuro-r1.jpg`, `m30-hoje-escuro-r1.jpg`).
- [ ] [EXECUTAR] Controladores avisam a tela depois de destruídos — (origem: revisor, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - Se o usuário sai da tela enquanto o `me()`, o `getAvailability` ou o `login` ainda respondem, o `notifyListeners()` do `finally` roda depois do `dispose` e, em debug, gera o erro "used after being disposed" (em release não acontece nada). Já corrigido no `RoutineController` e no `SuggestionController`. Fazer o mesmo guarda `_disposed` (padrão do `goal_chat_controller.dart`) em `ProfileController`, `GardenController`, `LoginController` e `RegisterController`, de preferência num mixin em `core/`. Pronto quando cada um tiver o teste "o Future que termina depois do dispose não avisa ninguém".
- [ ] [DECIDIR] Mensagem genérica no 422 do cadastro — (origem: revisor, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** no 422, o cadastro mostra a `message` do backend, que é "Dados inválidos.". Como o app confere as mesmas regras antes de enviar, é raro acontecer.
  - **Alternativas:** 1. **manter**; 2. **traduzir os `details`** (`user.name.display.name`, `user.email.invalid.email`, `user.password.strong.password`) em mensagens por campo (1 h).
  - **Recomendação:** 2, junto com o item "Textos de erro sem design".
- [ ] [DECIDIR] Conta criada mas o login falhou: o usuário ainda pode reenviar o cadastro — (origem: revisor, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** nesse caso a tela mostra "Sua conta foi criada, mas não deu pra entrar agora. Tenta pelo login." e mantém o botão "Criar conta" ativo; reenviar dá 409 "E-mail já cadastrado.".
  - **Alternativas:** 1. **manter**; 2. **levar ao Login com o e-mail preenchido** (rota com parâmetro; 1 h); 3. **desabilitar "Criar conta" nesse estado** (30 min).
  - **Recomendação:** 2.
- [ ] [DECIDIR] Perfil aberto pelo Hoje destaca a aba Jardim — (origem: revisor, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** pela MP10, o Perfil pertence ao grupo do Jardim (como no protótipo), então a aba Jardim fica ativa mesmo quando o Perfil foi aberto pelo Hoje; o "voltar" leva ao Hoje.
  - **Alternativas:** 1. **manter** (igual ao protótipo); 2. **nenhuma aba ativa no Perfil**, como na tab bar nova do design (M40).
  - **Recomendação:** 1 enquanto a aba Jardim existir.
- [ ] [DECIDIR] "Tentar de novo" na falha de carga do Redefinir rotina não tem design — (origem: S4, correção do revisor, 19/11/2026)
  - **Contexto:** se a rotina não carrega, a tela bloqueia a grade e mostra a mensagem com um botão terciário "Tentar de novo" logo abaixo (impede gravar uma grade vazia por cima da real).
  - **Alternativas:** 1. **aprovar**; 2. **pedir o estado de erro ao design**.
  - **Recomendação:** 1.
- [ ] [EXECUTAR] Atualizar `SEMESTER_END` a cada semestre — (origem: plano-mobile-compromissos-tarefas-unicas, 20/11/2026)
  - Pela MC3, o chip "Fim do semestre" usa a data fixa `SEMESTER_END` dos `env/*.json` (`2026-12-12`). Pronto quando a data for trocada no início de cada semestre (ou quando o perfil tiver um campo próprio).
- [ ] [DECIDIR] Caminho para as Tarefas únicas e compromissos no Hoje sem design — (origem: plano-mobile-compromissos-tarefas-unicas, 20/11/2026)
  - **Contexto:** o design não tem caminho para as Tarefas únicas nem mostra compromissos no Hoje. Pela MC9 e MC6, o app cria o botão "Tarefas únicas" ao lado de "SEU DIA" e mostra os compromissos na linha do tempo do Hoje.
  - **Alternativas:** 1. **manter** (como decidido); 2. **pedir os dois ao design** e ajustar depois.
  - **Recomendação:** 2, sem bloquear a rodada.
- [ ] [DECIDIR] Web sem tela de compromissos e de tarefas únicas — (origem: plano-mobile-compromissos-tarefas-unicas, 20/11/2026) — ver também Frontend
  - **Contexto:** os compromissos já ocupam o plano também no web (o backend é o mesmo), mas o web não tem como cadastrá-los, vê-los no calendário nem gerenciar tarefas únicas.
  - **Alternativas:** 1. **rodada própria para o web** (telas no calendário W15–W16 e uma lista de tarefas); 2. **manter o web sem** até o design do web.
  - **Recomendação:** 1 depois do MVP mobile.
- [ ] [DECIDIR] "Sem prazo" aparece nos date pickers de compromisso e de tarefa única — (origem: M2, M3, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Contexto:** o `showBoraDatePicker` (`features/goals/presentation/date_picker_sheet.dart`) sempre mostra "Sem prazo"; no protótipo ele só existe no Prazo do objetivo. No formulário de compromisso e no "Escolher dia" das tarefas, tocar nele não muda nada.
  - **Alternativas:** 1. **parâmetro `showClear`** no sheet, falso nesses usos (30 min, com teste); 2. **manter**.
  - **Recomendação:** 1.
- [ ] [DECIDIR] Textos e estados sem design nos compromissos e tarefas — (origem: M1, M2, M3, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Contexto:** mensagens de erro ("Não deu pra carregar os compromissos.", "Não deu pra salvar agora. Tenta de novo.", "Não deu pra carregar/salvar/excluir o compromisso. Tenta de novo?", "Não deu pra carregar suas tarefas." etc.), indicador de carregamento no editar, sheet do seletor de hora ("Início"/"Fim" + "Confirmar"), botões desabilitados durante uma ação e o ponto vazado do compromisso na linha do tempo do Hoje (MC6).
  - **Alternativas:** 1. **aprovar como estão** (seguem o tom do app); 2. **pedir ao design**.
  - **Recomendação:** 1.
- [ ] [DECIDIR] Toast "Encerrado" quando a série acaba no primeiro dia — (origem: M1, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Contexto:** "Excluir desse dia em diante" na primeira ocorrência apaga a série (MC12), mas o toast do protótipo diz "Encerrado / O último foi em (dia anterior)", e esse dia nunca teve compromisso.
  - **Alternativas:** 1. **manter como o protótipo**; 2. **mostrar "Compromisso excluído"** nesse caso (exige um `GET` antes para saber a `startDate`).
  - **Recomendação:** 1 no MVP.
- [ ] [EXECUTAR] Unificar a borda tracejada (`commitment_card.dart` e `garden_screen.dart`) — (origem: M1, rodada de compromissos e tarefas únicas, 20/11/2026)
  - Mover um painter com espessura configurável para `core/widgets` e usar nos dois. Pronto quando os dois usarem o mesmo painter e os testes passarem.
- [ ] [DECIDIR] Linha inalcançável no `WeekController._deadlineGoals` — (origem: M1, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Contexto:** a constante `showDoneGoalsInDeadlines = true` deixa 1 linha sem cobertura (208/209). Ligado ao [DECIDIR] antigo de mostrar objetivos concluídos em Prazos.
  - **Alternativas:** 1. tirar a constante e o ramo morto; 2. manter.
  - **Recomendação:** decidir junto com o item original.
- [ ] [DECIDIR] Compromisso que termina à meia-noite — (origem: revisor, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Contexto:** o domínio aceita `endMinute = 1440` (MC2), mas o seletor de hora do app (`CupertinoDatePicker`) vai só até 23:55.
  - **Alternativas:** 1. **tratar 00:00 escolhido no fim como 24:00** (1440) (30 min, com teste); 2. **manter** (o último fim possível é 23:55).
  - **Recomendação:** 1.
- [ ] [DECIDIR] "Fim do semestre" vencido — (origem: revisor, rodada de compromissos e tarefas únicas, 20/11/2026) — ver também `SEMESTER_END`
  - **Contexto:** se a data `SEMESTER_END` já passou, o chip "Fim do semestre" manda `endDate < startDate` e o backend responde 422.
  - **Alternativas:** 1. **esconder ou desabilitar o chip quando a data já passou** (30 min); 2. **manter** (depende de atualizar o `env` a cada semestre).
  - **Recomendação:** 1.

### Teste no Android físico (28/11/2026)

Pedidos do usuário ao testar o app num Galaxy S23 (Android 17) e o web, depois da rodada de compromissos e IA.

- [x] [EXECUTAR] Ícone do app com o Broto e nome "Bora" na lista de apps — (origem: teste no Android, 28/11/2026; nome "Bora" decidido pelo usuário em 28/11/2026) — branch `fix/mobile-android-icone-calendario-barra`
  - O app aparecia como "oitenta", com o ícone padrão do Flutter, e o usuário não o achava. Agora o ícone é o Broto (humor `ok`) sobre o `priSoft` (#D1FAE5): adaptativo no Android 8+ e todos os tamanhos do iOS. Os PNGs saem de `apps/mobile/tool/app_icon/generate_app_icon_test.dart` (rodar de novo se o Broto mudar). Se o nome do app mudar, trocar `android:label` e `CFBundleDisplayName`.
- [x] [EXECUTAR] "BOTTOM OVERFLOWED BY 2.0 PIXELS" no mês do calendário (Semana) — (origem: teste no Android, 28/11/2026) — branch `fix/mobile-android-icone-calendario-barra`
  - Causa: `monthPagerHeight` reservava 298 px e um mês de 6 semanas ocupa 300 (célula de 45, não 46, mais os 5 espaços de 2). A altura agora sai das mesmas medidas da grade; teste `month_pager_layout_test.dart`.
- [x] [EXECUTAR] Esconder a barra de navegação do Android (voltar, início, abas) — (origem: teste no Android, 28/11/2026; AT2) — branch `fix/mobile-android-icone-calendario-barra`, commits `2d6d5a1` e `db42905`
  - **Ajuste de 28/11 (AT2):** enquanto os botões aparecem, a tab bar sobe inteira, sem esticar, e o app pinta o `#047857` translúcido atrás deles.
  - A barra some ao abrir o app e ao voltar para ele; arrastar de baixo mostra, e ela some sozinha depois de 3 s. A barra de status (hora e bateria) continua. Não muda nada no iOS. `core/system/immersive_navigation_bar.dart`, teste `immersive_navigation_bar_test.dart`.
- [ ] [EXECUTAR] Editar o perfil (nome e e-mail) no app e no web — **decidido em 28/11/2026 (AT3): alternativa 2, nome e e-mail, com a senha atual para trocar o e-mail.** Pronto quando `PATCH /auth/me` tiver testes de integração e o Perfil (app) e as Configurações (web) editarem os dois. Item original: — (origem: teste no Android, 28/11/2026) — afeta Backend, Frontend (W26) e Mobile (M26)
  - **Contexto:** o Perfil do app e as Configurações do web mostram nome e e-mail, mas não deixam editar. Cada usuário já tem um ID único (UUID em `User.id`); o nome e o e-mail são só dados, então trocá-los não quebra objetivos, plano nem sessões.
  - **Problema:** não existe rota para alterar a conta (só `register`, `login`, `me` e `demo`), nem tela no design para editar.
  - **Alternativas:** 1. **só o nome** (`PATCH /auth/me` com `name`; linha "Nome" tocável no Perfil e campo nas Configurações; meio dia com testes); 2. **nome e e-mail**, pedindo a senha atual para trocar o e-mail (o e-mail é o login; 1 dia); 3. **nome, e-mail e senha** (troca de senha com a atual + nova; 1 dia e meio). Em todas, falta o design da tela de edição.
  - **Recomendação:** 2 agora (é o que o usuário pediu e evita alguém trocar o e-mail com o celular desbloqueado de outra pessoa); senha junto com a recuperação de senha (item "Recuperação de senha de verdade").
- [ ] [EXECUTAR] Interruptor do e-mail diário também no app — **decidido em 28/11/2026 (AT4): fica no web e entra no app, só visual, até o envio existir.** Pronto quando o Perfil do app tiver o interruptor. Item original: — (origem: teste no Android, 28/11/2026) — ver também Frontend (W26)
  - **Contexto:** o web tem o interruptor "E-mail diário" nas Configurações (W26); o Perfil do app (M26) não tem, e o design mobile também não. O backend ainda não envia e-mail nenhum (UC23 fora da fatia): o interruptor do web grava só no repositório de exemplo.
  - **Alternativas:** 1. **pôr o interruptor no Perfil do app** como só visual, igual ao web hoje (1 h); 2. **fazer o e-mail de verdade** (preferência no backend, provedor de e-mail, envio agendado; 2–3 dias) e aí pôr o interruptor nos dois; 3. **esconder no web** até existir o envio.
  - **Recomendação:** 3 até o e-mail existir; não mostrar uma opção que não faz nada.
- [ ] [EXECUTAR] "Máximo por dia" do Perfil não é editável direto — **decidido em 28/11/2026 (AT5): alternativa 1, seletor só do limite.** Pronto quando tocar na linha abrir o seletor, salvar e recalcular. Item original: — (origem: teste no Android, 28/11/2026)
  - **Contexto:** o Perfil mostra o "Máximo por dia", mas para mudar é preciso entrar em "Redefinir minha rotina". O usuário achou pouco intuitivo.
  - **Alternativas:** 1. **tocar na linha abre um seletor só do limite** (sheet com +/−, salva com `PUT /scheduling/availability` mantendo a grade e recalcula; meio dia); 2. **tocar na linha abre o "Redefinir minha rotina"** já rolado até o limite (1 h); 3. **manter**.
  - **Recomendação:** 1.
- [ ] [EXECUTAR] Idioma e "Enviar sugestão" no web — **decidido em 28/11/2026 (AT6, AT7): os dois aparecem no web, só visuais, como no app; backend e tradução depois.** Pronto quando as Configurações do web tiverem os dois. Item original: — (origem: teste no Android, 28/11/2026) — ver também os itens "Preferências do Perfil só visuais" e "Enviar sugestão sem backend", acima
  - **Contexto:** o app tem Idioma e Enviar sugestão no Perfil; o web não tem nenhum dos dois. O `design/web/SCREENS.md` diz que no web "não há idioma e enviar sugestão" (UC32 parcial). No app os dois são só visuais (MP8, MP9).
  - **Alternativas:** 1. **pôr os dois no web igual ao app** (visuais; 1 h, sem design web); 2. **fazer de verdade nos dois**: sugestão com `POST /feedback` (meio dia) e idioma com i18n (1–2 dias por plataforma); 3. **manter** como o design manda.
  - **Recomendação:** 2 para a sugestão (o mesmo endpoint serve aos dois) e 3 para o idioma até haver tradução.

- [ ] [EXECUTAR] "Lembrete da rampa" no Perfil não é editável e não explica o que é — **decidido em 28/11/2026 (AT8): alternativa 1, editável e só visual.** Item original: — (origem: teste no Android, 28/11/2026)
  - **Contexto:** a linha mostra "09:30" fixo. A ideia do design (M26) é um aviso no celular, todo dia nesse horário, chamando para começar a rampa. Pela MP8 é só visual: notificações estão fora do MVP.
  - **Alternativas:** 1. **editável e só visual**: tocar abre um seletor de horário e um subtítulo explica ("Um aviso por dia pra começar a rampa"); 1–2 h; 2. **de verdade**: notificação local (pacote novo, permissão do Android e do iOS); 1 dia; 3. **esconder** até existir.
  - **Recomendação:** 1 agora (mantém o MVP completo nas telas, como o e-mail diário, AT4) e 2 depois.
- [ ] [EXECUTAR] "Zona de risco": trocar senha, sair da conta e apagar conta (app e web) — **decidido em 28/11/2026 (AT9): alternativa 1, os três de verdade; a conta demo não pode ser apagada.** Item original: — (origem: teste no Android, 28/11/2026) — afeta Backend, Frontend (W26) e Mobile (M26)
  - **Contexto:** não há como trocar a senha logado, sair da conta no app (o web tem "Sair"; no app, fechar desloga, MP12) nem apagar a conta. Nenhum dos três tem design.
  - **Alternativas:** 1. **os três de verdade**: `PATCH /auth/me/password` (senha atual + nova, regra de senha forte), "Sair" no app (limpa a sessão e volta ao login) e `DELETE /auth/me` (apaga a conta com confirmação digitando a senha; o `User.deletedAt` já existe, então pode ser exclusão lógica); 1 dia e meio; 2. **só sair e trocar senha** de verdade, apagar conta só visual; 1 dia; 3. **os três só visuais**; 2 h.
  - **Recomendação:** 1. Apagar a conta de verdade é exigido pela LGPD e pelas lojas (Google Play e App Store pedem exclusão de conta dentro do app).

- [ ] [EXECUTAR] Revisar os Termos de uso e a Política de privacidade antes do lançamento — (origem: pedido do dono do produto, 28/11/2026) — afeta Frontend e Mobile
  - **Contexto:** os textos estão em `apps/frontend/src/modules/legal/data/legal-texts.ts` (o app gera o seu com `bash apps/mobile/tool/legal/generate_legal_texts.sh`) e aparecem com o aviso "Versão preliminar". Responsável: "equipe do Bora (Hack Brasil 2026)"; contato: contato@bora.app; sem idade mínima, com consentimento dos pais abaixo de 12 anos (LGPD, art. 14).
  - **Falta:** confirmar que contato@bora.app existe e é lido; pôr o fornecedor da IA e onde ficam o servidor e o banco quando forem escolhidos (§4 e §5 da política); revisão jurídica, de preferência. Pronto quando o aviso de versão preliminar puder sair.

## Backend (inclui domínio modules/*, banco e contrato)
- [ ] [EXECUTAR] `SplitCommitmentFrom` atômico — (origem: revisor, rodada de compromissos e tarefas únicas, 20/11/2026)
  - O caso de uso encerra (ou apaga) a série antiga e cria a nova em duas chamadas separadas; se a segunda falhar, as ocorrências futuras se perdem. Fazer: um método do repositório (ex.: `split(previous|null, next)`) que grava os dois numa `$transaction` do Prisma, com teste de falha. Pronto quando uma falha no `create` deixa a série antiga intacta.
- [ ] [EXECUTAR] `SetSingleTaskDone` com mais de uma etapa — (origem: revisor, rodada de compromissos e tarefas únicas, 20/11/2026)
  - Só a primeira etapa é marcada; uma tarefa `single` com 2 etapas (a API aceita) fica `active`. Fazer: marcar todas as etapas não `superseded`, ou o `Goal.validate()` recusar `single` com mais de 1 etapa (a §2.1 já diz "exatamente 1"; conferir se a regra existe no `validate`). Pronto quando o teste com 2 etapas der `done` ou 422.
- [ ] [DECIDIR] `deadline` em tarefa `single` — (origem: revisor, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Contexto:** pela MC7 a tarefa única não tem prazo, mas o backend ainda aceita `deadline` com `kind: single`. O app já não manda (corrigido no "Preencher à mão").
  - **Alternativas:** 1. **o domínio recusar `deadline` em `single`** (422); 2. **manter aceitando**.
  - **Recomendação:** 1.
- [ ] [EXECUTAR] Registrar na §5b que `startDate` só vale no `PATCH scope=all` — (origem: revisor, rodada de compromissos e tarefas únicas, 20/11/2026)
  - No `scope=following`, o `startDate` do corpo é ignorado (a série nova começa no `fromDate`). Escrever isso na tabela do contrato.
- [ ] [DECIDIR] `plannedDate` nas respostas de `POST /goals`, `PATCH …/done` e `GET /goals/:id` — (origem: D2, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Contexto:** pela §8.2 a saída do `CreateGoal` ficou igual; o `plannedDate` só aparece no `GET /goals`. O app recarrega a lista depois de cada ação.
  - **Alternativas:** 1. **manter**; 2. **acrescentar ao cabeçalho do objetivo** (campo aditivo nas 3 respostas).
  - **Recomendação:** 1.
- [ ] [DECIDIR] Bordas do `endingBefore` registradas pelo D1 — (origem: D1, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Contexto:** o domínio devolve `null` (apaga a série) também quando sobra só um intervalo sem nenhum dia da semana da série, e não alonga uma série cujo `endDate` já era anterior a `date − 1`. A §8.1 não dizia isso.
  - **Alternativas:** 1. **registrar as duas regras na §8.1** (como implementado); 2. mudar o comportamento.
  - **Recomendação:** 1.
- [ ] [INVESTIGAR] Worktrees novas sem o `dist` do `@oitenta/shared` — (origem: D1, D2, rodada de compromissos e tarefas únicas, 20/11/2026)
  - **Sintoma:** os testes do módulo falham com `Cannot find module '@oitenta/shared'` até rodar `npx turbo run build --filter=@oitenta/shared`. **Possível saída:** incluir o build dos pacotes no preparo das worktrees (P28).

- [ ] [DECIDIR] O mínimo de 2 caracteres do nome conta os espaços das pontas — (origem: S1, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** pela MP2, o nome vai de 2 a 80 caracteres. O `RegisterUser` não apara o nome, e a `MinLengthRule(2)` mede o texto bruto: `" A"` passa no backend com uma letra só. O mobile apara antes de validar e de enviar.
  - **Alternativas:** 1. **aparar o nome no `RegisterUser` antes de validar e gravar** (teste e ajuste; 30 min); 2. **aceitar como está**.
  - **Recomendação:** 1, porque o backend fica igual ao mobile e não grava espaços.
- [ ] [DECIDIR] Nome vazio na `DisplayNameRule` — (origem: S1, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Contexto:** o plano pedia que a regra recusasse `""` e `"   "`, mas também que seguisse o contrato das outras regras (`validateStringValues`), que deixa o vazio para a `RequiredRule`. Foi implementado o contrato: vazio dá só `user.name.required`.
  - **Alternativas:** 1. **manter** (um erro por causa, igual às outras regras); 2. **a regra também recusa o vazio** (o vazio passa a gerar dois códigos e um teste do `User` muda).
  - **Recomendação:** 1.
- [ ] [INVESTIGAR] Testes e2e do backend estouram o tempo de 5 s com a máquina carregada — (origem: orquestrador, verificação completa, rodada mobile acesso/perfil/jardim, 19/11/2026)
  - **Sintoma:** em 19/11, com o simulador, o app e dois backends extras no ar (e a máquina saindo do repouso), `npm --workspace apps/backend run test:e2e` falhou 4 vezes seguidas com "Exceeded timeout of 5000 ms for a hook/test", sempre em suítes diferentes (scheduling, goals-orchestrators, plan-views, goal-assistant) e com o `pg-pool` demorando para conectar. Com a máquina livre, passou inteiro (139/139, 71 s), e cada suíte sozinha passa.
  - **Onde olhar:** o `testTimeout` padrão do Jest (5 s) em `apps/backend/test/jest-e2e.json`; o `beforeEach` da suíte de scheduling que cria usuários (bcrypt).
  - **Possível saída:** `testTimeout: 15000` no e2e, se voltar a acontecer na CI.

- [ ] [DECIDIR] Cor do objetivo (P4), leitura ambígua — (origem: diário, pergunta 1, B1, 10/11/2026)
  - **Contexto:** pela P4, cada objetivo recebe uma cor de 1 a 4, "o próximo índice entre os objetivos ativos, voltando ao 1 depois do 4". A B1 implementou `(nº de ativos % 4) + 1`.
  - **Problema:** a fórmula repete cor entre objetivos ativos. Com A=1, B=2 e C=3, se B for concluído, o próximo recebe 3, a mesma cor de C.
  - **Alternativas:**
    1. **Manter `(nº de ativos % 4) + 1`.** Código: nada. Vantagem: já testado. Desvantagem: dois ativos com a mesma cor no calendário.
    2. **Menor índice de 1 a 4 que nenhum ativo usa;** com os 4 ocupados, a cor menos usada, com desempate pelo menor índice. Código: uma função e um teste no `CreateGoal` (cerca de 1 h). Telas: nenhuma mudança. Vantagem: mantém os cenários atuais ({1,2} → 3; {1..4} → 1) e dá {1,3} → 2. Desvantagem: regra um pouco mais longa.
  - **Recomendação:** 2 (sugestão do revisor). Cores repetidas confundem justamente o calendário, que é o mínimo obrigatório.

- [ ] [DECIDIR] Horizonte do plano para objetivos sem prazo — (origem: diário, pergunta 2, B2, 10/11/2026)
  - **Contexto:** o motor do plano aloca até o maior prazo ou até hoje + 28 dias, o que for mais tarde.
  - **Problema:** o que passa disso fica como `unscheduledMinutes`, com `feasible` continuando `true`. Ninguém confirmou o limite de 28 dias.
  - **Alternativas:**
    1. **Manter 28 dias.** Vantagem: plano leve e já testado. Desvantagem: um objetivo grande sem prazo fica com parte sem agenda, sem aviso.
    2. **Horizonte maior** (ex.: 90 dias). Código: uma constante e testes (30 min). Vantagem: quase nada fica sem agenda. Desvantagem: recálculo mais pesado e plano longo demais para ser útil.
    3. **Manter 28 dias e avisar na tela quando há `unscheduledMinutes`.** Código: telas web e mobile (1–2 h). Desvantagem: aviso sem design.
  - **Recomendação:** 1 no MVP. O recálculo acontece a cada registro, então o que fica de fora entra nas semanas seguintes.

- [ ] [DECIDIR] Resto menor que 30 min ao dividir uma etapa — (origem: diário, pergunta 3, B2, 10/11/2026)
  - **Contexto:** o bloco mínimo é de 30 min (4c, P10). Ao dividir uma etapa, o motor evita deixar um resto menor que 30 min, o que a P10 não exige.
  - **Problema:** em casos raros isso torna inviável um plano que caberia (ex.: 90 min com 75 livres vira 60 + 30).
  - **Alternativas:**
    1. **Manter a heurística.** Vantagem: nunca há bloco de 15 min. Desvantagem: raros "não cabe" falsos.
    2. **Guloso puro.** Código: o motor e os testes de borda (1–2 h). Vantagem: aproveita todo o tempo livre. Desvantagem: pode criar sobra de 15 min, abaixo do bloco mínimo.
  - **Recomendação:** 1. Bloco de 15 min contradiz o bloco mínimo, e o caso inviável é raro.

- [ ] [DECIDIR] Bloco fixado ou em andamento no recálculo — (origem: diário, pergunta 4, B2, 10/11/2026)
  - **Contexto:** no recálculo, um bloco fixado no futuro (ou um `planned` em andamento) ocupa o horário.
  - **Problema:** ele não desconta os minutos da etapa, que é alocada de novo por inteiro. No MVP não há como fixar bloco, então o impacto hoje é baixo.
  - **Alternativas:**
    1. **Manter.** Vantagem: nada a fazer. Desvantagem: quando existir "fixar", a etapa fica com tempo a mais no plano.
    2. **Descontar os minutos do bloco fixado da etapa.** Código: o motor e testes (1–2 h). Vantagem: plano correto. Desvantagem: trabalho sem efeito visível no MVP.
  - **Recomendação:** 2, mas só quando a função "fixar bloco" entrar.

- [ ] [DECIDIR] Blocos `missed` contam no "3h de 3h"? — (origem: diário, pergunta 5, B2, 10/11/2026)
  - **Contexto:** o calendário mostra por dia o tempo usado sobre o limite ("3h de 3h").
  - **Problema:** hoje os blocos não feitos (`missed`) contam no `usedMinutes` do dia e da semana e no limite do recálculo do mesmo dia.
  - **Alternativas:**
    1. **Manter (contam).** Vantagem: depois de um "não rolou", o dia não é enchido de novo, o que respeita o limite do usuário. Desvantagem: o "3h de 3h" inclui tempo que não foi usado.
    2. **Não contar.** Código: o motor, o `GetDayPlan`/`GetWeekPlan` e os testes (1–2 h). Vantagem: número fiel ao que foi feito. Desvantagem: o recálculo pode reagendar no mesmo dia o que acabou de falhar.
  - **Recomendação:** 1. Evita encher de novo um dia que já deu errado, o que combina com o público que trava.

- [ ] [DECIDIR] Tamanho máximo do título do compromisso — (origem: diário, pergunta 6, B2, 10/11/2026)
  - **Contexto:** a P2 limita a 120 caracteres os títulos de objetivo e etapa.
  - **Problema:** o título do compromisso (aula, estágio) não tem limite.
  - **Alternativas:** 1. **120 caracteres, como a P2** (regra e teste, 30 min); 2. **sem limite** (nada a fazer; risco de texto gigante quebrar a tela).
  - **Recomendação:** 1, pela consistência com a P2.

- [ ] [DECIDIR] `replaceFutureAutoBlocks` com bloco de outro usuário — (origem: diário, pergunta 7, C2, 10/11/2026)
  - **Contexto:** o adaptador Prisma grava os blocos novos do plano com o `userId` do parâmetro.
  - **Problema:** se um bloco chegar com outro `userId` (bug do motor), ele é gravado em nome do usuário do parâmetro, sem aviso.
  - **Alternativas:**
    1. **Manter, com um teste que prove a reescrita.** Código: um teste (30 min). Vantagem: nunca grava em nome de outro usuário. Desvantagem: esconde um eventual bug do motor.
    2. **Lançar erro.** Código: a checagem e um teste (30 min). Vantagem: revela o bug. Desvantagem: um bug do motor derruba o recálculo do usuário.
  - **Recomendação:** 1 (sugestão do revisor), porque a posse continua garantida.

- [ ] [DECIDIR] Textos da rampa vindos do catálogo do domínio — (origem: diário, pergunta 11, B4/D1, 10/11/2026) — afeta as telas do Frontend
  - **Contexto:** desde a Etapa D, as opções da rampa vêm do catálogo fixo do domínio (`activation`): alongamento, contas etc.
  - **Problema:** os textos do catálogo são os do protótipo mobile, diferentes dos do protótipo web.
  - **Alternativas:**
    1. **Aceitar os textos do catálogo nos dois apps.** Vantagem: uma fonte só. Desvantagem: o web difere do protótipo web.
    2. **O catálogo ganha os textos do web.** Código: o catálogo e testes do domínio (1–2 h). Desvantagem: dois conjuntos de textos para o mesmo degrau, sem critério de qual usar.
  - **Recomendação:** 1. O catálogo é provisório (4a) e será trocado pelas tarefas do usuário.

- [ ] [DECIDIR] O progresso de uma etapa pode regredir — (origem: diário, pergunta 15, C4, 10/11/2026)
  - **Contexto:** pela 4h e pelo docs/3, um registro `partial` define o progresso da etapa como o `partialPct`.
  - **Problema:** uma sessão `partial` com 30% numa etapa em 80% (ou já `done`) baixa a etapa para 30% e devolve minutos ao plano.
  - **Alternativas:**
    1. **Manter (o usuário corrige a estimativa).** Vantagem: o usuário pode admitir que avaliou mal. Desvantagem: um toque errado desfaz progresso.
    2. **O progresso nunca recua** (`max(atual, novo)`), regra na entidade `Step`. Código: domínio, testes e um teste de integração (1–2 h). Vantagem: protege o progresso, o que importa para quem desanima fácil. Desvantagem: corrigir para baixo exige outra função.
  - **Recomendação:** 2. Perder progresso por engano é pior para o público do produto do que não conseguir corrigir para baixo.

- [ ] [DECIDIR] Nome do usuário demo — (origem: diário, pergunta 20 e problema 12, E-web, 10/11/2026) — afeta Frontend e Mobile
  - **Contexto:** o botão do login diz "Entrar direto como Arthur (demo)", como no protótipo; o seed cria a "Usuária Demo".
  - **Problema:** a saudação, a sidebar e o avatar mostram "Usuária Demo"/"U", contra o botão.
  - **Alternativas:**
    1. **Trocar o seed para "Arthur".** Código: o seed e o `db:reset-demo` (30 min). Vantagem: tudo igual ao protótipo. Desvantagem: o nome do demo é o de uma pessoa do time.
    2. **Trocar o texto do botão** (web e mobile) para "Entrar como demo". Código: dois textos e os testes (30 min). Vantagem: neutro. Desvantagem: foge do protótipo.
  - **Recomendação:** 1. Mantém a fidelidade ao design com a menor mudança.

- [ ] [DECIDIR] Validar decisão já implementada: script `db:reset-demo` e seu uso no ponta a ponta — (origem: diário, pergunta 21, problema 9 e "decisões que tomei sem você", E-dep, 10/11/2026) — afeta os ponta a ponta do Frontend e do Mobile
  - **Contexto:** o script apaga sessões, blocos, objetivos e disponibilidade do usuário demo, mantendo o usuário. O Playwright o roda a cada execução, e o ponta a ponta do mobile pede para rodá-lo antes.
  - **Problema:** testar no banco local apaga o que você fez à mão com o demo.
  - **Alternativas:**
    1. **Manter.** Vantagem: simples; o demo começa sempre do zero. Desvantagem: perde os dados manuais do demo.
    2. **Usuário só para os testes** (ex.: `e2e@…`), criado pelo próprio teste. Código: seed ou cadastro no teste, e o script passa a zerar esse usuário (1–2 h). Vantagem: o demo manual fica intacto. Desvantagem: o teste deixa de usar o botão "Entrar direto como … (demo)".
  - **Recomendação:** 2, se você usa o demo à mão no mesmo banco; senão, 1.

- [ ] [DECIDIR] `postinstall` no backend rodando `prisma generate` — (origem: diário, problema 1, C0, 10/11/2026)
  - **Contexto:** num `npm ci` limpo, `npm run build` falha no backend (`Module '"@prisma/client"' has no exported member 'PrismaClient'`) até alguém rodar `prisma:generate`. Hoje está documentado no `COMO-TESTAR` (passo 2b).
  - **Problema:** quem esquece o passo vê um erro confuso.
  - **Alternativas:**
    1. **Manter o passo manual.** Vantagem: nada a fazer. Desvantagem: armadilha para quem chega.
    2. **`postinstall` no backend.** Código: uma linha no `package.json` do backend. Vantagem: automático, também no CI e na hospedagem. Desvantagem: toda instalação roda o gerador (alguns segundos).
  - **Recomendação:** 2. Evita o erro no CI e no deploy, que ainda vão ser montados.

- [ ] [DECIDIR] Validar decisão já implementada: Jest × `@nestjs/config` (só ESM) — (origem: diário, problema 2, C0, 10/11/2026)
  - **Contexto:** os testes de integração não carregavam a aplicação (`Must use import to load ES Module: .../@nestjs/config/dist/index.js`).
  - **Problema:** a solução aplicada (o `test:e2e` roda com `NODE_OPTIONS=--experimental-vm-modules` e `--runInBand`) usa uma opção experimental do Node.
  - **Alternativas:**
    1. **Manter.** Vantagem: sem dependência nova; funciona. Desvantagem: depende de flag experimental.
    2. **Trocar o `@nestjs/config` pela v4** (CommonJS, compatível com Nest 11). Código: versão e testes (cerca de 1 h). Vantagem: sem flag. Desvantagem: versão mais antiga.
  - **Recomendação:** 1, revendo se a flag der problema no CI.

- [ ] [DECIDIR] Validar decisão já implementada (lacuna A da C4): `createdAt` no `ListGoals` — (origem: diário, problema 8A, C4, 10/11/2026)
  - **Contexto:** o `PlanCalculator` desempata a ordem dos objetivos pela data de criação.
  - **Problema:** nenhuma saída do goals expunha `createdAt`; o orquestrador acrescentou o campo ao `ListGoals` (e ao `GET /goals`).
  - **Alternativas:** 1. **manter** (campo a mais na saída, já no contrato); 2. **desempatar por outro critério** que já exista (ex.: id), removendo o campo (1 h; o desempate deixa de ter sentido para o usuário).
  - **Recomendação:** 1. Desempate por criação é o comportamento esperado.

- [ ] [DECIDIR] Validar decisão já implementada (lacuna B da C4): caso de uso `GetNextBlocks` — (origem: diário, problema 8B, C4, 10/11/2026)
  - **Contexto:** o `GET /goals/:goalId` mostra o próximo bloco de cada etapa (`nextBlock`), mas não havia caso de uso para isso.
  - **Problema:** o orquestrador criou o `GetNextBlocks` no scheduling: por etapa, o bloco `planned` de menor início a partir de agora, até 366 dias.
  - **Alternativas:** 1. **manter**; 2. **calcular o próximo bloco a partir do plano já gerado**, sem caso de uso novo (o orquestrador passaria a calcular, contra a 5.9).
  - **Recomendação:** 1. Respeita a regra de que orquestrador não calcula.

- [ ] [DECIDIR] Validar decisão já implementada (lacuna C da C4): conferir a posse antes de gravar, `GetBlock` novo e `blockId` opcional — (origem: diário, problema 8C, C4, 10/11/2026)
  - **Contexto:** o `POST /activation/sessions` gravava antes de conferir a posse do bloco. Agora confere tudo antes (`GetGoal` + `GetBlock`, caso de uso novo), e o `blockId` é opcional.
  - **Problema:** (a) são mudanças de domínio feitas sem você; (b) se o `GeneratePlan` falhar depois das escritas, elas ficam (hoje isso não acontece pela API).
  - **Alternativas:**
    1. **Manter como está.** Vantagem: o 404 nunca deixa gravação parcial. Desvantagem: o caso (b) fica em aberto.
    2. **Manter e envolver as escritas numa transação.** Código: uma porta de "unidade de trabalho" no domínio e a implementação com transação do Prisma (meio dia). Vantagem: atomicidade total. Desvantagem: estrutura nova para um caso que hoje não acontece.
  - **Recomendação:** 1 no MVP; 2 se aparecer falha real do `GeneratePlan`.

- [ ] [DECIDIR] Validar decisão já implementada (lacuna D da C4): objetivo `done` com `slackDays: null` — (origem: diário, problema 8D, C4, 10/11/2026)
  - **Contexto:** a folga (`slackDays`) vem do plano; um objetivo concluído não entra no plano.
  - **Problema:** o orquestrador decidiu devolver `slackDays: null` para objetivo `done`.
  - **Alternativas:** 1. **manter `null`** (as telas não mostram folga de objetivo concluído); 2. **devolver a folga do momento da conclusão** (exige guardar o valor: campo novo no banco).
  - **Recomendação:** 1. Não há tela que mostre folga de objetivo concluído.

- [ ] [DECIDIR] Validar decisão já implementada: bloco do próprio usuário mas de outra etapa → 404 — (origem: diário, "decisões que tomei sem você", C4, 10/11/2026)
  - **Contexto:** no `POST /activation/sessions`, o `blockId` informado pode ser de outra etapa do mesmo usuário. Antes da correção, o bloco errado era marcado como `done`.
  - **Problema:** escolher a resposta HTTP.
  - **Alternativas:** 1. **404 antes de gravar** (atual: "esse bloco não existe para essa etapa"); 2. **422** (regra de negócio violada); 3. **ignorar o `blockId` e registrar sem bloco** (o usuário não vê erro, mas o bloco certo fica sem resultado).
  - **Recomendação:** 1. Já implementado e testado, e trata o par etapa–bloco como o recurso procurado.

- [ ] [DECIDIR] Validar decisão já implementada: ordem da Etapa C — (origem: diário, "decisões que tomei sem você" e "Ajuste de sequência da Etapa C", 10/11/2026)
  - **Contexto:** as rotas que dependem de orquestrador (PUT com `plan`, plano do dia e da semana, `POST`/`GET /goals`, rampa, sessões) foram para a C4; C2 e C3 entregaram só persistência e rotas simples.
  - **Problema:** a ordem diferiu do plano aprovado (`docs/5-plano-execucao.md`).
  - **Alternativas:** 1. **validar** (já executado; nenhum efeito no código final); 2. **registrar que, nas próximas etapas, mudança de ordem espera aprovação**.
  - **Recomendação:** 1, e adotar 2 como prática daqui para frente (já coberto pela regra do processo, seção 5).

- [ ] [DECIDIR] Validar ajustes de consistência do orquestrador (contrato × modelagem) — (origem: diário, "Ajustes de consistência feitos pelo orquestrador", 10/11/2026)
  - **Contexto:** (a) o `GetDayPlan` seguiu o contrato (`{ date, blocks, usedMinutes, limitMinutes }`) e a modelagem foi corrigida; (b) semana que não começa na segunda responde 422 (o contrato dizia 400); dia e semana sem disponibilidade respondem 404 (P12), que o contrato não listava.
  - **Problema:** contrato e modelagem foram alterados sem você.
  - **Alternativas:** 1. **validar**; 2. **voltar algum dos códigos** (ex.: 400 para a semana fora da segunda; mexe no domínio e nos testes, 1 h).
  - **Recomendação:** 1. Segue a P19 (formato → 400, regra → 422).

- [ ] [DECIDIR] Validar decisões de detalhe da B3 (activation) — (origem: diário, "Pendências da B3", 10/11/2026)
  - **Contexto:** a B3 decidiu, sem documento que definisse: opções do micro-passo (`durationLabel '1 min'`, `description 'Micro-passo'`, `icon 'footprints'`, ids `micro-<n>`, do protótipo); desafio sem `durationSeconds` (contrato §5 corrigido para opcional); ids das opções `<kind>-<n>`; `partialPct` inteiro de 1 a 99 com `partial` e `null` fora dele; `goalId`, `stepId` e `blockId` validados como UUID; `endedAt < startedAt` gera `focusSession.endedAt.min.date`; o `BuildRamp` não valida `availableTime` (P15).
  - **Problema:** escolhas aceitas pelo revisor sem você.
  - **Alternativas:** 1. **aceitar todas**; 2. **reabrir as que quiser** como [EXECUTAR].
  - **Recomendação:** 1. Todas seguem o protótipo ou as decisões P14/P15.

- [ ] [EXECUTAR] Testes da B3 com mais de um resultado esperado e nomes de arquivos de teste — (origem: diário, "Pendências da B3", 10/11/2026)
  - **O que fazer:** dividir os testes do `modules/activation` que têm mais de um resultado esperado (a regra `testes-e-cobertura.md` pede um por teste) e renomear os dois arquivos de teste que não acompanharam o sufixo `.provider`.
  - **Critério de pronto:** um `expect` de resultado por teste no activation, nomes de teste espelhando `src/`, cobertura 100% e verificação completa verde.

- [ ] [DECIDIR] Regras de validação locais do goals candidatas ao shared (`MultipleOfRule`) — (origem: diário, tabela de tarefas, B1, 10/11/2026)
  - **Contexto:** a B1 criou regras de validação dentro de `modules/goals` (ex.: `MultipleOfRule`), que poderiam servir a outros módulos.
  - **Problema:** regra genérica fora do `shared` tende a ser duplicada.
  - **Alternativas:** 1. **mover para `packages/shared`** com a skill `shared-validation-rule` (1–2 h); 2. **deixar no goals** até outro módulo precisar.
  - **Recomendação:** 2. Mover só quando houver um segundo uso.

- [ ] [DECIDIR] Validar campos extras nas saídas do goals e do plano — (origem: diário, tabela de tarefas, B1 e C4, 10/11/2026)
  - **Contexto:** as saídas trazem campos além do contrato mínimo: `kind`, `source`, `status`, `aiEstimatedMinutes`, `microSteps` (B1); `scheduledMinutes` e o `StepView` completo (C4). Também: o `POST /goals` confere a disponibilidade antes de gravar, e o `GET /goals` sem objetivo ativo devolve `[]`. Tudo documentado no OpenAPI.
  - **Problema:** decisões dos autores aceitas pelo orquestrador.
  - **Alternativas:** 1. **aceitar**; 2. **enxugar as saídas ao contrato mínimo** (mexe em DTOs e testes, 1–2 h, sem ganho para as telas).
  - **Recomendação:** 1.

- [ ] [DECIDIR] Testes do backend recomendados pelo revisor da C2 e não feitos — (origem: diário, tabela de tarefas, C2, 10/11/2026)
  - **Contexto:** o revisor recomendou três testes de integração: desempate pelo fim; `deletedAt` nas leituras; reescrita do `userId` no `replaceFutureAutoBlocks` (ligado à pergunta 7).
  - **Problema:** comportamentos sem teste podem quebrar sem ninguém notar.
  - **Alternativas:** 1. **fazer agora** (cerca de 1 h); 2. **deixar para depois do MVP**.
  - **Recomendação:** 1. É barato e protege o motor, que é o mínimo obrigatório.

- [ ] [DECIDIR] Validar exceções à ordem do TDD registradas nas Etapas B e C — (origem: diário, tabela de tarefas, B2, B5 e C1, 10/11/2026)
  - **Contexto:** (a) B2: testes de borda (zoned-time, união de janelas, bordas do motor) escritos junto com o código, fora dos cenários aprovados; (b) B5: testes de widget escritos depois das telas, como a brief pedia; (c) C1: 2 testes do adaptador escritos depois, com prova por mutação.
  - **Problema:** desvios da ordem teste → código, aceitos pelos revisores.
  - **Alternativas:** 1. **aceitar e registrar os cenários de borda da B2 no `docs/3-modelagem-dominio.md`** (cerca de 1 h de documentação); 2. **aceitar sem mudar docs**; 3. **reescrever os testes em ordem TDD** (sem ganho prático: os testes já existem e foram validados por mutação).
  - **Recomendação:** 1. Os testes ficam, e a modelagem passa a ser a fonte dos cenários, como a regra pede.

### Rodada de ajustes visuais (11/11/2026)

- [ ] [DECIDIR] Provedor de LLM do assistente de novo objetivo — (origem: M1, `docs/2-decisoes-mvp.md` 4f e "Pendências para sexta" item 4, 11/11/2026) — afeta Mobile (chat M13–M15) e Frontend (W27–W31)
  - **Contexto:** o chat do novo objetivo precisa de uma IA que transforme o texto do usuário em título, prazo e etapas (`parseGoal` + `suggestSteps`, 4f). A 5.8 manda escolher entre os parceiros do hackathon (o prêmio é em créditos deles); a lista ainda está pendente. Hoje o mobile usa uma resposta de exemplo fixa ("Trabalho de Algoritmos", qualquer que seja o texto).
  - **Problema:** sem provedor não há endpoint, e o chat devolve sempre o mesmo objetivo.
  - **Alternativas:**
    1. **LLM de um parceiro do hackathon**, escolhido quando a lista sair. Código: `GoalAssistantProvider` no `goals` com fake, implementação no backend (skill `backend-provider-implementation`), chave no `.env` (1 dia). Telas: nenhuma mudança. Vantagem: segue a 5.8 e pode render créditos. Desvantagem: depende da lista; o parceiro pode não ter saída JSON estruturada nem leitura de PDF.
    2. **Provedor fora da lista** (ex.: Anthropic, OpenAI ou Gemini). Código e prazo iguais. Vantagem: saída estruturada madura; leitura de PDF (e áudio em alguns) serviria ao anexo/áudio da M13/M14. Desvantagem: custo próprio; não conta para a 5.8.
    3. **Manter a fonte de exemplo até depois da demo.** Vantagem: zero risco. Desvantagem: a demo mostra uma IA falsa.
  - **Recomendação:** 1 assim que a lista sair, escolhendo um parceiro com saída JSON estruturada; 2 se nenhum parceiro tiver LLM. Em qualquer caso, a falha da IA continua abrindo o formulário manual (4f).
  - **Atualização (proposta de IA, 11/11/2026):** decisão marcada para sexta (13/11). A `docs/7-proposta-ia.md` §f compara as opções gratuitas para testar antes (Ollama, Groq, Gemini, GitHub Models, OpenRouter, com os limites "a confirmar") e propõe o script `ai:eval` (tarefa 10) para levar números de qualidade e latência à reunião. Qualquer fornecedor no formato OpenAI entra só pelo `.env`; outro formato é um adaptador novo. Ver a subseção "Proposta de IA (11/11/2026)" abaixo.

  - **Atualização (12/11/2026, IA6):** continua para a reunião de sexta. Os números de qualidade e latência estão em `docs/8-avaliacao-ia.md`.
- [x] [EXECUTAR] Endpoint do assistente de novo objetivo — (origem: M1, `apps/mobile/lib/features/goals/data/goal_assistant_repository.dart`, 11/11/2026) — depende do [DECIDIR] "Provedor de LLM" para a implementação real; dá para começar com o provider fake
  - **O que fazer:**
    - Domínio: `GoalAssistantProvider` (`modules/goals/src/goal/provider/`) com `extractGoal(text)` e `suggestSteps(goal)`; um caso de uso que encadeia os dois **sem gravar** (o usuário confere e depois chama `POST /goals`); fake em `test/mock`.
    - Rota sugerida: `POST /goals/assistant`, com JWT; nome final no contrato (`docs/4-contrato-api.md`) e no `openapi.json`.
    - **Entrada:** `{ "text": string }` (não vazio depois de `trim`).
    - **Saída 200** (o que a interface do mobile, `GoalSuggestion`, espera): `{ "title": "Trabalho de Algoritmos", "deadline": "2026-11-24" | null, "steps": [ { "title": "…", "estimatedMinutes": 180 } ] }`. Títulos de 1 a 120 caracteres (P2); `estimatedMinutes` múltiplo de 15, mínimo 15 (P5): o backend arredonda o que a IA sugerir; `microSteps` opcional (P6/4f).
    - **Erros:** 400 formato; 401; 422 texto vazio; 503 quando o provedor falhar (o app abre a M15 vazia, 4f).
    - Mobile: `HttpGoalAssistantRepository` em `apps/mobile/lib/features/goals/data/` e a troca em `AppDependencies.http` (o comentário "EXAMPLE" marca o lugar).
  - **Critério de pronto:** testes de domínio com o fake (100%); integração (feliz, 400, 401, 422, 503 com provider que falha); contrato e OpenAPI atualizados; teste do repositório HTTP do mobile.
  - **Atualização (proposta de IA, 11/11/2026):** a `docs/7-proposta-ia.md` detalha e ajusta este item, **pendente do [DECIDIR] "Aprovar a proposta de IA"**: rota `POST /goals/assistant/draft`; métodos com os nomes da 4f (`parseGoal`, não `extractGoal`); a saída ganha `category`, `requirements`, `missingFields`, `engine` e, por etapa, `microSteps` e `aiEstimatedMinutes`; o `POST /goals` passa a aceitar `source` e `aiEstimatedMinutes`; motor de regras (`AI_PROVIDER=rules`) para testar o fluxo antes do fornecedor. O trabalho foi quebrado nas tarefas 1–11 do §g.
  - **Fechado** em `c02561b` (`POST /goals/assistant/draft`, tarefa 5) e `f88bee8` (seleção por `AI_PROVIDER`, tarefa 10).

  - **Atualização (12/11/2026):** proposta aprovada (IA1). Este item é executado pelas tarefas 1–11 do `docs/7` §g, com o contrato de `docs/4` §3 (`POST /goals/assistant/draft`).
- [ ] [DECIDIR] Tipo do prazo e nome curto do objetivo — (origem: W1, W2, M2 e revisores, 11/11/2026) — afeta Frontend (W17–W19, W21, prévia do e-mail na W26) e Mobile (M21)
  - **Contexto:** os protótipos mostram o tipo da entrega ("Entrega", "Prova", "Publicar") e um nome curto do objetivo ("Eng. Software") além do completo ("Trabalho de Engenharia de Software"). O contrato (`GET /goals`) só tem `title`. Os apps usam "Entrega" fixo e o título inteiro (no web, títulos longos quebram por sílaba na coluna estreita ou cortam com "…").
  - **Alternativas:**
    1. **Manter.** Código: nada. Desvantagem: "Entrega" para uma prova; nomes longos cortados.
    2. **Campos `deadlineKind` e `shortTitle`** no domínio, contrato, banco e nas telas de criação (web e mobile). Prazo: meio dia a um dia. Vantagem: fidelidade. Desvantagem: dois campos novos no formulário.
    3. **Nome curto derivado no front** (truncagem). Código: pouco. Desvantagem: corta palavras; não resolve o tipo.
  - **Recomendação:** 1 no MVP; 2 depois, se o design confirmar os dois nomes.

- [ ] [DECIDIR] Próxima etapa no `GET /goals` — (origem: revisor da W1, `apps/frontend/src/modules/goals/pages/goal-list.page.tsx:30`, 11/11/2026)
  - **Contexto:** a lista de objetivos (W21) mostra a próxima etapa de cada objetivo; o `GET /goals` não a traz, então o web faz um `GET /goals/:id` por objetivo.
  - **Alternativas:** 1. **manter** (poucos objetivos no MVP); 2. **acrescentar `nextStep{title, nextBlock}` ao `GET /goals`** (orquestrador `goals-view`, contrato e testes; 2–3 h).
  - **Recomendação:** 1 no MVP.

- [ ] [DECIDIR] Endpoints de preferências do usuário (tema, e-mail diário) e envio do e-mail — (origem: W1, W26, 11/11/2026)
  - **Contexto:** a W26 usa um `ExampleSettingsRepository` em memória também no modo http (tema e e-mail diário não existem no contrato).
  - **Alternativas:** 1. **`GET`/`PATCH /me/preferences` no auth** (a tela só troca a implementação do repositório; meio dia, mais o envio do e-mail com provider); 2. **depois do MVP**.
  - **Recomendação:** 2. Não está no mínimo obrigatório.

- [ ] [DECIDIR] Endpoint de gamificação para o Jardim (W25) e a barra gamificada — (origem: W1, 11/11/2026)
  - **Contexto:** o Jardim mostra nível, XP, dias regados, histórico, conquistas e loja com valores fixos (P18).
  - **Alternativas:** 1. **manter fixo até o módulo `gamification`** (P18); 2. **criar o módulo agora** (dias de trabalho, fora do MVP).
  - **Recomendação:** 1.

- [x] [DECIDIR] Compromissos fixos (Aula/Estágio) fora do contrato[DECIDIR] Compromissos fixos (Aula/Estágio) fora do contrato — (origem: revisor da W1, 11/11/2026) — fechado pelas decisões MC1–MC14 (20/11/2026); implementado na rodada `feat/compromissos-tarefas-unicas`.
  - **Contexto:** o domínio já tem `Commitment` (P8, implementação vazia `EmptyCommitmentRepository`), mas o contrato não expõe compromissos. A grade da W26 e o calendário ficam sem a hachura "Aula/Estágio" e sem a legenda "Aula e estágio" do protótipo.
  - **Alternativas:** 1. **manter (P8)**; 2. **expor e persistir compromissos** (CRUD, prisma, contrato e telas; 1–2 dias).
  - **Recomendação:** 1 no MVP, como decidido na P8.

- [ ] [DECIDIR] Usuário de teste deixado no Postgres local — (origem: W1, investigação do bug do novo objetivo, 11/11/2026)
  - **Contexto:** para provar que o bug não era do backend, o subagente cadastrou `w1.bug.1794402356@teste.local` no banco **local**, com disponibilidade e cerca de 6 objetivos. O demo e o `db:reset-demo` não foram tocados.
  - **Alternativas:** 1. **apagar o usuário** (um `DELETE` no banco local); 2. **manter** (não afeta nada).
  - **Recomendação:** 1, quando você quiser; não apaguei porque é o seu banco.
  - **Atualização (12/11/2026):** o ponta a ponta novo do web (`novo-objetivo-ia.spec.ts`, tarefa 11) cria a cada execução um usuário `e2e.ia.<carimbo>@bora.app` com um objetivo, que não é apagado (os testes de integração do backend já faziam o mesmo). Decidir junto: limpar no `global-setup` ou aceitar no banco local.

### Proposta de IA (11/11/2026)

Origem comum: `docs/7-proposta-ia.md` (rodada de análise, sem implementação). **Decisões de 12/11/2026 em `docs/2-decisoes-mvp.md` (IA1–IA7).** Os itens marcados "sexta" vão para a reunião do time de 13/11; os outros são seus. O fornecedor e o modelo estão no [DECIDIR] "Provedor de LLM do assistente de novo objetivo", acima.

- [x] [EXECUTAR] Aprovar a proposta de IA (arquitetura, contrato e plano) — (origem: `docs/7-proposta-ia.md` §c, §d, §e.2 e §g, 11/11/2026; decidido em 12/11/2026, IA1) — afeta Frontend e Mobile
  - **Decisão (IA1):** alternativa 1, aprovada com todas as divergências do §e.2: `rules` em vez de "fake"; 15 s de orçamento total; normalizador no domínio; `category`; `today` e `timezone` na entrada; `POST /goals` com `source` e `aiEstimatedMinutes`; máximo de 240 min por etapa no rascunho. Prompts em `.prompt.ts` (IA5). Tarefas 0–11 do §g; a 12 fica fora (IA7). Contrato em `docs/3` §2.6–2.7 e `docs/4` §3.
  - **Pronto quando:** as tarefas 0–11 estiverem integradas na `developer` com a verificação completa verde.
  - **Andamento (12/11/2026):** tarefas 0–10 integradas na developer (`9006d3c`, `f4041e7`, `c02561b`, `f88bee8`, `4748903`, `80d36ba`), cada uma com a verificação completa verde e revisor. Tarefa 11 (ponta a ponta pelo chat, `395a531`) integrada com a verificação verde e revisor. A tarefa 12 ficou fora (IA7). **Fechado.**
  - **Contexto:** a 4f define a IA do novo objetivo (`parseGoal` + `suggestSteps`, confirmação do usuário, formulário manual se falhar), mas não a arquitetura, o contrato nem como testar sem fornecedor. Você pediu um substituto da IA até sexta e a troca para a IA real só por configuração.
  - **Problema:** sem aprovação, nenhuma das tarefas do §g pode começar (a regra do processo proíbe endpoint ou campo fora do plano aprovado). A proposta muda o contrato aprovado (`POST /goals` ganha `source` e `aiEstimatedMinutes`) e a modelagem (porta, `DraftGoal`, `GoalDraftNormalizer`).
  - **Alternativas:**
    1. **Aprovar como está.** Código: as tarefas 0–11 do §g (≈ 3–4 dias de uma pessoa; o caminho mínimo até o fluxo testável com o motor de regras é 0 → 1/2/4 → 5 → 7, ≈ 1,5 dia). Telas: mobile nenhuma; web W27/W29/W30 preenchida. Vantagem: fluxo de ponta a ponta testável antes de sexta e troca de fornecedor só pelo `.env`. Desvantagem: mexe num contrato aprovado.
    2. **Aprovar com ajustes** (ex.: `AI_PROVIDER=fake` em vez de `rules`; prompts em `.ts` em vez de `.md`; sem o máximo de 240 min por etapa; sem o campo `engine`). Código e prazo iguais. Vantagem: atende preferências do time. Desvantagem: cada ajuste precisa ser escrito no item.
    3. **Adiar até a escolha do fornecedor** e implementar direto para ele. Código: o mesmo, sem o motor de regras. Vantagem: menos código. Desvantagem: nada testável até sexta; a demo fica sem reserva offline; testes de ponta a ponta dependem de rede e de cota.
  - **Recomendação:** 1. Os pontos que mais mudam a sua proposta original estão no §e.2 (renomear "fake" para "rules", validação em duas camadas, um endpoint só, orçamento total de 15 s, `source`/`aiEstimatedMinutes` no `POST /goals`, web precisa de telas).

- [ ] [DECIDIR] Chave, custo e limites de uso da IA (sexta) — (origem: `docs/7-proposta-ia.md` §c.6, §c.8 e §h, 11/11/2026)
  - **Atualização (12/11/2026, IA6):** continua para a reunião de sexta. Até lá, o limite de uso **não** é implementado.
  - **Contexto:** a chave do fornecedor fica só no `.env` do backend e no segredo da hospedagem (que também é pendência de sexta). O repositório é público até a apresentação (4j), e a demo pode ser aberta por qualquer pessoa logada.
  - **Problema:** sem dono da conta, teto de gasto e limite por usuário, uma demo pública pode esgotar a cota gratuita (ou gerar custo) no meio da apresentação.
  - **Alternativas:**
    1. **Conta do time num plano gratuito + limite em memória por usuário** (ex.: 20 rascunhos por hora → 429), feito à mão, sem dependência. Código: 2–3 h com testes. Telas: o 429 cai no formulário manual (mesmo caminho do 503). Vantagem: custo zero e sem dependência. Desvantagem: o limite zera quando o backend reinicia.
    2. **Igual à 1, com `@nestjs/throttler`.** Código: 1–2 h. Vantagem: pronto e configurável. Desvantagem: dependência nova (precisa de aprovação).
    3. **Conta paga com teto de gasto no painel do fornecedor, sem limite no app.** Código: nada. Vantagem: simples. Desvantagem: depende de cartão e do teto do fornecedor funcionar.
  - **Recomendação:** 1, com a conta no nome de quem for apresentar e a chave guardada só no segredo da hospedagem. Definir também quem pode ver a chave.

- [ ] [DECIDIR] Privacidade dos textos enviados à IA (sexta) — (origem: `docs/7-proposta-ia.md` §c.6 e §f, 11/11/2026)
  - **Atualização (12/11/2026, IA6):** continua para a reunião de sexta. Observação do revisor da tarefa 9: com `AI_LOG_CONTENT=false`, o corpo de erro HTTP do fornecedor ainda vai ao log (cortado em 200 caracteres e sem a chave); alguns fornecedores repetem trechos do pedido em erros de moderação. Decidir junto se o log de erro guarda só o código.
  - **Contexto:** a proposta manda ao fornecedor só o texto do objetivo e a data de hoje (nunca nome, e-mail, id ou fuso). Alguns planos gratuitos podem usar o conteúdo para treino ou revisão humana: os termos do Gemini gratuito dizem isso (conferir a versão atual); para Groq, GitHub Models e OpenRouter, "a confirmar".
  - **Problema:** um estudante pode colar o enunciado com o próprio nome, matrícula ou dados de terceiros. O app não avisa que o texto vai para um terceiro.
  - **Alternativas:**
    1. **Só fornecedor que não treina com os dados** (confirmado nos termos) e nada de aviso. Código: nada. Vantagem: sem atrito. Desvantagem: depende de ler e guardar os termos.
    2. **Igual à 1, mais uma linha de aviso** no chat ("O texto é analisado por uma IA externa"). Código: 30 min por app. Telas: texto que o design não tem. Vantagem: transparência. Desvantagem: texto sem design.
    3. **Ollama ou outro modelo próprio na hospedagem.** Código: só `.env`. Vantagem: nada sai do nosso servidor. Desvantagem: hospedagem com GPU ou CPU forte; mais lento.
  - **Recomendação:** 1 para a demo, usando só textos inventados enquanto o fornecedor não estiver confirmado; 2 quando houver usuários reais.

- [ ] [DECIDIR] O que fazer quando a IA falha: motor de regras, formulário manual ou os dois (sexta) — (origem: `docs/7-proposta-ia.md` §c.5, 11/11/2026) — cruza com o Mobile "Aviso quando a IA falha no chat"
  - **Atualização (12/11/2026, IA6):** continua para a reunião de sexta. Até lá, o padrão provisório do `.env.example` é `AI_FALLBACK=rules` (alternativa 1); `AI_FALLBACK=none` dá o comportamento da 4f (alternativa 2) sem mudar código.
  - **Contexto:** a 4f diz "se a IA falhar, abre o formulário manual". A proposta acrescenta a opção de cair no motor de regras (instantâneo, sem rede), controlada por `AI_FALLBACK=rules|none`. A resposta traz `engine: 'llm' | 'rules'`.
  - **Problema:** cair nas regras dá ao usuário um rascunho de qualidade menor sem ele saber; não cair deixa a demo à mercê da rede e da cota.
  - **Alternativas:**
    1. **Regras como reserva, sem aviso** (`AI_FALLBACK=rules`). Código: incluído na tarefa 10. Telas: nenhuma. Vantagem: o fluxo nunca quebra na demo. Desvantagem: muda a 4f; rascunho genérico apresentado como da IA.
    2. **Formulário manual, como na 4f** (`AI_FALLBACK=none` → 503 → M15/W30 vazia). Código: incluído. Vantagem: honesto e já previsto. Desvantagem: na falha, o usuário monta tudo à mão.
    3. **Regras como reserva, com aviso** quando `engine = 'rules'` (balão do Broto: "Montei um rascunho básico, confere?"). Código: 1 h por app. Telas: texto sem design. Vantagem: nunca quebra e é transparente. Desvantagem: texto e estado sem design.
  - **Recomendação:** 3 se o time aprovar o texto; senão 1 na apresentação e 2 depois dela. Em qualquer caso, a decisão vai para a `docs/2-decisoes-mvp.md` como ajuste da 4f.

- [ ] [DECIDIR] Leitura de link e anexo (UC03): Firecrawl no MVP? (sexta) — (origem: `docs/7-proposta-ia.md` §a.1 A5–A7, 11/11/2026) — cruza com o Mobile "Anexo e áudio do chat (M13/M14) só visuais" e com o Frontend (aba "Colar link", W28)
  - **Contexto:** o UC03 está no MVP dos casos de uso, mas fora do mínimo obrigatório (4a). O web tem a aba "Colar link" (W28); o mobile tem o clipe e o microfone (M13/M14), hoje só visuais. A leitura de páginas seria pelo Firecrawl (citado no UC03 e no README) atrás de um `PageReaderProvider`.
  - **Problema:** sem decisão, a aba e o clipe continuam sem efeito; com decisão, entra uma porta nova, um fornecedor novo e mais uma chave.
  - **Alternativas:**
    1. **Só link, com Firecrawl, na fatia 3** (depois do texto funcionar). Código: porta + adaptador + `url?` no `POST /goals/assistant/draft` (1 dia). Telas: a W28 passa a funcionar; o mobile segue só visual. Vantagem: usa um parceiro com caso real (5.8, se o Firecrawl for parceiro: a confirmar). Desvantagem: páginas com login (Moodle) não são lidas; o usuário teria de colar o texto.
    2. **Link e PDF** (PDF por extração de texto ou LLM que lê PDF). Código: 2–3 dias, com upload no backend e pacotes novos nos apps. Vantagem: o caso do enunciado em PDF (M14). Desvantagem: prazo; depende do fornecedor.
    3. **Nada no MVP;** só texto. Vantagem: foco no mínimo. Desvantagem: a W28 e o clipe ficam sem efeito na demo.
  - **Recomendação:** 3 até o texto estar no ar; depois 1, se o Firecrawl estiver entre os parceiros. Áudio fica para depois do hackathon.

- [x] [EXECUTAR] Perguntas de esclarecimento no chat (prazo faltando) — (origem: `docs/7-proposta-ia.md` §b, 11/11/2026; decidido em 12/11/2026, IA2) — afeta Mobile (M13–M15) e Frontend (W27–W30)
  - **Decisão (IA2):** alternativa 1. Um turno, sem estado, **sem perguntas**. `missingFields` é informativo; a M15/W30 mostra o campo vazio.
  - **Pronto quando:** o rascunho sem prazo chega às telas com o prazo vazio e o objetivo pode ser salvo (tarefas 5, 7 e 8).
  - **Fechado** em `c02561b`, `4748903` e `7f74653` (teste de integração "texto sem data" e testes de tela dos dois apps).
  - **Contexto:** você pediu a conversa do chat com perguntas de esclarecimento. Nenhum design mostra a IA perguntando. O prazo é opcional (P3), então a falta dele não impede salvar.
  - **Problema:** escolher entre um turno só (o que falta aparece vazio na tela de etapas) e uma conversa de verdade, e onde guardar o histórico.
  - **Alternativas:**
    1. **Um turno, sem estado** (`missingFields` na resposta; a M15/W30 mostra o prazo vazio). Código: incluído no plano. Telas: nenhuma nova. Vantagem: nada sem design; funciona igual com regras e LLM. Desvantagem: o Broto não pergunta.
    2. **Uma pergunta, sem estado** (`type: 'question'`; o app reenvia rascunho + resposta). Código: 1 dia (backend, os dois apps e testes). Telas: balão de pergunta e resposta curta, sem design. Vantagem: conversa de verdade sem tabela; o motor de regras responde de forma determinística. Desvantagem: estados sem design.
    3. **Sessão no backend** (tabela de conversas). Código: 2 dias (migration, posse, expiração, endpoints). Vantagem: histórico guardado. Desvantagem: o mais caro, sem ganho para a demo.
  - **Recomendação:** 1 no MVP; 2 depois que o design do balão existir. A 3 não compensa.

- [x] [EXECUTAR] Ollama local sem modelo instalado — (origem: rodada de execução da IA, 12/11/2026) — **decidido e feito em 16/11/2026 (IA8):** você autorizou instalar (alternativa 1).
  - **Fechado com:** Ollama 0.40.16 como serviço do Homebrew (`brew services start ollama`, sobe a cada login) com `OLLAMA_KEEP_ALIVE=24h`; `ollama pull qwen2.5:7b` (4,7 GB, a regra para 48 GB de RAM) e `ollama pull qwen2.5:3b` (1,9 GB); `ollama list` mostra os dois. O `POST /goals/assistant/draft` respondeu `engine: "llm"` com `outcome=ok` no log, e o `ai:eval` mediu os dois modelos (`docs/8-avaliacao-ia.md`, 16/11). O seu `apps/backend/.env` aponta para o `qwen2.5:3b` (provisório; ver "Modelo local do Ollama" abaixo). Comandos em `docs/backend/COMO-TESTAR.md` (passo 6a e seção 8b).
  - **Causa confirmada de 12/11:** só a falta de modelo. O 404 vinha do próprio Ollama em `/v1/chat/completions` (`model 'llama3.2' not found`), então endereço, porta, rota e formato do pedido estavam certos. Em 16/11 o servidor estava parado (o de 12/11 era um `ollama serve` aberto à mão); agora é serviço.
  - **Contexto:** você pediu o teste manual do adaptador e a linha (b) do `ai:eval` com o Ollama do seu Mac. Ele responde em `http://localhost:11434` (`curl http://localhost:11434/api/tags` → `{"models":[]}`), mas `ollama list` está vazio. A instrução foi não baixar nem instalar nada.
  - **Problema:** sem modelo, toda chamada do adaptador ao Ollama falha; o rascunho cai no motor de regras (`engine: 'rules'`) e o `ai:eval` não mede a qualidade de um LLM local.
  - **Alternativas:**
    1. **Baixar um modelo pequeno** (`ollama pull <modelo>`, 2–5 GB; ex.: um modelo de 3–4B de parâmetros com saída JSON; nome exato a conferir no catálogo do Ollama) e rodar de novo o teste manual e o `ai:eval` (comandos em `docs/backend/COMO-TESTAR.md`). Vantagem: números de um LLM antes de sexta, sem mandar nada para fora. Desvantagem: download e espaço em disco; modelo pequeno erra mais.
    2. **Usar o Groq** (chave no `apps/backend/.env`; hoje não há). Vantagem: modelo grande e rápido. Desvantagem: o texto sai da máquina; conta e chave.
    3. **Levar só o motor de regras para sexta.** Vantagem: nada a fazer. Desvantagem: a reunião decide o fornecedor sem número de LLM.
  - **Recomendação:** 1 (e 2 se alguém do time já tiver a chave), antes da reunião.
  - **Resultado da rodada (12/11/2026):** o teste manual e o `ai:eval` com o Ollama responderam HTTP 404 (`model ... not found`) em menos de 0,1 s e caíram no motor de regras (`engine: 'rules'`); detalhes em `docs/8-avaliacao-ia.md`. O seu `apps/backend/.env` ficou com `AI_PROVIDER=rules` e as linhas do Ollama comentadas, prontas para quando houver modelo.

- [ ] [DECIDIR] Regras de data, título e categoria do motor de regras — (origem: revisor das tarefas 4 e 9, `pt-br-date.parser.ts` e `rules-goal-assistant.provider.ts`, e `docs/8-avaliacao-ia.md`, 12/11/2026)
  - **Contexto:** o motor de regras segue a tabela da `docs/7` §a.3 ao pé da letra ("a primeira regra que casar vale"). O revisor e o `ai:eval` acharam casos comuns em que isso erra:
    - intervalos e frações viram prazo: "3-5 páginas para sexta" → 03/05/2027; "Ler 1/2 do livro até sexta" → 01/02/2027; "das 14-16h na sexta" → sem prazo;
    - dia da semana usado como ordinal: "Prova da segunda unidade" → próxima segunda; "Quinta lista de exercícios" → próxima quinta; "Hoje é dia de estudar; entrega sexta" → hoje;
    - formas que não casam: "1º de dezembro", "daqui 3 dias", "24.11", "em 2 semanas"; "fim do mês que vem" → fim **deste** mês; o ano explícito em "3 de dezembro de 2027" e "24-11-2027" é ignorado;
    - plural não conta como palavra-chave ("provas", "trabalhos", "listas", "projetos" → `generic`); "seminário" e "apresentação" não são palavras-chave;
    - o título leva a expressão de data quando ela vem sem separador ("Prova de Cálculo 1 na sexta", "Lista de exercícios de Física para amanhã") e fica curto demais com ":" cedo ("TCC").
  - **Problema:** prazo errado em silêncio é pior que prazo vazio. O usuário confere na M15/W30, mas pode não perceber.
  - **Alternativas:**
    1. **Ajustar o motor** (≈ 2–3 h com testes): regra que casa com dia/mês impossível passa para a próxima; `dd-mm` só sem unidade depois ("páginas", "h"); ordinal antes de substantivo não é dia da semana; plurais e "seminário"/"apresentação"; ano opcional em `dd de <mês> [de aaaa]` e `dd-mm-aaaa`; "fim do mês que vem"; tirar do título a expressão de data já reconhecida. Muda a tabela da §a.3.
    2. **Só o mais grave** (≈ 1 h): datas impossíveis passam para a próxima regra e ano explícito; o resto fica como está.
    3. **Manter** (o motor de regras é reserva; o LLM resolve esses casos).
  - **Recomendação:** 2 agora (evita prazo errado em silêncio) e 1 se o time decidir na sexta que o motor de regras é o padrão da demo.

- [ ] [DECIDIR] Cancelar a chamada do LLM quando o orçamento de 15 s estoura — (origem: revisores das tarefas 5 e 9, `goal-draft.runner.ts` e `openai-compatible-goal-assistant.provider.ts`, 12/11/2026)
  - **Contexto:** o orçamento total (`AI_TIMEOUT_MS`) é controlado pelo `GoalDraftRunner` (docs/3 §2.6): quando estoura, a resposta sai do motor de regras na hora. Mas a chamada HTTP em andamento não é cancelada; ela só para no tempo limite próprio do adaptador (o mesmo valor, por chamada). Um `suggestSteps` iniciado aos 14 s pode seguir até 15 s depois da resposta, gastando cota.
  - **Alternativas:**
    1. **Sinal de cancelamento por rascunho** (≈ 1 h): o runner cria um `AbortController` e o adaptador recebe o sinal na construção por pedido (fora da porta do domínio). Vantagem: nada de chamada órfã. Desvantagem: o adaptador deixa de ser um objeto único.
    2. **Tempo por chamada menor** (ex.: metade do orçamento). Vantagem: 1 linha. Desvantagem: corta respostas boas na primeira chamada.
    3. **Manter** (o usuário não espera; só a cota sofre).
  - **Recomendação:** 3 até a escolha do fornecedor; 1 se o plano gratuito escolhido tiver limite por minuto apertado.
  - **Observação com o Ollama local (16/11/2026):** com um modelo local, a chamada órfã não gasta cota, mas continua ocupando o modelo por alguns segundos depois da reserva (no log: `op=draft … ms=15003 outcome=assistant.timeout` e, depois, `op=suggestSteps … ms=15003 outcome=timeout`). No `ai:eval` do `qwen2.5:7b`, com 120 s, 3 dos 10 rascunhos ficaram abaixo de 15 s; com 15 s, nenhum passou. Uma explicação plausível, **não confirmada**, é a chamada órfã de um texto atrasar o seguinte. Pesa a favor da alternativa 1 se o Ollama local for o motor da demo.

- [x] [INVESTIGAR] O fornecedor escolhido aceita `response_format: { type: 'json_object' }` e devolve `usage`? — (origem: tarefa 9, `docs/7` §c.3 "a confirmar", 12/11/2026) — **resolvido para o Ollama em 16/11/2026:** aceita e devolve.
  - **Evidência:** `curl http://localhost:11434/v1/chat/completions` com `response_format: {"type":"json_object"}` (`qwen2.5:7b`) devolveu JSON puro e válido, sem cercas de markdown, com `finish_reason: stop` e `usage: {"prompt_tokens": 82, "completion_tokens": 46, ...}`, os campos que o adaptador lê. Nas chamadas reais do backend, o log mostra `tokens_in` e `tokens_out` preenchidos (ex.: `outcome=ok tokens_in=429 tokens_out=54`), e nenhuma resposta caiu em `invalid_json` ou `invalid_output` (as falhas foram só de tempo). Nenhuma mudança no adaptador. Detalhes em `docs/8-avaliacao-ia.md`. Para um fornecedor hospedado (IA6), repetir o mesmo `curl` quando ele for escolhido.
  - **Sintoma possível:** fornecedor que ignora `response_format` pode responder com texto em volta do JSON (`outcome=invalid_json` → reserva). Cercas de markdown (```json) já são aceitas. `tokens_in`/`tokens_out` aparecem como `-` se o fornecedor não mandar `usage`.
  - **Onde olhar:** rodar o `ai:eval` com o fornecedor escolhido e conferir os `outcome=` no log. (Texto de 12/11; em 16/11 o Ollama foi testado com modelo, ver acima. O fornecedor hospedado segue no [EXECUTAR] abaixo.)

- [ ] [EXECUTAR] Conferir `response_format` e `usage` no fornecedor hospedado quando a IA6 for decidida — (origem: fechamento do [INVESTIGAR] acima, 16/11/2026)
  - **O que fazer:** com a chave no `apps/backend/.env`, repetir contra o fornecedor escolhido o `curl` de `/chat/completions` com `response_format: {"type":"json_object"}` (exemplo em `docs/8-avaliacao-ia.md`, seção "`response_format` e `usage` no Ollama") e rodar o `ai:eval`.
  - **Pronto quando:** o conteúdo vem como JSON válido, o log mostra `tokens_in`/`tokens_out` preenchidos e nenhum `outcome=invalid_json` aparece; o resultado entra no `docs/8`.

- [ ] [DECIDIR] Modelo local do Ollama: o `qwen2.5:7b` passa de 15 s e o `qwen2.5:3b` repete etapas — (origem: rodada do Ollama local, 16/11/2026, `docs/8-avaliacao-ia.md`) — também afeta Frontend e Mobile (tempo limite de 25 s dos apps)
  - **Contexto:** com o Ollama instalado (IA8), a regra combinada foi `qwen2.5:7b` para 16 GB de RAM ou mais (o Mac tem 48 GB) e, se o rascunho com o modelo carregado passasse de 15 s, não mexer no código nem no padrão e trazer a decisão para cá. O orçamento `AI_TIMEOUT_MS` (15 s) cobre as duas chamadas (`parseGoal` + `suggestSteps`). Os dois apps desistem do rascunho aos 25 s (`HttpGoalAssistantRepository`, web e mobile) e abrem o formulário manual.
  - **Problema:** nenhum dos dois modelos atende ao mesmo tempo ao tempo e à qualidade:

    | Modelo | Rascunho carregado | Frio | Respostas do LLM no `ai:eval` (15 s) | Qualidade |
    |---|---|---|---|---|
    | `qwen2.5:7b` | 17,3–21,1 s (texto 1, 5 seguidas); 12,1–16,6 s (`ai:eval` com 120 s) | 21,9 s | 0 de 10 (com 120 s: 10 de 10) | boa: etapas específicas; um prazo errado e uma etapa em inglês |
    | `qwen2.5:3b` | 5,6–9,0 s (texto 1); 5,8–12,2 s (`ai:eval`) | 9,7 s | 7 de 10 (3 estouram o orçamento) | fraca: título vazio em 4 de 7, um prazo errado, etapas inventadas |

    O 3b, em alguns textos, entra em repetição: gera a mesma etapa de novo e de novo e não fecha o JSON (no texto "Prova de Cálculo 1 na sexta…", 3 de 4 tentativas não terminaram nem em 120 s). Exemplo real: `{"title": "Estudar respostas", "estimatedMinutes": 30, "microSteps": ["Estudar respostas da prova anterior", "Estudar respostas da prova do colega"]}` repetido até o fim. O 7b no mesmo texto fechou o JSON em 3 de 3. A velocidade de geração do 7b nas chamadas reais ficou em 20–21,5 tokens/s (18,9 num teste curto) e a do 3b em 38,6; o `suggestSteps` do 7b gera cerca de 300 tokens.
  - **Alternativas:**
    1. **`qwen2.5:3b` com 15 s (como está hoje no seu `.env`, provisório).** Código: nada. Telas: nada. Vantagem: responde em 6–12 s. Desvantagem: qualidade fraca; cerca de 3 em 10 textos esperam 15 s e caem nas regras.
    2. **`qwen2.5:7b` com `AI_TIMEOUT_MS="23000"` só no seu `.env` local.** Código: nada; o padrão do projeto continua 15 s. Telas: o "analisando…" dura 12–21 s. Vantagem: a melhor qualidade medida, sem nada sair da máquina. Desvantagem: espera longa; o limite de 23 s fica abaixo dos 25 s dos apps, com pouca folga (o maior tempo medido foi 21,9 s); acima de 25 s precisaria mudar os apps.
    3. **Prompt `suggest-steps@v2` mais curto** (3 a 6 etapas, 1 micro-passo) e, no adaptador, um teto de tokens (`max_tokens`) e uma penalidade de repetição (`frequency_penalty`). Código: prompt novo (IA5) e 2 parâmetros, com testes e um `ai:eval` novo (≈ 2 h). Telas: nenhuma nova; a W30/M15 chega com menos etapas e um micro-passo por etapa. Vantagem: o 7b pode caber nos 15 s (cerca de 180 tokens a 20 tokens/s ≈ 9 s, mais 2,5 s do `parseGoal`), e o 3b para de repetir sem fim. Desvantagem: menos detalhe por etapa; o resultado precisa ser medido, não é garantido.
    4. **Testar outro modelo local** (ex.: `llama3.2:3b`, `gemma3:4b`; download de 2–3 GB cada). Código: nada. Telas: nada. Prazo: ≈ 1 h por modelo (download e `ai:eval`). Vantagem: pode haver um modelo rápido sem repetição. Desvantagem: mais downloads e outra rodada de `ai:eval`; nenhum foi testado.
    5. **Fornecedor hospedado** (Groq ou outro, IA6). Código: só `.env`. Telas: nada. Prazo: o da decisão da IA6 (conta e chave). Vantagem: modelo grande e rápido. Desvantagem: o texto sai da máquina; chave e conta.
  - **Recomendação:** 2 para os seus testes locais agora (a melhor qualidade, só no `.env`), e 3 como próxima tarefa, porque também resolve a repetição do 3b e pode trazer o 7b para dentro dos 15 s. O fornecedor do projeto segue na IA6.

- [ ] [DECIDIR] Prazo relativo errado quando o LLM responde — (origem: `ai:eval` com o Ollama, 16/11/2026, `docs/8-avaliacao-ia.md`)
  - **Contexto:** no `parseGoal`, o LLM recebe só a data de hoje (`Hoje é 2026-11-16`) e converte sozinho "sexta", "dia 30" e "semana que vem". O motor de regras tem um analisador de datas determinístico (`pt-br-date.parser.ts`), que acertou os 8 textos com data no `ai:eval`.
  - **Problema:** o `qwen2.5:7b` leu "sexta" (hoje = segunda, 16/11) como 17/11 em vez de 20/11; o `qwen2.5:3b` leu "dia 30" como 30/12 em vez de 30/11. Prazo errado em silêncio leva o plano a encaixar as etapas cedo demais ou tarde demais; o usuário só percebe se conferir a data na M15/W30.
  - **Alternativas:**
    1. **Prazo pelo analisador de datas quando ele reconhecer uma expressão; o LLM só preenche o prazo quando o analisador não achar nada.** Código: o orquestrador do rascunho (`goal-draft.orchestrator.ts`) ou o `DraftGoal` passa a consultar o analisador; testes de unidade e de integração (≈ 1–2 h). Telas: nada. Vantagem: determinístico, já testado e já medido. Desvantagem: herda os erros do analisador (ver "Regras de data, título e categoria do motor de regras").
    2. **Prompt `parse-goal@v2` com o dia da semana de hoje e exemplos** ("hoje é segunda-feira, 2026-11-16; 'sexta' = 2026-11-20"). Código: prompt novo (IA5) e um `ai:eval` (≈ 1 h). Telas: nada. Vantagem: sem lógica nova. Desvantagem: modelos pequenos podem continuar errando; precisa medir.
    3. **Manter** (o usuário confere o prazo na tela). Vantagem: nada a fazer. Desvantagem: erro silencioso.
  - **Recomendação:** 1: o analisador já acerta mais que os dois modelos medidos e não depende do modelo escolhido.

- [ ] [DECIDIR] O `ai:eval` com `AI_PROVIDER=rules` mostra o modelo e o endereço do `.env` no cabeçalho — (origem: rodada do Ollama local, 16/11/2026, `apps/backend/scripts/ai-eval.ts`)
  - **Contexto:** com o `.env` apontando para o Ollama, `AI_PROVIDER=rules npm --workspace apps/backend run ai:eval` imprime `Motor: rules (qwen2.5:3b) em http://localhost:11434/v1`, embora o motor de regras não use nenhum dos dois.
  - **Problema:** o cabeçalho engana quem lê a tabela. Hoje o contorno documentado é zerar as duas variáveis na linha de comando (`AI_MODEL= AI_BASE_URL=`).
  - **Alternativas:**
    1. **Mostrar modelo e endereço só quando o motor não for `rules`.** Código: uma condição no script e um teste, se houver teste do script (≈ 15 min). Vantagem: cabeçalho certo. Desvantagem: nenhuma real.
    2. **Manter, com o contorno documentado.** Vantagem: nada a fazer. Desvantagem: o cabeçalho continua enganando sem o contorno.
  - **Recomendação:** 1, numa tarefa pequena.

- [ ] [EXECUTAR] Preparo das worktrees dos subagentes de backend inclui `prisma:generate` e o build dos módulos — (origem: relatórios das tarefas 4 e 9, 12/11/2026)
  - **O que fazer:** acrescentar à P28 (preparo das worktrees) `npm --workspace apps/backend run prisma:generate` e `npx turbo run build --filter='./modules/*' --filter='./packages/*'`. Sem isso, o `nest build` e os testes de integração falham na worktree nova (`has no exported member 'PrismaClient'`, `Cannot find module '@oitenta/auth'`).
  - **Pronto quando:** a P28 e o roteiro do orquestrador tiverem os dois comandos.

- Ver também: "Tipo do prazo e nome curto do objetivo" (acima): a `category` do rascunho (`exam`, `assignment`, `project`) poderia alimentar o tipo do prazo ("Prova", "Entrega", "Publicar") nos objetivos criados pela IA; não faz parte da proposta.

### Concluídos (registro da sessão de 10/11/2026)

- [x] [EXECUTAR] Ligar o `ValidationPipe` (P19) e decorar os corpos do auth — (origem: diário, problema 3, C0, 10/11/2026) — fechado na C1 (`e39052e`).
- [x] [EXECUTAR] Configuração comum da aplicação em `apps/backend/src/app.setup.ts` (`configureApp`), usada pelo `main.ts` e pelos testes de integração — (origem: diário, problema 4, C0, 10/11/2026) — fechado na C0 (`189cd98`).
- [x] [EXECUTAR] Verificador completo inclui `test:e2e` do backend — (origem: diário, problema 5, C0, 10/11/2026) — registrado na regra do processo (§4).
- [x] [INVESTIGAR] Integração de docs com a verificação vermelha (`ac1ccd7`) — (origem: diário, problema 6, 10/11/2026) — causa: cliente do Prisma desatualizado no checkout principal; corrigido no processo (o verificador roda `prisma:generate` e grava selo verde por SHA; a integração exige o selo).
- [x] [EXECUTAR] Brief do revisor da C3 citava um `GetRampOptions` inexistente — (origem: diário, problema 7, C3, 10/11/2026) — sem ação: não é requisito; o `BuildRamp` (docs/3 §4.6) não usa histórico.
- [x] [INVESTIGAR] Teste ao vivo da D1 gravou uma grade no usuário demo do banco local — (origem: diário, problema 9, D1, 10/11/2026) — resolvido com o `db:reset-demo` (`eefc30b`); a validação do script segue no item "Script `db:reset-demo`".
- [x] [INVESTIGAR] Folga de 1 dia com prazo a 14 dias — (origem: diário, problema 13, E-web, 10/11/2026) — não é bug: é o `slackDays` da P9.

- [ ] [DECIDIR] Fornecedor de IA do backend hospedado (Render): hoje responde só o motor de regras — (origem: teste no celular e `feat/backend-ia-reasoning-effort`, 26/11/2026) — ver também "Modelo local do Ollama"
  - **Contexto:** no Render não há nenhuma variável `AI_*`, então o `POST /goals/assistant/draft` responde com `engine: "rules"`: etapas fixas por categoria, que ignoram o detalhe do texto (conferido com uma conta de teste, `teste.ia.1795695216@bora.app`, criada no banco hospedado). O Ollama não serve ali, porque roda no Mac. Localmente, o `apps/backend/.env` passou a usar o Groq (`openai/gpt-oss-120b`, plano gratuito) com `AI_REASONING_EFFORT="low"`.
  - **Problema:** o plano gratuito do Groq limita a 8.000 tokens por minuto e 200.000 por dia por modelo (cabeçalhos `x-ratelimit-*` conferidos). Com `low`, cada rascunho gasta ~1.300 tokens e leva ~1,5 s; dá ~6 rascunhos por minuto e ~150 por dia. No `ai:eval` (10 textos seguidos), 7 vieram do LLM e 3 caíram nas regras por limite (`/tmp/oitenta-teste-manual/ai-eval-groq-low.log`). Sem `low`, eram 5 de 10 e ~2.300 tokens por rascunho.
  - **Alternativas:**
    1. **Groq gratuito no Render** (`AI_PROVIDER=openai-compatible`, `AI_BASE_URL=https://api.groq.com/openai/v1`, `AI_MODEL=openai/gpt-oss-120b`, `AI_REASONING_EFFORT=low`, `AI_API_KEY` como segredo). Código: nenhum além desta branch. Vantagem: rápido, sem cartão, não retém dados por padrão. Desvantagem: o limite por minuto cai nas regras em picos (demo com várias pessoas ao mesmo tempo).
    2. **Gemini gratuito** (`gemini-3.1-flash-lite`, endpoint OpenAI-compatible). Código: nenhum, se o `json_object` funcionar (não testado). Vantagem: bom em português, ~500 pedidos/dia. Desvantagem: no plano gratuito o Google usa os textos para melhorar produtos; limites não publicados oficialmente.
    3. **Manter o motor de regras no Render.** Código: nada. Vantagem: sem dependência externa. Desvantagem: a IA da demo hospedada não personaliza nada.
  - **Como fazer (qualquer alternativa):** `docs/backend/CONFIGURAR-IA.md`.
  - **Recomendação:** 1, com uma chave nova só para o Render (a chave local `oitenta-local` apareceu no chat em 26/11 e deve ser trocada). Se a demo tiver muita gente ao mesmo tempo, revisitar (2 como segundo fornecedor exigiria código de cadeia de fallback).
