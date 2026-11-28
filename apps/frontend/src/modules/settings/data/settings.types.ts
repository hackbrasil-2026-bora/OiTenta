// Preferências da tela W26 (AppConfig.dc.html) que o contrato não cobre: tema, e-mail diário e idioma.
export type Theme = "light" | "dark";

/** Idiomas do seletor (AT7). Só visual: o app continua em português. */
export type Language = "pt" | "en" | "es";

export interface Preferences {
  theme: Theme;
  dailyEmail: boolean;
  language: Language;
}
