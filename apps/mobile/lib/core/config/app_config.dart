/// Configuração por ambiente, lida de `--dart-define-from-file=env/<ambiente>.json`.
///
/// Único lugar do app que conhece a URL do backend (regra em
/// `.agents/rules/mobile-flutter.md`).
class AppConfig {
  const AppConfig._();

  static const String envName = String.fromEnvironment(
    'ENV_NAME',
    defaultValue: 'local-simulator',
  );

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:4000',
  );

  /// De onde vêm os dados: `http` (backend real, padrão) ou `sample`
  /// (dados de exemplo do protótipo, sem rede).
  static const String dataSource = String.fromEnvironment(
    'DATA_SOURCE',
    defaultValue: 'http',
  );

  /// Mostra "Entrar direto como Arthur (demo)" no login (MP5): `true` em
  /// `local-*` e `developer`, `false` em `prod`.
  static const bool showDemo = bool.fromEnvironment('SHOW_DEMO');

  /// Último dia do semestre, usado no "Fim do semestre" do formulário de
  /// compromisso (MC3). Atualizar a cada semestre.
  static const String semesterEnd = String.fromEnvironment(
    'SEMESTER_END',
    defaultValue: '2026-12-12',
  );
}
