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
- Cada projeto concorre em **uma trilha**, e o problema e o público precisam estar dentro dela; citar o tema não basta, e o júri pode realocar o projeto ou deixá-lo inelegível. **Nossa trilha é Saúde & bem-estar.** Por isso o roteiro precisa deixar claro, desde o gancho, que o problema é de bem-estar (sobrecarga, ansiedade antes de começar, culpa quando o plano falha, uso do celular como fuga) e que o impacto é na saúde mental e na relação da pessoa com a própria rotina, não só em produtividade.
- Demos não podem mostrar dados pessoais reais de terceiros. Vamos usar o usuário de demonstração.

## O produto: Bora

**Frase:** um planejador com IA para quem sabe o que precisa fazer, mas trava na hora de começar.

**Problema:** saber o que fazer não basta para começar. As tarefas se acumulam, escolher por onde ir vira mais uma tarefa, e o celular vira fuga. Os apps de produtividade assumem que o difícil é lembrar; para muita gente o difícil é começar. E quando o plano dá errado, a agenda fica vermelha e gera culpa. Esse ciclo de travar, se culpar e travar de novo gera ansiedade e esgotamento. Público principal: pessoas sobrecarregadas que procrastinam por excesso, não por falta de vontade, a começar por estudantes que conciliam aula, estágio e entregas.

**Por que é saúde & bem-estar (o ângulo do pitch):**
- **Limite diário de foco:** a pessoa escolhe quanto aguenta por dia, e o motor nunca passa disso. O plano protege o descanso em vez de lotar cada horário livre.
- **Sem culpa:** registrar "parcial" ou "não rolou" só refaz o plano. Não tem tela vermelha nem cobrança; o dia ruim não vira regra.
- **Rampa que cuida do corpo e da cabeça:** os degraus de aquecimento são atividades de autocuidado com tempo definido: alongamento de 3 min, um copo d'água e 5 respirações lentas, uma volta pela casa, arrumar a mesa. Depois vem um desafio curto (ex.: 5 contas), o micro-passo e só então o foco, em blocos de 10 a 45 min, escolhidos pela energia do momento.
- **Menos decisões:** o app escolhe o próximo passo, o que reduz a sobrecarga de ter que reorganizar tudo de cabeça.
- **Visão:** bloqueio voluntário dos apps que distraem, liberados com as gotas conquistadas, para a pessoa retomar o controle do tempo de tela.
- **Cuidado para não prometer demais:** o Bora não é tratamento nem ferramenta clínica, e não mede saúde. É apoio para a rotina. O roteiro não deve falar em diagnóstico, TDAH ou ansiedade como condição clínica.

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

- Os **nomes do time** e quem vai falar.
- O **link do web** na Vercel, se já existir.

### Trilha: Saúde & bem-estar (decidida em 28/11/2026)

O regulamento exige que o problema e o público estejam dentro da trilha (itens 5.3 a 5.5). Na prática:
- **Conte a história pelo bem-estar:** o problema é o ciclo de travar, se culpar e travar de novo, não "falta de organização". A produtividade é consequência.
- **Mostre na demo o que é de bem-estar:** o limite diário no onboarding, um degrau de aquecimento (água e respirações, ou alongamento) na rampa, e o "Parcial" refazendo o plano sem bronca.
- **Não prometa o que o app não faz:** nada de diagnóstico, tratamento ou medição de saúde.
- O exemplo do trabalho de faculdade pode continuar: ele mostra a sobrecarga de quem concilia aula, estágio e entregas.

### O que mostrar nos 3 minutos (sugestão rápida)

| Tempo | Conteúdo |
|---|---|
| 0:00–0:15 | Gancho: a cena de quem trava diante de um trabalho, abre o celular e termina o dia com culpa |
| 0:15–0:40 | Problema (o ciclo trava → culpa → ansiedade) e solução em três ideias (slides) |
| 0:40–2:00 | Demo no web: limite diário no onboarding → texto livre → IA quebra em etapas → encaixa no calendário → Hoje → rampa com aquecimento de autocuidado → registrar "Parcial" → plano recalculado sem bronca |
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

Saber o que precisa ser feito nem sempre basta para conseguir começar. As tarefas se acumulam, escolher por onde seguir vira mais uma tarefa e o celular vira fuga. Quando o plano dá errado, a agenda fica vermelha e vem a culpa, que deixa o próximo começo ainda mais difícil. Esse ciclo de travar, se culpar e travar de novo alimenta ansiedade e esgotamento, principalmente em quem concilia muitas frentes, como estudantes com aula, estágio e entregas. Os apps de produtividade assumem que o difícil é lembrar; para essas pessoas, o difícil é começar sem se sobrecarregar.

O Bora é um apoio de bem-estar para a rotina, com três ideias:

**1. A IA transforma intenção em plano.** A pessoa escreve o que precisa entregar em texto livre, como falaria com um amigo ("trabalho de Algoritmos, comparar 3 algoritmos de ordenação, entrega 24/12"). A IA devolve um rascunho com título, prazo, categoria e etapas, cada uma com tempo estimado e um micro-passo para começar. Nada é salvo sem a confirmação do usuário.

**2. Dois calendários e um plano que se refaz sozinho.** O Bora separa o calendário de Prazos (até quando entregar) do de Execução (quando trabalhar e por quanto tempo). Um motor de agendamento determinístico encaixa as etapas só nos horários livres, respeita compromissos fixos e recorrentes, nunca passa do limite diário de foco que a própria pessoa escolheu (o plano protege o descanso em vez de lotar cada horário livre), deixa folga antes do prazo e avisa quando algo não cabe. Cada vez que a pessoa registra o que fez, inclusive "parcial" ou "não rolou", o plano futuro é recalculado na hora, sem tela vermelha e sem bronca: um dia ruim não vira regra.

**3. Uma rampa para quando a pessoa trava.** Em vez de "foque por 2 horas", o app pergunta a energia do momento e sugere uma escada de cinco degraus: um aquecimento de autocuidado com tempo definido (alongamento de 3 minutos, um copo d'água e cinco respirações lentas, uma volta pela casa), um desafio curto, um micro-passo, um bloco de foco de 10 a 45 minutos e o registro. Cada degrau tem opções para escolher, e a pessoa sobe no próprio ritmo até conseguir se concentrar. O progresso vira um jardim que ela rega.

O Bora não é ferramenta clínica nem substitui cuidado profissional: é um apoio para reduzir a sobrecarga do dia a dia e tornar o recomeço mais leve.

**IA com responsabilidade.** A IA só gera rascunhos; a agenda é sempre calculada por um motor testado, sem IA. Se o modelo falha ou passa de 15 segundos, um motor de regras em português (que entende "24/12", "amanhã", "em 10 dias") responde no lugar, então o usuário nunca fica sem resposta. O fornecedor é trocado só por configuração: Groq (gpt-oss-120b) em produção e Ollama local em desenvolvimento, sem dados saindo da máquina.

**Como foi construído.** Monorepo com Turborepo em arquitetura limpa/hexagonal: o domínio (objetivos, agenda, rampa, autenticação) é TypeScript puro, sem framework, com 100% de cobertura de testes e teste de posse em todo caso de uso. Backend em NestJS, Prisma e PostgreSQL, com Swagger. Web em Next.js e app mobile em Flutter para iOS e Android, ambos completos: cadastro, onboarding, novo objetivo com IA ou à mão, compromissos recorrentes, calendário de execução e de prazos, Hoje, rampa, registro e perfil. Desenvolvido com TDD, testes de integração HTTP e testes ponta a ponta (Playwright no web, integration_test no simulador iOS). Backend no Render e web na Vercel.

**Próximos passos.** Bloqueio voluntário dos apps que distraem, com liberação pelas gotas conquistadas, para a pessoa retomar o controle do tempo de tela; gamificação calculada a partir das sessões; tarefas leves do dia como aquecimento da rampa, rotina descrita em texto livre e estimativas que aprendem com o tempo real de cada pessoa.
