# Pitch e descrição do projeto (Hack Brasil 2026)

Escrito em 28/11/2026. Submissão fecha em **30/11/2026 às 23h59** (horário de Brasília). Depois disso, o repositório fica congelado até a final.

Duas partes:
1. **Prompt para o chat do Claude** que monta o roteiro do vídeo, os slides e o plano de demonstração.
2. **Textos da submissão**: nome, frase de apresentação e descrição.

---

## 1. Prompt para o chat do Claude

Copie tudo entre as linhas `=====` e cole num chat novo do Claude (claude.ai), com a pesquisa na web ligada.

=====

Você vai me ajudar a preparar o vídeo de pitch de 3 minutos do meu projeto no Hack Brasil 2026. Antes de escrever qualquer coisa, pesquise na internet como fazer um bom pitch curto e um bom vídeo de demo de hackathon. Depois use o que aprendeu para montar os entregáveis abaixo.

## Contexto do hackathon (do regulamento oficial, hackbrasil.com/regulamento)

- Hackathon nacional, fase online até 30/11/2026 às 23h59; até 5 projetos por trilha vão para a final presencial em São Paulo (12/12/2026).
- Precisamos enviar um **vídeo de até 3 minutos**, acessível sem login, que **mostre o produto funcionando**. Pode ser em português. O regulamento não exige roteiro nem formato.
- Os jurados **não são obrigados a instalar nem rodar** o projeto. Se a demo online cair, avaliam só pelo vídeo e pelo código. Ou seja: **o vídeo é a nossa principal chance de mostrar o produto**.
- Quatro critérios, **mesmo peso**, nota de 0 a 10 cada:
  1. **Execução técnica:** o produto funciona e está completo.
  2. **Implementação técnica:** arquitetura, qualidade do código, escolha e uso de tecnologias e APIs.
  3. **Impacto:** efeito sobre o problema e o público da trilha.
  4. **Qualidade da comunicação:** o vídeo.
- Cada projeto concorre em **uma trilha**, e o problema e o público precisam estar dentro dela. Trilhas possíveis para nós: **Acesso à educação** ou **Saúde & bem-estar**. [Escreva aqui qual trilha escolhemos.]
- Demos não podem mostrar dados pessoais reais de terceiros. Vamos usar o usuário de demonstração.

## O produto: Bora

**Frase:** um planejador com IA para quem sabe o que precisa fazer, mas trava na hora de começar.

**Problema:** saber o que fazer não basta para começar. As tarefas se acumulam, escolher por onde ir vira mais uma tarefa, e o celular vira fuga. Os apps de produtividade assumem que o difícil é lembrar; para muita gente o difícil é começar. E quando o plano dá errado, a agenda fica vermelha e gera culpa. Público principal: estudantes que conciliam aula, estágio e entregas.

**Solução, em três ideias:**
1. **Dois calendários:** Prazos (até quando entregar) e Execução (quando vou trabalhar nisso e por quanto tempo).
2. **Plano realista que se refaz sozinho:** um motor de agendamento encaixa as etapas só nos horários livres, respeita compromissos fixos (aula, estágio) e um limite diário de foco, deixa folga antes do prazo e avisa quando não cabe. Registrou que fez menos? O plano é recalculado na hora, sem bronca.
3. **Rampa para o "travei":** na hora de começar, o app pergunta a energia (baixa, média, alta, elétrico) e propõe uma escada de 5 degraus: aquecimento → desafio curto → micro-passo → foco com cronômetro → registro. Cada degrau tem opções para escolher.

O progresso vira um jardim: as gotas regam o Broto, o mascote.

**Fluxo da demo (tudo funciona de verdade, web e mobile):**
1. Entrar como demo.
2. Onboarding: pintar os horários livres na grade e escolher o limite diário (ex.: 2h).
3. Novo objetivo em texto livre: "Trabalho de Algoritmos — implementar e comparar 3 algoritmos de ordenação, entrega 24/12". A IA devolve título, prazo, categoria e etapas com tempo estimado e micro-passos. O usuário revisa e clica em "Encaixar no meu calendário".
4. As etapas aparecem distribuídas no calendário de Execução e o prazo no de Prazos.
5. Hoje: "Vamos começar?" → check-in de energia → rampa → foco.
6. Registrar "Concluí" ou "Parcial" → o progresso sobe e o plano é recalculado.
7. Mobile: mesma experiência, mais compromissos recorrentes (aula toda segunda, por exemplo), tema escuro e perfil.

**IA, com responsabilidade:**
- A IA só transforma texto em rascunho (objetivo + etapas). Nada é salvo sem o usuário confirmar.
- O motor do calendário é determinístico e testado: **a IA nunca mexe na agenda**.
- Se o modelo falha ou demora mais de 15 s, um motor de regras em português (entende "24/12", "amanhã", "em 10 dias") responde no lugar. O usuário nunca fica sem resposta.
- Fornecedor trocável só por configuração: Groq (`openai/gpt-oss-120b`) em produção, Ollama local em desenvolvimento.

**Técnica (para o critério de implementação):**
- Monorepo Turborepo em arquitetura limpa/hexagonal: domínio em TypeScript puro, sem framework, com **100% de cobertura de testes**.
- Backend NestJS + Prisma + PostgreSQL, com Swagger. Web em Next.js. App mobile em Flutter (iOS e Android).
- Desenvolvido com TDD, testes de integração HTTP, ponta a ponta com Playwright no web e `integration_test` no simulador iOS.
- Backend no Render, web na Vercel.

**O que ainda é visual (não prometer como pronto):** gotas, sequência e nível do jardim mostram valores fixos. Bloqueio de apps, tarefas leves como aquecimento e aprendizado das estimativas são próximos passos.

## O que quero que você pesquise primeiro

Pesquise e resuma em poucas linhas o que dizem as boas fontes sobre:
- estrutura de pitch curto (ex.: problema → solução → demo → diferencial → visão; técnicas de abertura com gancho; storytelling com uma persona);
- vídeos de demo de hackathon que se destacam: proporção entre fala e demonstração, ritmo, o que os jurados querem ver, erros comuns (slides demais, demo longa sem narração, termos técnicos, música alta);
- como escrever para fala: palavras por minuto em português, frases curtas, uma ideia por frase;
- gravação: tela + rosto, áudio, cortes, legendas, zoom no que importa, primeiros 10 segundos.

Cite as fontes. Depois, diga quais dessas técnicas você vai aplicar e por quê.

## Entregáveis

1. **Roteiro do vídeo, com no máximo 2min50s** (margem de segurança). Em tabela: tempo (início–fim), o que aparece na tela (slide, tela do web ou do app, rosto), a fala exata. Conte as palavras e confirme que cabe no tempo, considerando uma fala calma (cerca de 140 palavras por minuto). Regras:
   - abrir com um gancho de até 10 segundos que gere identificação ("você já abriu o celular para começar um trabalho e, 40 minutos depois, ainda não começou?");
   - pelo menos **metade do tempo mostrando o produto funcionando**, narrado;
   - deixar claro, sem jargão, os quatro critérios: funciona e está completo, como foi construído, para quem e qual impacto;
   - fechar com a visão e uma frase que fique na cabeça.
   Faça duas versões: uma com uma pessoa falando, outra dividida entre duas ou três pessoas do time.
2. **Slides de fundo:** de 5 a 7 slides, só os que aparecem no roteiro (abertura, problema, solução em três ideias, como a IA é usada com responsabilidade, arquitetura em um diagrama simples, visão/próximos passos, encerramento com o nome e o link). Pouquíssimo texto por slide. Paleta do app: verde `#047857` como cor principal, fundo claro, fontes arredondadas (Fredoka nos títulos e Nunito no texto). Gere o arquivo (.pptx ou um deck que eu consiga baixar) e escreva também o conteúdo de cada slide em texto.
3. **Plano da demonstração:** quais telas gravar, em que ordem, o que preparar antes (dados do demo zerados, objetivo de exemplo já escrito para colar, horário com bloco livre no Hoje), o que cortar se o tempo apertar, e se vale mostrar web e mobile ou só um deles. Lembre que o backend no plano gratuito pode demorar ~1 minuto para acordar: devo aquecê-lo antes de gravar.
4. **Dicas de gravação e edição** objetivas: ferramenta (OBS, Loom, Screen Studio, CapCut), resolução, áudio, legendas, velocidade da demo (acelerar esperas), onde hospedar (YouTube não listado) e um checklist final antes de enviar (duração ≤ 3:00, link abre em aba anônima, sem dados reais).
5. **Uma versão de 60 segundos** do pitch, para a apresentação presencial ou redes sociais.

Se faltar alguma informação (nomes do time, trilha, link da demo), pergunte antes de finalizar, ou deixe um espaço marcado para eu preencher.

=====

### Antes de colar, preencha

- A **trilha** escolhida (veja a recomendação abaixo).
- Os **nomes do time** e quem vai falar.
- O **link do web** na Vercel, se já existir.

### Recomendação de trilha

**Acesso à educação**, se o foco for estudante: o público dos exemplos e do app inteiro é quem concilia aula, estágio, trabalhos e provas, e o impacto é "estudante consegue começar e entregar". **Saúde & bem-estar** cabe se a história for sobre ansiedade, sobrecarga e procrastinação em geral. O regulamento diz que o júri pode realocar o projeto ou deixá-lo inelegível se o problema não estiver dentro da trilha, então a história do vídeo e da descrição precisa falar a língua da trilha escolhida. Decisão do time.

### O que mostrar nos 3 minutos (sugestão rápida)

| Tempo | Conteúdo |
|---|---|
| 0:00–0:15 | Gancho: a cena de quem trava diante de um trabalho |
| 0:15–0:40 | Problema e solução em três ideias (slides) |
| 0:40–2:00 | Demo no web: texto livre → IA quebra em etapas → encaixa no calendário → Hoje → rampa → registrar → plano recalculado |
| 2:00–2:20 | Mobile: o mesmo fluxo no celular, compromissos e tema escuro, em cortes rápidos |
| 2:20–2:40 | Como foi feito: IA que nunca mexe na agenda e sempre tem reserva, arquitetura limpa, 100% de cobertura no domínio |
| 2:40–2:50 | Visão (jardim, bloqueio de apps, estimativas que aprendem) e fechamento |

---

## 2. Textos da submissão

### Nome

Bora

### Frase de apresentação

Um planejador com IA para quem sabe o que precisa fazer, mas trava na hora de começar.

### Descrição

Saber o que precisa ser feito nem sempre basta para conseguir começar. As tarefas se acumulam, escolher por onde seguir vira mais uma tarefa e o celular vira fuga. Os apps de produtividade assumem que o difícil é lembrar; para muita gente, principalmente estudantes que conciliam aula, estágio e entregas, o difícil é começar. E quando o plano dá errado, a agenda fica vermelha e gera culpa.

O Bora resolve isso com três ideias:

**1. A IA transforma intenção em plano.** A pessoa escreve o que precisa entregar em texto livre, como falaria com um amigo ("trabalho de Algoritmos, comparar 3 algoritmos de ordenação, entrega 24/12"). A IA devolve um rascunho com título, prazo, categoria e etapas, cada uma com tempo estimado e um micro-passo para começar. Nada é salvo sem a confirmação do usuário.

**2. Dois calendários e um plano que se refaz sozinho.** O Bora separa o calendário de Prazos (até quando entregar) do de Execução (quando trabalhar e por quanto tempo). Um motor de agendamento determinístico encaixa as etapas só nos horários livres, respeita compromissos fixos e recorrentes, não passa do limite diário de foco que a pessoa escolheu, deixa folga antes do prazo e avisa quando algo não cabe. Cada vez que a pessoa registra o que fez, inclusive "parcial" ou "não rolou", o plano futuro é recalculado na hora, sem bronca.

**3. Uma rampa para quando a pessoa trava.** Em vez de "foque por 2 horas", o app pergunta a energia do momento e sugere uma escada de cinco degraus: aquecimento, desafio curto, micro-passo, foco com cronômetro e registro. Cada degrau tem opções para escolher, e a pessoa sobe até conseguir se concentrar. O progresso vira um jardim que ela rega.

**IA com responsabilidade.** A IA só gera rascunhos; a agenda é sempre calculada por um motor testado, sem IA. Se o modelo falha ou passa de 15 segundos, um motor de regras em português (que entende "24/12", "amanhã", "em 10 dias") responde no lugar, então o usuário nunca fica sem resposta. O fornecedor é trocado só por configuração: Groq (gpt-oss-120b) em produção e Ollama local em desenvolvimento, sem dados saindo da máquina.

**Como foi construído.** Monorepo com Turborepo em arquitetura limpa/hexagonal: o domínio (objetivos, agenda, rampa, autenticação) é TypeScript puro, sem framework, com 100% de cobertura de testes e teste de posse em todo caso de uso. Backend em NestJS, Prisma e PostgreSQL, com Swagger. Web em Next.js e app mobile em Flutter para iOS e Android, ambos completos: cadastro, onboarding, novo objetivo com IA ou à mão, compromissos recorrentes, calendário de execução e de prazos, Hoje, rampa, registro e perfil. Desenvolvido com TDD, testes de integração HTTP e testes ponta a ponta (Playwright no web, integration_test no simulador iOS). Backend no Render e web na Vercel.

**Próximos passos.** Gamificação calculada a partir das sessões, bloqueio de apps que distraem com liberação pelas gotas conquistadas, tarefas leves do dia como aquecimento da rampa, rotina descrita em texto livre e estimativas que aprendem com o tempo real de cada pessoa.
