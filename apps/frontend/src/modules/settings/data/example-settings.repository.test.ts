import { describe, expect, it } from "vitest";
import { ExampleSettingsRepository } from "./example-settings.repository";

// Sem endpoint no contrato (docs/4-contrato-api.md): tema e e-mail diário ficam só nos dados de exemplo.
describe("preferências de exemplo (W26)", () => {
  it("começa como o protótipo: tema claro e e-mail diário ligado", async () => {
    expect(await new ExampleSettingsRepository().getPreferences()).toEqual({ theme: "light", dailyEmail: true, language: "pt" });
  });

  it("guarda o tema e o e-mail diário", async () => {
    const repo = new ExampleSettingsRepository();
    expect(await repo.setTheme("dark")).toEqual({ theme: "dark", dailyEmail: true, language: "pt" });
    expect(await repo.setDailyEmail(false)).toEqual({ theme: "dark", dailyEmail: false, language: "pt" });
    expect(await repo.getPreferences()).toEqual({ theme: "dark", dailyEmail: false, language: "pt" });
  });

  it("devolve cópias: mexer no retorno não muda o guardado", async () => {
    const repo = new ExampleSettingsRepository();
    const p = await repo.getPreferences();
    p.theme = "dark";
    expect((await repo.getPreferences()).theme).toBe("light");
  });

  it("guarda o idioma escolhido, sem traduzir nada (AT7)", async () => {
    const repo = new ExampleSettingsRepository();
    expect((await repo.setLanguage("es")).language).toBe("es");
    expect((await repo.getPreferences()).language).toBe("es");
  });

  it("guarda a sugestão só em memória (AT6: o backend vem depois)", async () => {
    const repo = new ExampleSettingsRepository();
    await repo.sendSuggestion("  Queria mudar a cor dos objetivos  ");
    expect(repo.suggestions).toEqual(["Queria mudar a cor dos objetivos"]);
  });
});
