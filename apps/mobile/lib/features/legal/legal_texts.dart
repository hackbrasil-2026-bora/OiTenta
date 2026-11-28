// Termos de uso e Política de privacidade (decisão do dono do produto, 28/11/2026).
// VERSÃO PRELIMINAR: precisa de revisão do time (e, de preferência, jurídica) antes do lançamento.
// GERADO por apps/mobile/tool/legal/generate_legal_texts.sh a partir de
// apps/frontend/src/modules/legal/data/legal-texts.ts. Não edite aqui: mude lá e gere de novo.

/// Uma seção dos textos legais.
class LegalSection {
  const LegalSection({required this.heading, required this.paragraphs});

  final String heading;
  final List<String> paragraphs;
}

/// Um texto legal (Termos de uso ou Política de privacidade).
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.updated,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String updated;
  final String intro;
  final List<LegalSection> sections;
}

const legalContact = 'contato@bora.app';
const legalUpdated = '28 de novembro de 2026';
const legalDraftNotice = 'Versão preliminar: este texto ainda está em revisão.';

const termsOfUse = LegalDocument(
  title: 'Termos de uso',
  updated: legalUpdated,
  intro:
      'Estes termos explicam as regras para usar o Bora. Ao criar uma conta, você concorda com eles. Se não concordar, não use o Bora.',
  sections: [
    LegalSection(
      heading: '1. O que é o Bora',
      paragraphs: [
        'O Bora é um aplicativo de planejamento que ajuda quem trava ao começar tarefas: divide objetivos em etapas, encaixa as etapas no seu calendário e guia o início de cada sessão de foco.',
        'O Bora é um protótipo (MVP) criado pela equipe do Bora para o Hack Brasil 2026. É gratuito, está em desenvolvimento e pode mudar, ficar fora do ar ou ser encerrado a qualquer momento.',
      ],
    ),
    LegalSection(
      heading: '2. Quem pode usar',
      paragraphs: [
        'Não há idade mínima. Crianças com menos de 12 anos só podem usar o Bora com o consentimento de um dos pais ou responsável, que deve criar ou autorizar a conta, como pede a Lei Geral de Proteção de Dados (LGPD, art. 14). Adolescentes de 12 a 17 anos devem usar com o conhecimento dos responsáveis.',
      ],
    ),
    LegalSection(
      heading: '3. Sua conta',
      paragraphs: [
        'Use um e-mail que seja seu e guarde a sua senha. Você é responsável pelo que for feito com a sua conta.',
        'Você pode trocar o nome, o e-mail e a senha, sair e apagar a conta quando quiser, no Perfil (app) ou nas Configurações (site).',
      ],
    ),
    LegalSection(
      heading: '4. Uso permitido',
      paragraphs: [
        'Não use o Bora para nada ilegal, não tente acessar a conta de outra pessoa e não tente prejudicar o funcionamento do serviço.',
        'Podemos suspender ou encerrar uma conta que descumpra estes termos.',
      ],
    ),
    LegalSection(
      heading: '5. Sugestões da inteligência artificial',
      paragraphs: [
        'As etapas, as estimativas de tempo e o plano são sugestões automáticas e podem ter erros. Confira e ajuste o que precisar: a decisão final é sua.',
        'O Bora não é um serviço de saúde. Ele usa técnicas estudadas pela psicologia, mas não faz diagnóstico nem substitui acompanhamento médico ou psicológico, inclusive para TDAH.',
      ],
    ),
    LegalSection(
      heading: '6. Funções ainda em teste',
      paragraphs: [
        'Algumas opções já aparecem, mas ainda não funcionam por completo: o e-mail diário, o lembrete da rampa, o idioma, o bloqueio de apps e o envio de sugestões. Elas vão ser ativadas aos poucos.',
      ],
    ),
    LegalSection(
      heading: '7. Limites de responsabilidade',
      paragraphs: [
        'Fazemos o possível para o Bora funcionar bem, mas ele é oferecido como está, sem garantia de que vai estar sempre disponível ou sem erros. Não nos responsabilizamos por prazos, provas ou compromissos perdidos.',
      ],
    ),
    LegalSection(
      heading: '8. Mudanças nestes termos',
      paragraphs: [
        'Podemos mudar estes termos. Quando a mudança for importante, avisamos no app ou no site antes de ela valer.',
      ],
    ),
    LegalSection(
      heading: '9. Lei e contato',
      paragraphs: [
        'Estes termos seguem as leis do Brasil.',
        'Dúvidas? Escreva para contato@bora.app.',
      ],
    ),
  ],
);

const privacyPolicy = LegalDocument(
  title: 'Política de privacidade',
  updated: legalUpdated,
  intro:
      'Esta política explica quais dados o Bora guarda, para que usa e quais são os seus direitos, de acordo com a Lei Geral de Proteção de Dados (LGPD, Lei 13.709/2018).',
  sections: [
    LegalSection(
      heading: '1. Quem cuida dos seus dados',
      paragraphs: [
        'A equipe do Bora (Hack Brasil 2026) é a controladora dos seus dados. Para qualquer assunto sobre eles, escreva para contato@bora.app.',
      ],
    ),
    LegalSection(
      heading: '2. Quais dados guardamos',
      paragraphs: [
        'Conta: nome, e-mail, senha (guardada cifrada, nunca em texto) e fuso horário.',
        'Planejamento: seus objetivos, etapas, prazos, tarefas únicas, horários livres, limite por dia e compromissos.',
        'Uso: as sessões de foco, com a energia e o tempo disponível que você informa, o início, o fim, os minutos focados e o resultado.',
        'Não pedimos localização, contatos, fotos nem microfone, e não usamos ferramentas de rastreamento, publicidade ou análise de comportamento.',
      ],
    ),
    LegalSection(
      heading: '3. Para que usamos',
      paragraphs: [
        'Para fazer o Bora funcionar: entrar na sua conta, montar e reorganizar o seu plano, mostrar o seu progresso e guiar as sessões de foco. A base legal é a execução do serviço que você pediu ao criar a conta (LGPD, art. 7º, V).',
        'Não vendemos seus dados e não usamos seus dados para publicidade.',
      ],
    ),
    LegalSection(
      heading: '4. Inteligência artificial',
      paragraphs: [
        'Quando você descreve um objetivo para o Bora sugerir as etapas, esse texto é enviado a um serviço de inteligência artificial. Não enviamos seu nome nem seu e-mail junto. Evite escrever dados sensíveis (como saúde) na descrição.',
        'O texto não fica guardado nos registros do nosso servidor. O fornecedor da inteligência artificial ainda está em definição; quando for escolhido, ele vai aparecer nesta política.',
      ],
    ),
    LegalSection(
      heading: '5. Com quem compartilhamos',
      paragraphs: [
        'Só com os serviços necessários para o Bora funcionar: a hospedagem do site e do servidor, o banco de dados e o serviço de inteligência artificial. Alguns desses serviços podem ficar fora do Brasil; nesse caso, exigimos proteção compatível com a LGPD.',
        'Também podemos compartilhar dados se a lei ou uma ordem judicial exigir.',
      ],
    ),
    LegalSection(
      heading: '6. Por quanto tempo',
      paragraphs: [
        'Guardamos seus dados enquanto a sua conta existir. Quando você apaga a conta, apagamos de vez a conta e todos os dados dela: objetivos, etapas, plano, sessões de foco, rotina e compromissos.',
      ],
    ),
    LegalSection(
      heading: '7. Segurança',
      paragraphs: [
        'A senha é guardada cifrada, e só você acessa os seus dados, com o seu login. No site, o acesso fica salvo no seu navegador até você sair; no app, até você fechar o aplicativo.',
      ],
    ),
    LegalSection(
      heading: '8. Seus direitos',
      paragraphs: [
        'Pela LGPD (art. 18), você pode: saber quais dados temos, corrigir dados, pedir uma cópia, apagar os dados e a conta, e saber com quem compartilhamos.',
        'Você mesmo corrige o nome e o e-mail no Perfil ou nas Configurações, e apaga a conta na Zona de risco. Para os outros pedidos, escreva para contato@bora.app.',
      ],
    ),
    LegalSection(
      heading: '9. Crianças e adolescentes',
      paragraphs: [
        'Dados de crianças com menos de 12 anos só são tratados com o consentimento de um dos pais ou responsável. Se você é responsável e acha que uma criança usou o Bora sem consentimento, escreva para nós e apagamos a conta.',
      ],
    ),
    LegalSection(
      heading: '10. Mudanças nesta política',
      paragraphs: [
        'Podemos mudar esta política. Quando a mudança for importante, avisamos no app ou no site antes de ela valer.',
      ],
    ),
  ],
);
