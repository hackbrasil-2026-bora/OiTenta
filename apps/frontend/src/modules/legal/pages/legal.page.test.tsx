import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import { LEGAL_CONTACT, PRIVACY, TERMS } from "../data/legal-texts";
import LegalPage from "./legal.page";

afterEach(cleanup);

describe("Termos de uso e Política de privacidade", () => {
  it.each([
    ["termos", TERMS],
    ["privacidade", PRIVACY],
  ] as const)("a página de %s mostra o título, o aviso de rascunho, as seções e o contato", (_, doc) => {
    render(<LegalPage doc={doc} />);
    expect(screen.getByRole("heading", { level: 1, name: doc.title })).toBeTruthy();
    expect(screen.getByText("Versão preliminar: este texto ainda está em revisão.")).toBeTruthy();
    expect(screen.getByText(`Atualizado em ${doc.updated}`)).toBeTruthy();
    for (const s of doc.sections) expect(screen.getByRole("heading", { level: 2, name: s.heading })).toBeTruthy();
    expect(screen.getAllByText(new RegExp(LEGAL_CONTACT)).length).toBeGreaterThan(0);
  });

  it("cada página leva para a outra", () => {
    render(<LegalPage doc={TERMS} />);
    expect(screen.getByRole("link", { name: "Política de privacidade" }).getAttribute("href")).toBe("/privacidade");
    cleanup();
    render(<LegalPage doc={PRIVACY} />);
    expect(screen.getByRole("link", { name: "Termos de uso" }).getAttribute("href")).toBe("/termos");
  });

  it("a política diz que apagar a conta apaga todos os dados e cita a LGPD (crianças)", () => {
    render(<LegalPage doc={PRIVACY} />);
    expect(screen.getByText(/apagamos de vez a conta e todos os dados dela/)).toBeTruthy();
    expect(screen.getByText(/menos de 12 anos só são tratados com o consentimento/)).toBeTruthy();
  });
});
