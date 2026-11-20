/// Caminhos das rotas do app (go_router). As telas navegam só por estes nomes.
class AppRoutes {
  const AppRoutes._();

  static const login = '/entrar';
  static const register = '/cadastro';
  static const onboarding = '/onboarding';
  static const today = '/hoje';
  static const goals = '/objetivos';

  /// Chat do novo objetivo (M13–M14): a resposta abre o [newGoal] preenchido.
  static const goalChat = '/objetivos/chat';

  /// Etapas editáveis (M15): vazia (P20) ou com a resposta da IA no `extra`.
  static const newGoal = '/objetivos/novo';
  static const manualTask = '/objetivos/manual';
  static const trail = '/objetivos/trilha';
  static const week = '/semana';
  static const garden = '/jardim';

  /// Novo compromisso (M46/M47), aberto pelo "+ Compromisso" da Semana.
  static const commitmentNew = '/semana/compromisso';

  /// Editar compromisso (M46, M52): `/semana/compromisso/<id>`.
  static String commitmentEdit(String id) => '$commitmentNew/$id';

  /// Tarefas únicas (M53–M54), pelo botão do Hoje (MC9).
  static const singleTasks = '/tarefas';

  /// Recuperação de senha (M36): placeholder pela MP4.
  static const forgotPassword = '/entrar/esqueci';

  /// Perfil (M26), aberto pela inicial do topo, e as subtelas (M27, M29).
  static const profile = '/perfil';
  static const profileRoutine = '/perfil/rotina';
  static const profileSuggestion = '/perfil/sugestao';
  static const ramp = '/rampa';
  static const warmup = '/rampa/aquecer';
  static const challenge = '/rampa/desafio';
  static const micro = '/rampa/micro';
  static const focus = '/rampa/foco';
  static const log = '/rampa/registro';
  static const celebration = '/rampa/celebracao';

  /// Trilha de um objetivo: `/objetivos/trilha/<goalId>`.
  static String trailOf(String goalId) => '$trail/$goalId';

  /// Tela de cada degrau da rampa, na ordem (aquecer, desafio, micro, foco, registrar).
  static const rampSteps = [warmup, challenge, micro, focus, log];
}
