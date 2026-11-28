import type { Language, Preferences, Theme } from "./settings.types";

// Fronteira da tela de configurações com as preferências do usuário. Não há endpoint no contrato
// (docs/4-contrato-api.md): hoje só existe a implementação de exemplo; quando houver, entra uma HTTP.
export interface SettingsRepository {
  getPreferences(): Promise<Preferences>;
  setTheme(theme: Theme): Promise<Preferences>;
  setDailyEmail(on: boolean): Promise<Preferences>;
  /** AT7: só guarda a escolha; a tradução vem depois. */
  setLanguage(language: Language): Promise<Preferences>;
  /** AT6: "Enviar sugestão" só visual; o POST /feedback vem depois. */
  sendSuggestion(text: string): Promise<void>;
}
