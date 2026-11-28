# Telas — mobile, projeto "Bora App" (Flutter)

Fonte: `design/mobile/app/source/` (zip "Bora app anti-procrastinação telas principais"). Protótipo navegável `Bora App.dc.html` + dados de exemplo `bora-data.js`. Capturas em `design/mobile/app/screens/`: viewport 390×844, deviceScaleFactor 2, só a moldura do celular. Quando a tela rola por dentro, o conteúdo foi expandido para aparecer inteiro (a tab bar fica no fim da imagem).

O protótipo tem um painel "Bora · protótipo" com um botão por estado. A coluna "Ação" diz o que leva à tela **no app**; entre parênteses, o botão do painel usado na captura.

UC = `docs/0-casos-de-uso.md` · Fluxo = seção de `docs/0-fluxos.md`.

| # | Tela | O que mostra | Ação (painel) | UC | Fluxo |
|---|---|---|---|---|---|
| 01 | Hoje | Barra gamificada, "Bom dia, Arthur", "Vamos começar?", timeline com etapas e tarefas leves, folga até o prazo. Sem card de energia | Abrir o app / aba Hoje (Hoje) | UC06 | §2 |
| 02 | Objetivos | Lista com %, prazo, folga e "Novo objetivo" | Aba Objetivos (Objetivos) | UC12 | §6 |
| 03 | Semana | Semana compacta com pontos por objetivo, Execução/Prazos, lista do dia | Aba Semana (Semana, em Abas) | UC07 | §5 |
| 04 | Jardim | Broto, nível, dias regados, conquistas, loja | Aba Jardim (Jardim) | UC25 | §7 |
| 05 | Rampa 1 — check-in | Bottom sheet com energia em **4 níveis** (Baixa, Média, Alta, Elétrico) + "Quanto tempo você tem agora?" + "Montar minha rampa" | "Vamos começar?" (Check-in) | UC14, UC15 | §3 |
| 06 | Rampa 2 — escada | "Sua rampa tá pronta": 5 degraus, sugerido destacado, "Trocar", "Pular pra tarefa", "Começar daqui" | "Montar minha rampa" (Escada) | UC15, UC19 | §3 |
| 07 | Rampa 3 — aquecimento | Alongamento com timer e passos, "Já terminei" | "Começar daqui" no Aquecer (Aquecimento) | UC16 | §3 |
| 08 | Rampa 4 — desafio mental | Conta 1 de 5 com teclado numérico | Degrau seguinte (Desafio mental) | UC17 | §3 |
| 09 | Rampa 5 — micro-passo | "Abra o arquivo do trabalho e escreva o título", "Feito!" | Degrau seguinte (Micro-passo) | UC18 | §3 |
| 10 | Rampa 6 — foco | Timer 25 min, Broto de óculos, Pausar / Encerrar / **Pedir ajuda**, "Bloquear apps de distração" | Degrau seguinte (Foco) | UC20, UC26 | §3 |
| 11 | Rampa 7 — registro | "Quanto você avançou?" Concluí / Parcial / Não rolou + "Registrar" | "Encerrar" (Registro) | UC21, UC08 | §3 |
| 12 | Rampa 8 — celebração | "+20", etapa concluída, XP e nível, "Voltar pra Hoje" | "Registrar" (Celebração) | UC21, UC25 | §3 |
| 13 | Novo objetivo — chat vazio | Broto pede o objetivo; texto, áudio ou anexo; "Preencher à mão" | "Novo objetivo" (Chat vazio) | UC02 | §4 |
| 14 | Novo objetivo — analisando | PDF anexado + texto; "Lendo o que você mandou…" | Enviar (Chat · analisando) | UC02, UC03 | §4 |
| 15 | Novo objetivo — resposta | "Achei 4 requisitos…", card de etapas editáveis com tempo e total, encaixar no calendário | Fim da análise (Chat · resposta) | UC04, UC05 | §4 |
| 16 | Preencher à mão | Título, tempo estimado (chips), prazo opcional, "Deixar a IA encaixar" / escolher dia e hora | "Preencher à mão" (Preencher à mão) | UC30 | §4 |
| 17 | Plano inviável | "Não cabe tudo até 24/11: faltam 2h15", opções (subir limite, empurrar outro objetivo, usar o sábado) | Encaixar um objetivo que não cabe (Plano inviável) | UC11 | §5 |
| 18 | Trilha · Algoritmos | Anel 57%, "4 de 7 etapas", trilha com datas e tempos até a entrega | Tocar num objetivo (Trilha · Algoritmos) | UC10 | §6 |
| 19 | Calendário — semana | Idem 03, aberto pelo grupo Calendário do painel | Aba Semana (Semana, em Calendário) | UC07 | §5 |
| 20 | Calendário — mês | Mês expandido, "Arraste pra cima pra voltar à semana" | Arrastar a semana para baixo (Mês) | UC07 | §5 |
| 21 | Calendário — prazos | Mês com as entregas finais | "Prazos" (Prazos) | UC07 | §5 |
| 22 | Tarefas leves | Filtros por duração, "Pra hoje", lista com +3 | Atalho no Hoje / Perfil (Tarefas leves) | UC13 | — |
| 23 | Pausa | "Pausado há 0 min", "Voltar com mini-degrau", "Voltar direto pro foco", "Encerrar por hoje" | "Pausar" no foco (Pausa) | UC22 | §3 |
| 24 | Mini-degrau | Mini-degrau de 2 min, "Pronto, voltar pro foco" | "Voltar com mini-degrau" (Mini-degrau) | UC22 | §3 |
| 25 | Pedir ajuda | "Deu vontade de pegar o celular? Normal…", "Você já focou 10 min", "Bora reaquecer" / "Voltar ao foco" | "Pedir ajuda" no foco (Pedir ajuda) | UC31 | §3 |
| 26 | Perfil | Dados, preferências (modo escuro, bloquear apps, máximo por dia, lembrete) e configurações | Botão de perfil no topo (Perfil) | UC32 | §7 |
| 27 | Redefinir rotina | Grade de horários livres + limite diário, "Salvar e recalcular plano" | Perfil > Redefinir minha rotina (Redefinir rotina) | UC01, UC09 | §1/§7 |
| 28 | Idioma | Perfil com o seletor de idioma aberto | Perfil > Idioma (Idioma) | UC32 | §7 |
| 29 | Enviar sugestão | Texto, anexar print, e-mail de contato | Perfil > Enviar sugestão (Enviar sugestão) | UC32 | §7 |
| 30 | Hoje — tema escuro | Hoje no modo escuro | Perfil > Modo escuro (Tema: Escuro) | UC32 | §7 |
| 31 | Bora Telas — prancheta 1 | "Tela 1 — Hoje (modo claro)", versão anterior do Hoje **com** card "Como está sua energia?" | `Bora Telas.dc.html` desta pasta | UC06, UC14 | §2 |
| 32 | Bora Telas — canvas | O canvas completo do arquivo acima (1440 de largura) | `Bora Telas.dc.html` desta pasta | — | — |
| 33 | Acesso — Login | Broto, "Que bom te ver!", e-mail, senha com olho, "Esqueci minha senha", "Entrar" (habilita com e-mail válido e senha ≥ 6), "Entrar com Google", "Criar conta" | Abrir o app sem sessão (Login) | UC32 | — |
| 34 | Acesso — Criar conta | "Criar sua conta": nome ("Como quer ser chamado?"), e-mail, senha com dica, confirmação, termos, "Criar conta", "Já tem conta? Entrar" | "Criar conta" no Login (Criar conta) | UC32 | §1 |
| 35 | Acesso — Criar conta preenchido | Idem 34 com as dicas verdes ("As senhas batem") e os termos marcados | Preencher o formulário (Criar conta + preenchimento) | UC32 | §1 |
| 36 | Acesso — Esqueci a senha | "Esqueceu a senha?", e-mail, "Enviar link", "Voltar pro login" | "Esqueci minha senha" no Login (Esqueci a senha) | — | — |
| 37 | Acesso — Código | "Confere seu e-mail", 6 caixas do código, "Verificar código", "Reenviar código", "Trocar e-mail" | "Enviar link" (Código) | — | — |
| 38 | Acesso — Nova senha | "Crie uma nova senha", nova senha + confirmação, "Salvar nova senha" | Código certo (Nova senha) | — | — |
| 39 | Jardim pelo Broto | Jardim com o topo (Broto + barra + "A") e a tab bar nova (Hoje, Objetivos, Semana, Compromissos) | Tocar o Broto do topo (Jardim (pelo Broto)) | UC25 | §7 |
| 40 | Perfil com a tab bar nova | Idem 26, com a tab bar nova e nenhuma aba ativa | Botão "A" (Perfil) | UC32 | §7 |
| 41 | ~~Compromissos~~ | **Removida do design em 20/11/2026** (os compromissos passam a ser cadastrados pelo "+ Compromisso" da Semana, 44–52) | — | — | — |
| 42 | ~~Novo compromisso (versão de 19/11)~~ | Substituída pelas 46, 46b, 47 e 52 | — | — | — |
| 43 | Tarefas únicas | Anotar tarefa avulsa com duração e quando | Atalho no Hoje (Tarefas únicas) | UC30 | — |
| 44 | Semana com "+ Compromisso" | Título do dia com o botão "+ Compromisso" à direita (só em Execução) | Aba Semana (Semana) | UC01, UC07 | §5 |
| 45 | Semana com compromissos | Dia 11: "Consulta no dentista" (Compromisso · Só uma vez) na lista do dia, misturada às etapas pela hora | Tocar no dia 11 (Compromisso no calendário, sheet fechado) | UC01, UC07 | §5 |
| 46 | Novo compromisso (semanal) | Nome, Tipo (Aula, Trabalho, Saúde, Pessoal), Repete? (Toda semana) — topo | "+ Compromisso" e "Toda semana" (Novo compromisso) | UC01 | §1 |
| 46b | Novo compromisso (semanal), fim | Dias da semana, Até quando? (Sem fim, Fim do semestre, Escolher data), Horário, Salvar compromisso, Cancelar | Rolar o formulário | UC01 | §1 |
| 47 | Novo compromisso (só uma vez) | Data com date picker, Horário, Salvar | "Só uma vez" no formulário | UC01 | §1 |
| 48 | Sheet do compromisso | Nome, data e horário, "Toda terça"; Editar, Não vai ter nesse dia, Excluir | Tocar num compromisso recorrente da Semana (Compromisso no calendário) | UC01 | §5 |
| 49 | Sheet — Editar qual? | Só nesse dia / Desse dia em diante / Todas as semanas + Continuar | "Editar" no sheet | UC01 | §5 |
| 50 | Sheet — Excluir qual? | Os mesmos 3 escopos + Excluir | "Excluir" no sheet | UC01 | §5 |
| 51 | Sheet — dia cancelado | Pílula "Não vai ter nesse dia", "Liberei esse horário só nesse dia…", "Vai ter sim" (e o toast "Horário liberado") | "Não vai ter nesse dia" e tocar de novo no compromisso | UC01 | §5 |
| 52 | Editar só nesse dia | "Mudando só Ter, 11/11/2025…", nome fixo, Data, Horário, "Salvar só nesse dia" | Editar → Só nesse dia → Continuar | UC01 | §5 |
| 53 | Tarefas únicas | Campo + "+", grupos Hoje, Próximos dias, Sem data (e Feitas) | Painel (Tarefas únicas); no app, decisão MC9 | UC30 | — |
| 54 | Tarefas únicas — adicionando | "Quanto tempo leva?" (15 min, 30 min, 1h, 2h), "Quando?" (Hoje, Amanhã, Sem data, Escolher dia), "Adicionar tarefa" | Digitar no campo | UC30 | — |

## Observações

- **Atualização de 20/11/2026** (zip "…telas principais-project", exportação do projeto inteiro): mudou o `Bora App.dc.html`; o `Bora Telas.dc.html` só passou a ler os ícones de `./vendor/phosphor` (pasta nova, junto com um `README.md`). A tab bar voltou a ser **Hoje · Objetivos · Semana · Jardim** (o ícone do Jardim no protótipo é `leaf`; o app mantém `plant`, MC14). A página dedicada de Compromissos saiu: o cadastro é pelo "+ Compromisso" da Semana, e cada ocorrência abre um sheet com Editar / Não vai ter nesse dia / Excluir e o escopo (só nesse dia, desse dia em diante, todas as semanas). O protótipo não tem caminho para as Tarefas únicas (MC9). Nas capturas 46b, 47 e 52 o campo de horário aparece em 12 h (`07:00 PM`) porque é o `input type="time"` do navegador; o texto do protótipo usa 24 h ("19:00–20:00").

- **Atualização de 19/11/2026** (zip novo, só o `Bora App.dc.html` mudou): entrou o grupo **Acesso** (33–38: login, criar conta e a recuperação de senha em 3 passos), a aba **Compromissos** (41–42) e **Tarefas únicas** (43). A tab bar do protótipo passou a ser **Hoje · Objetivos · Semana · Compromissos**; o Jardim sai das abas e abre pelo **Broto do topo** (39), que aparece no Hoje e no Jardim junto da barra gamificada e do botão "A" do Perfil. Perfil, Jardim, Redefinir rotina, Idioma e Enviar sugestão não mudaram (04, 26–29). As capturas 33–43 mostram só a moldura (390×844, deviceScaleFactor 2), sem expandir a rolagem.
- **Login e cadastro agora têm design** (33–35). O **onboarding** continua sem design neste projeto: só aparece em `design/mobile/telas/` (Bora Telas do zip "Sistema do app Bora").
- O `Bora Telas.dc.html` desta pasta **não é igual** ao de `design/mobile/telas/source/`: este tem uma prancheta ("Tela 1 — Hoje, turno 1") e uma prop "energia" (pendente/baixa/média/alta) que só muda pelo editor do Claude Design. Capturei só o padrão ("pendente").
- `Bora App-print.dc.html` (versão para impressão) não foi capturado.
- `bora-data.js` traz os dados de exemplo do protótipo (usuário Arthur, objetivos, etapas, agenda): é referência útil para a modelagem.
