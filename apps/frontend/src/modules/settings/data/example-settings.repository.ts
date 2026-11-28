import type { SettingsRepository } from "./settings.repository";
import type { Language, Preferences, Theme } from "./settings.types";

// example: preferências em memória, com os valores iniciais do protótipo (tema claro, e-mail diário ligado,
// português). Usada também com NEXT_PUBLIC_DATA_SOURCE=http, porque o backend não tem esses dados (ver afazeres).
export class ExampleSettingsRepository implements SettingsRepository {
  private prefs: Preferences = { theme: "light", dailyEmail: true, language: "pt" };

  /** Sugestões "enviadas" (AT6): ficam só aqui até existir o backend. */
  readonly suggestions: string[] = [];

  async getPreferences(): Promise<Preferences> {
    return { ...this.prefs };
  }

  async setTheme(theme: Theme): Promise<Preferences> {
    this.prefs = { ...this.prefs, theme };
    return { ...this.prefs };
  }

  async setDailyEmail(on: boolean): Promise<Preferences> {
    this.prefs = { ...this.prefs, dailyEmail: on };
    return { ...this.prefs };
  }

  async setLanguage(language: Language): Promise<Preferences> {
    this.prefs = { ...this.prefs, language };
    return { ...this.prefs };
  }

  async sendSuggestion(text: string): Promise<void> {
    this.suggestions.push(text.trim());
  }
}
