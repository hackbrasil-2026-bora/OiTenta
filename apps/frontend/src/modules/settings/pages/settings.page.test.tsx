import { act, cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { authRepository } from "@/modules/auth/data";
import { clock } from "@/modules/core/data/clock";
import { exampleBackend } from "@/modules/core/data/example-backend";
import { schedulingRepository } from "@/modules/scheduling/data";
import { settingsRepository } from "../data";
import SettingsPage from "./settings.page";

const push = vi.fn();
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push, replace: push }),
  useSearchParams: () => new URLSearchParams(),
  usePathname: () => "/configuracoes",
}));
beforeEach(async () => {
  exampleBackend.reset();
  await settingsRepository.setTheme("light");
  await settingsRepository.setDailyEmail(true);
  await settingsRepository.setLanguage("pt");
});
afterEach(() => {
  cleanup();
  push.mockReset();
  vi.restoreAllMocks();
});

const open = async () => {
  render(<SettingsPage />);
  await screen.findByText("Livre · 25h por semana");
};

describe("W26 Configurações", () => {
  it("mostra o usuário, o tema, a grade e o limite atuais", async () => {
    await open();
    expect(screen.getByRole("heading", { name: "Configurações", level: 1 })).toBeTruthy();
    expect(screen.getByText("Arthur · arthur@faculdade.edu.br")).toBeTruthy();
    expect(screen.getByRole("button", { name: "Claro" }).getAttribute("aria-pressed")).toBe("true");
    expect(screen.getByRole("slider", { name: "Limite diário" }).getAttribute("aria-valuenow")).toBe("180");
    expect(screen.getByText("3h")).toBeTruthy();
  });

  it("redefinir a rotina na grade grava a disponibilidade (PUT /scheduling/availability)", async () => {
    const save = vi.spyOn(schedulingRepository, "setAvailability");
    await open();
    fireEvent.mouseDown(screen.getByTitle("Seg 8h–9h"));
    fireEvent.mouseUp(window);
    expect(screen.getByText("Livre · 26h por semana")).toBeTruthy();
    await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
    const input = save.mock.calls[0][0];
    expect(input.dailyLimitMinutes).toBe(180);
    expect(input.windows).toContainEqual({ weekday: 0, startMinute: 480, endMinute: 540 });
    expect((await schedulingRepository.getAvailability()).availability.windows).toContainEqual({ weekday: 0, startMinute: 480, endMinute: 540 });
  });

  it("mudar o limite diário grava junto com a grade", async () => {
    const save = vi.spyOn(schedulingRepository, "setAvailability");
    await open();
    fireEvent.keyDown(screen.getByRole("slider", { name: "Limite diário" }), { key: "ArrowRight" });
    expect(screen.getByText("3h30")).toBeTruthy();
    await waitFor(() => expect(save).toHaveBeenCalledTimes(1));
    expect(save.mock.calls[0][0].dailyLimitMinutes).toBe(210);
    expect(save.mock.calls[0][0].windows).toHaveLength(8); // a grade do demo: 5 noites, sábado em 2 janelas, domingo
  });

  it("grade vazia não é gravada (o contrato exige ao menos uma janela)", async () => {
    const save = vi.spyOn(schedulingRepository, "setAvailability");
    await open();
    fireEvent.click(screen.getByRole("button", { name: "Limpar" }));
    expect(screen.getByText("Livre · 0h por semana")).toBeTruthy();
    await new Promise((r) => setTimeout(r, 700));
    expect(save).not.toHaveBeenCalled();
  });

  it("tema e e-mail diário ficam nas preferências de exemplo (sem endpoint)", async () => {
    await open();
    await act(async () => fireEvent.click(screen.getByRole("button", { name: "Escuro" })));
    expect(screen.getByRole("button", { name: "Escuro" }).getAttribute("aria-pressed")).toBe("true");
    const sw = screen.getByRole("switch", { name: "E-mail diário" });
    expect(sw.getAttribute("aria-checked")).toBe("true");
    await act(async () => fireEvent.click(sw));
    expect(sw.getAttribute("aria-checked")).toBe("false");
    expect(await settingsRepository.getPreferences()).toEqual({ theme: "dark", dailyEmail: false, language: "pt" });
  });

  it("a prévia do e-mail mostra o plano de hoje", async () => {
    await open();
    const preview = await screen.findByLabelText("Prévia do e-mail diário");
    expect(within(preview).getAllByText("Seu plano de hoje, Arthur")).toHaveLength(2);
    expect(within(preview).getByText("Segunda, 16 de novembro")).toBeTruthy();
    expect(await within(preview).findByText("Diagrama de casos de uso")).toBeTruthy();
    expect(within(preview).getByText("20:00")).toBeTruthy();
  });

  it("Sair encerra a sessão e volta para o login", async () => {
    const logout = vi.spyOn(authRepository, "logout");
    await open();
    await act(async () => fireEvent.click(screen.getByRole("button", { name: "Sair" })));
    expect(logout).toHaveBeenCalled();
    expect(push).toHaveBeenCalledWith("/entrar");
  });

  it("o relógio avançar durante uma edição pendente não desfaz a edição na tela", async () => {
    const getAvailability = vi.spyOn(schedulingRepository, "getAvailability");
    const now = vi.spyOn(clock, "now");
    await open();
    now.mockReturnValue("2026-11-16T22:41:00.000Z"); // virou o minuto
    fireEvent.mouseDown(screen.getByTitle("Seg 8h–9h"));
    fireEvent.mouseUp(window);
    await act(async () => {
      await new Promise((r) => setTimeout(r, 50));
    });
    expect(screen.getByText("Livre · 26h por semana")).toBeTruthy();
    expect(getAvailability).toHaveBeenCalledTimes(1);
  });

  it("dados do servidor que chegam depois de uma edição não sobrescrevem a edição", async () => {
    let release: () => void = () => {};
    const real = schedulingRepository.getAvailability.bind(schedulingRepository);
    vi.spyOn(schedulingRepository, "getAvailability").mockImplementation(
      () => new Promise((resolve) => { release = () => resolve(real()); }),
    );
    render(<SettingsPage />);
    await screen.findByText("Livre · 0h por semana");
    fireEvent.mouseDown(screen.getByTitle("Seg 8h–9h"));
    fireEvent.mouseUp(window);
    await act(async () => {
      release();
      await new Promise((r) => setTimeout(r, 50));
    });
    expect(screen.getByText("Livre · 1h por semana")).toBeTruthy();
  });

  describe("Sua conta (AT3)", () => {
    it("começa com o nome e o e-mail atuais e Salvar desligado", async () => {
      await open();
      expect((screen.getByLabelText("Nome") as HTMLInputElement).value).toBe("Arthur");
      expect((screen.getByLabelText("E-mail") as HTMLInputElement).value).toBe("arthur@faculdade.edu.br");
      expect(screen.queryByLabelText("Senha atual")).toBeNull();
      expect((screen.getByRole("button", { name: "Salvar conta" }) as HTMLButtonElement).disabled).toBe(true);
    });

    it("trocar o nome grava (PATCH /auth/me) e o topo mostra o nome novo", async () => {
      const save = vi.spyOn(authRepository, "updateProfile");
      await open();
      fireEvent.change(screen.getByLabelText("Nome"), { target: { value: "Arthur Lima" } });
      fireEvent.click(screen.getByRole("button", { name: "Salvar conta" }));
      await screen.findByText("Perfil atualizado.");
      expect(save).toHaveBeenCalledWith({ name: "Arthur Lima" });
      expect(screen.getByText("Arthur Lima · arthur@faculdade.edu.br")).toBeTruthy();
    });

    it("trocar o e-mail pede a senha atual e mostra o erro da senha errada", async () => {
      await open();
      fireEvent.change(screen.getByLabelText("E-mail"), { target: { value: "novo@bora.app" } });
      expect(screen.getByText("Pra trocar o e-mail, confirme sua senha atual.")).toBeTruthy();
      expect((screen.getByRole("button", { name: "Salvar conta" }) as HTMLButtonElement).disabled).toBe(true);
      fireEvent.change(screen.getByLabelText("Senha atual"), { target: { value: "errada" } });
      fireEvent.click(screen.getByRole("button", { name: "Salvar conta" }));
      expect(await screen.findByText("Senha atual incorreta.")).toBeTruthy();
      expect(push).not.toHaveBeenCalled();
    });

    it("com a senha certa, troca o e-mail", async () => {
      const save = vi.spyOn(authRepository, "updateProfile");
      await open();
      fireEvent.change(screen.getByLabelText("E-mail"), { target: { value: "novo@bora.app" } });
      fireEvent.change(screen.getByLabelText("Senha atual"), { target: { value: "bora1234" } });
      fireEvent.click(screen.getByRole("button", { name: "Salvar conta" }));
      await screen.findByText("Perfil atualizado.");
      expect(save).toHaveBeenCalledWith({ email: "novo@bora.app", currentPassword: "bora1234" });
      expect(screen.getByText("Arthur · novo@bora.app")).toBeTruthy();
    });
  });

  it("Idioma (AT7): escolher marca a opção e guarda", async () => {
    await open();
    const english = screen.getByRole("button", { name: "English" });
    expect(screen.getByRole("button", { name: "Português (Brasil)" }).getAttribute("aria-pressed")).toBe("true");
    fireEvent.click(english);
    await waitFor(() => expect(english.getAttribute("aria-pressed")).toBe("true"));
    expect((await settingsRepository.getPreferences()).language).toBe("en");
  });

  it("Enviar sugestão (AT6): Enviar só com texto e mostra a confirmação", async () => {
    const send = vi.spyOn(settingsRepository, "sendSuggestion");
    await open();
    const enviar = screen.getByRole("button", { name: "Enviar sugestão" }) as HTMLButtonElement;
    expect(enviar.disabled).toBe(true);
    fireEvent.change(screen.getByLabelText("O que podemos melhorar?"), { target: { value: "Queria mudar a cor" } });
    expect(enviar.disabled).toBe(false);
    fireEvent.click(enviar);
    expect(await screen.findByText("Sugestão enviada. Valeu! A gente lê tudo.")).toBeTruthy();
    expect(send).toHaveBeenCalledWith("Queria mudar a cor");
    expect((screen.getByLabelText("O que podemos melhorar?") as HTMLTextAreaElement).value).toBe("");
  });
});
