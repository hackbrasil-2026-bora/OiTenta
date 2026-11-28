# Bora 🌱

**Um planejador com IA para quem sabe o que precisa fazer, mas trava na hora de começar.**

Você escreve o que tem para entregar, do jeito que falaria com um amigo. O Bora quebra em etapas, encaixa nos seus horários livres e, quando chega a hora e você trava, oferece uma rampa: degraus pequenos, do mais fácil ao foco de verdade.

> Projeto do **Hack Brasil 2026**. O repositório se chama OiTenta (nome provisório); o app se chama **Bora**.

| | |
|---|---|
| **Backend (API + Swagger)** | https://oitenta.onrender.com/docs |
| **Web** | _a preencher com a URL da Vercel_ |
| **Vídeo de 3 min** | _a preencher_ |
| **Mobile** | Flutter (iOS e Android), roda pelo código: veja [Como testar](#como-testar) |

> O backend está no plano gratuito do Render: a primeira requisição depois de um tempo parado pode levar até ~1 minuto para acordar.

---

## Índice

1. [O problema](#o-problema)
2. [A solução](#a-solução)
3. [Como funciona, passo a passo](#como-funciona-passo-a-passo)
4. [O papel da IA (e onde ela não entra)](#o-papel-da-ia-e-onde-ela-não-entra)
5. [O que já funciona](#o-que-já-funciona)
6. [Arquitetura](#arquitetura)
7. [Como testar](#como-testar)
8. [Qualidade e testes automatizados](#qualidade-e-testes-automatizados)
9. [Próximos passos](#próximos-passos)
10. [Documentação](#documentação)
11. [Equipe](#equipe)

---

## O problema

Saber o que precisa ser feito não basta para conseguir começar. As tarefas se acumulam, escolher por onde seguir vira mais uma tarefa, e o celular acaba sendo a fuga, mesmo quando a pessoa queria estar fazendo outra coisa.

Os apps de produtividade comuns assumem que o difícil é **lembrar**. Para muita gente o difícil é **começar**: transformar "tenho um trabalho para o dia 24" em "agora, às 20h, eu leio o enunciado por 30 minutos". E quando o plano dá errado (um dia ruim, uma tarefa que demorou mais), a maioria das agendas simplesmente fica vermelha e gera culpa.

Pensamos primeiro em estudantes que conciliam aula, estágio e entregas, mas o problema vale para qualquer pessoa que procrastina por sobrecarga e não por falta de vontade.

## A solução

O Bora junta três ideias:

1. **Dois calendários.** Um de **Prazos** (até quando cada coisa precisa estar pronta) e um de **Execução** (quando você vai trabalhar nela e por quanto tempo). Um objetivo vira vários blocos de execução antes do prazo.
2. **Plano realista que se refaz sozinho.** Um motor de agendamento encaixa as etapas só nos seus horários livres, respeita seus compromissos fixos e um limite diário de foco, deixa folga antes do prazo e avisa quando não cabe. Registrou que fez menos do que o planejado? O plano do futuro é recalculado na hora, sem bronca.
3. **Rampa de ativação para o "travei".** Na hora de começar, em vez de "foque por 2 horas", o app pergunta sua energia e propõe uma escada de 5 degraus: aquecimento → desafio curto → micro-passo → foco → registro. Cada degrau tem opções para escolher, e você sobe até conseguir se concentrar.

O progresso vira um **jardim**: as gotas que você ganha regam o Broto, o mascote do app.

## Como funciona, passo a passo

1. **Cadastro e onboarding.** Você pinta na grade seus horários livres da semana e escolhe quanto tempo de foco aguenta por dia (ex.: 2h).
2. **Compromissos.** Aula, estágio, academia: compromissos únicos ou recorrentes ocupam a agenda e o motor não agenda nada por cima.
3. **Novo objetivo, em texto livre.** Ex.: _"Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação, entrega 24/12"_. A IA devolve um rascunho com título, prazo, categoria e etapas, cada uma com estimativa de tempo e micro-passos. Você revisa, edita e confirma. Também dá para preencher tudo à mão.
4. **Encaixar no calendário.** O motor distribui as etapas em blocos de pelo menos 30 minutos, alinhados a cada 15, por ordem de prazo, sem passar do seu limite diário.
5. **Hoje.** A tela inicial mostra só o que importa agora: o próximo bloco e o botão **Vamos começar?**
6. **Rampa.** Check-in de energia (baixa, média, alta, elétrico) → o app sugere o degrau certo → aquecimento, desafio, micro-passo, foco com cronômetro.
7. **Registrar.** Concluí, parcial ou não rolou. O progresso da etapa e do objetivo é atualizado (média ponderada pelo tempo estimado) e o plano é **recalculado** a partir dali.

## O papel da IA (e onde ela não entra)

- **Entra:** transformar texto livre em objetivo estruturado (`parseGoal`) e sugerir etapas com estimativa e micro-passo (`suggestSteps`). Rota `POST /goals/assistant/draft`.
- **Nunca decide sozinha:** a resposta é um rascunho; nada é gravado sem a confirmação do usuário. A estimativa da IA e a confirmada pelo usuário ficam salvas separadamente, para aprender depois.
- **Não entra no calendário:** o motor de agendamento é **determinístico** e testado, sem IA. O mesmo plano sai sempre do mesmo dado.
- **Nunca deixa o usuário na mão:** cada rascunho tem orçamento de 15 s. Se o modelo falha, demora ou devolve algo inválido, um **motor de regras** em português (leitor de datas como "24/12", "amanhã", "em 10 dias", modelos de etapas por categoria) responde no lugar. A resposta diz quem respondeu (`"engine": "llm"` ou `"rules"`).
- **Fornecedor neutro:** qualquer API compatível com OpenAI, trocada só pelo `.env`. Em produção: Groq com `openai/gpt-oss-120b`. Em desenvolvimento: Ollama local (`qwen2.5:3b`), sem nada sair da máquina.
- **Saída validada duas vezes:** formato (no adaptador) e regras do domínio (título até 120 caracteres, estimativas múltiplas de 15 min etc.), valendo para qualquer motor.

Detalhes: [proposta](docs/7-proposta-ia.md), [avaliação dos modelos](docs/8-avaliacao-ia.md), [como configurar](docs/backend/CONFIGURAR-IA.md).

## O que já funciona

| Funcionalidade | Web | Mobile |
|---|:-:|:-:|
| Cadastro, login e **Entrar como demo** | ✅ | ✅ |
| Onboarding: grade de horários livres e limite diário | ✅ | ✅ |
| Novo objetivo com IA (texto livre → etapas editáveis) | ✅ | ✅ |
| Novo objetivo à mão e tarefa única | ✅ | ✅ |
| Compromissos únicos e recorrentes (editar só um dia, os seguintes ou todos) | | ✅ |
| Hoje, com o próximo bloco | ✅ | ✅ |
| Calendário de Execução e de Prazos (dia, semana, mês) | ✅ | ✅ |
| Trilha do objetivo, com progresso por etapa | ✅ | ✅ |
| Rampa completa: energia → aquecimento → desafio → micro-passo → foco → registro | ✅ | ✅ |
| Replanejamento automático depois de cada registro | ✅ | ✅ |
| Perfil e configurações (nome, e-mail, senha, apagar conta) | ✅ | ✅ |
| Tema escuro | | ✅ |
| Jardim e gamificação | visual (valores fixos) | visual (valores fixos) |

## Arquitetura

Monorepo com Turborepo, em **arquitetura limpa / hexagonal**: as regras de negócio não conhecem framework, banco nem IA.

```
apps/
  backend/     NestJS + Prisma + PostgreSQL     (porta 4000, Swagger em /docs)
  frontend/    Next.js: landing + web app       (porta 3000)
  mobile/      Flutter: iOS e Android
modules/       domínio puro, um pacote por módulo de negócio
  auth/          usuário, senha com hash, JWT
  goals/         objetivos, etapas, assistente de IA (porta GoalAssistantProvider)
  scheduling/    disponibilidade, compromissos, recorrência, motor do plano
  activation/    rampa e sessões de foco
  gamification/, notifications/   (estrutura pronta para a próxima fase)
packages/
  shared/      Entity, UseCase, erros e validações comuns
  contracts/   openapi.json exportado do backend
```

Princípios que seguimos:

- **Domínio sem framework.** `modules/*` é TypeScript puro, com casos de uso, entidades e portas (interfaces). O backend só implementa as portas: repositórios Prisma, provider de IA, JWT, bcrypt.
- **Interfaces só nas fronteiras:** repositórios, IA, fontes de ocupação da agenda (`BusySource`: compromissos hoje, Google Calendar amanhã), opções da rampa (`RampOptionSource`).
- **Posse pelo token.** Todo dado pertence a um `userId` tirado do JWT, nunca do corpo da requisição. Há teste negativo de posse em todos os casos de uso.
- **Orquestradores** no backend encadeiam casos de uso entre módulos (ex.: registrar sessão → atualizar progresso → recalcular plano) sem calcular nada.
- **Tempo:** a grade guarda horários locais no fuso do usuário; todo bloco é salvo em UTC.
- **Web e mobile** usam repositórios trocáveis: dados reais por HTTP ou dados de exemplo sem backend, com as mesmas telas.

| Camada | Tecnologia |
|---|---|
| Backend | NestJS 11, Prisma 7, PostgreSQL, JWT, Swagger/OpenAPI |
| Web | Next.js 16, React 19, Phosphor Icons, Playwright |
| Mobile | Flutter, go_router, `ChangeNotifier` por tela, `integration_test` |
| IA | API compatível com OpenAI via `fetch` (Groq em produção, Ollama local) + motor de regras |
| Hospedagem | Render (backend e banco), Vercel (web) |

## Como testar

### Opção 1: sem instalar nada

1. Abra o web (link no topo) e clique em **Entrar direto como Arthur (demo)**. Se o backend estiver dormindo, espere até ~1 minuto.
2. Faça o onboarding: pinte alguns horários livres e escolha o limite diário.
3. Crie um objetivo com a IA, por exemplo: `Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação, entrega daqui a 2 semanas`. Revise as etapas e clique em **Encaixar no meu calendário**.
4. Veja os blocos no **Hoje** e no **Calendário** (Execução e Prazos).
5. Clique em **Vamos começar?**, escolha a energia e siga a rampa até o foco.
6. Registre como **Concluí** ou **Parcial** e veja o progresso subir e o plano ser recalculado.

Também dá para explorar a API direto no Swagger: https://oitenta.onrender.com/docs → `POST /auth/demo` → copie o `token` → **Authorize** → teste as rotas.

### Opção 2: rodar tudo na sua máquina

Pré-requisitos: **Node.js 24+**, **npm 11.12+**, **Docker Desktop** aberto. Para o mobile, **Flutter** e Xcode (iOS) ou Android Studio.

Todos os comandos rodam na raiz do repositório.

```bash
npm install
```

```bash
cp -n apps/backend/.env.example apps/backend/.env
```

```bash
npm --workspace apps/backend run prisma:generate && npm run build
```

```bash
npm --workspace apps/backend run db:start
```

```bash
npm --workspace apps/backend run prisma:migrate:deploy && npm --workspace apps/backend run prisma:seed
```

```bash
npx turbo run dev --filter=@oitenta/backend
```

O backend sobe em http://localhost:4000 (Swagger em `/docs`). O `.env` de exemplo já funciona e usa o **motor de regras** da IA, sem chave nenhuma. Para ligar um LLM (Groq, Ollama, OpenRouter), veja [CONFIGURAR-IA.md](docs/backend/CONFIGURAR-IA.md).

Em outro terminal, o web:

```bash
npx turbo run dev --filter=@oitenta/frontend
```

Abra http://localhost:3000/entrar e clique em **Entrar direto como Arthur (demo)**.

O mobile, com o simulador iOS aberto:

```bash
cd apps/mobile && flutter pub get && flutter run --dart-define-from-file=env/local-simulator.json
```

Para recomeçar do onboarding com o usuário demo:

```bash
npm --workspace apps/backend run db:reset-demo
```

Sem backend nenhum, o web e o mobile também rodam com dados de exemplo (`NEXT_PUBLIC_DATA_SOURCE=example` no web, `--dart-define=DATA_SOURCE=sample` no mobile).

Guias completos, com o resultado esperado de cada passo:

- [Backend](docs/backend/COMO-TESTAR.md): inclui o fluxo inteiro por `curl` e o assistente de IA.
- [Web](docs/frontend/COMO-TESTAR.md): roteiro manual e ponta a ponta.
- [Mobile](docs/mobile/COMO-TESTAR.md): simulador iOS, iPhone físico e Android.

## Qualidade e testes automatizados

| O quê | Comando |
|---|---|
| Build de todos os pacotes | `npm run build` |
| Lint de todos os workspaces | `npx turbo run lint` |
| Testes unitários (domínio com **100% de cobertura**) | `npm run test --workspaces --if-present` |
| Integração HTTP do backend (Postgres no ar) | `npm --workspace apps/backend run test:e2e` |
| Ponta a ponta do web (Playwright) | ver [docs/frontend/COMO-TESTAR.md](docs/frontend/COMO-TESTAR.md) |
| Mobile: análise, testes e ponta a ponta no simulador | `cd apps/mobile && flutter analyze && flutter test` |
| Comparar o LLM com o motor de regras em 10 textos | `npm --workspace apps/backend run ai:eval` |

O desenvolvimento foi feito com TDD (teste vermelho antes da implementação), uma branch por tarefa a partir da `developer`, e verificação completa antes de cada merge. O processo está em [.agents/rules/processo-desenvolvimento.md](.agents/rules/processo-desenvolvimento.md) e o histórico em [docs/6-diario-execucao.md](docs/6-diario-execucao.md).

## Próximos passos

- **Gamificação de verdade:** gotas e sequência calculadas a partir das sessões registradas.
- **Bloqueio de distrações:** a pessoa escolhe apps para bloquear e usa as gotas para liberar acesso temporário.
- **Tarefas leves como aquecimento:** as pequenas tarefas do dia viram opções dos degraus da rampa.
- **Rotina em texto livre:** "faço aula de manhã e estágio à tarde" vira compromissos recorrentes.
- **Replanejar com IA:** juntar o que falta de um objetivo atrasado e propor novas etapas.
- **Estimativas que aprendem:** usar o tempo real das sessões para ajustar as próximas estimativas.
- **Google Calendar** como mais uma fonte de ocupação da agenda.

## Documentação

| Documento | Conteúdo |
|---|---|
| [0-casos-de-uso.md](docs/0-casos-de-uso.md) | Casos de uso do produto |
| [0-fluxos.md](docs/0-fluxos.md) | Fluxos de tela |
| [0-design-system.md](docs/0-design-system.md) | Cores, tipografia e componentes |
| [2-decisoes-mvp.md](docs/2-decisoes-mvp.md) | Todas as decisões de produto e técnicas |
| [3-modelagem-dominio.md](docs/3-modelagem-dominio.md) | Entidades, regras e cenários de teste |
| [4-contrato-api.md](docs/4-contrato-api.md) | Contrato da API |
| [7-proposta-ia.md](docs/7-proposta-ia.md) | Como a IA entra no projeto |
| [8-avaliacao-ia.md](docs/8-avaliacao-ia.md) | Medições dos modelos |

## Equipe

Time de 4 pessoas no Hack Brasil 2026. _(nomes e links a preencher)_
