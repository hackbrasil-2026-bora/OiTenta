import { describe, expect, it } from "vitest";
import { blockGeometry, dayLoadLabel, freeRects, gridRange, weekRangeLabel, blockDetail } from "./calendar.logic";

const TZ = "America/Sao_Paulo";

describe("calendário semana — Execução (W15)", () => {
  it("rótulo da semana", () => {
    expect(weekRangeLabel("2026-11-16")).toBe("16–22 de novembro");
    expect(weekRangeLabel("2026-11-30")).toBe("30 nov – 6 dez");
  });

  it("carga do dia: \"3h de 3h\" ou \"livre\"", () => {
    expect(dayLoadLabel(180, 180)).toBe("3h de 3h");
    expect(dayLoadLabel(165, 180)).toBe("2h45 de 3h");
    expect(dayLoadLabel(0, 180)).toBe("livre");
  });

  it("posição do bloco: 40px por hora a partir das 08h", () => {
    expect(blockGeometry("2026-11-16T23:00:00.000Z", "2026-11-17T00:30:00.000Z", TZ)).toEqual({ top: 481, height: 57 });
    expect(blockGeometry("2026-11-21T13:00:00.000Z", "2026-11-21T13:15:00.000Z", TZ)).toEqual({ top: 81, height: 20 });
  });

  it("faixas livres a partir das janelas do dia", () => {
    expect(freeRects([{ weekday: 5, startMinute: 540, endMinute: 720 }, { weekday: 5, startMinute: 840, endMinute: 1080 }], 5)).toEqual([
      { top: 40, height: 120 },
      { top: 240, height: 160 },
    ]);
  });

  it("faixa de horas: 08h–23h por padrão", () => {
    expect(gridRange([], [], TZ)).toEqual({ firstMinute: 480, hours: 15 });
  });

  it("faixa de horas: começa antes das 08h quando há janela livre ou bloco mais cedo", () => {
    expect(gridRange([{ weekday: 0, startMinute: 360, endMinute: 1380 }], [], TZ)).toEqual({ firstMinute: 360, hours: 17 });
    // bloco 07:30–09:30 (horário de Brasília) sem janela cedo
    expect(gridRange([], [{ start: "2026-11-24T10:30:00.000Z", end: "2026-11-24T12:30:00.000Z" }], TZ)).toEqual({ firstMinute: 420, hours: 16 });
  });

  it("faixa de horas: termina depois das 23h quando a janela ou o bloco passa, até 24h", () => {
    expect(gridRange([{ weekday: 2, startMinute: 600, endMinute: 1410 }], [], TZ)).toEqual({ firstMinute: 480, hours: 16 });
    // bloco 23:30–00:30 vai até o fim do dia
    expect(gridRange([], [{ start: "2026-11-25T02:30:00.000Z", end: "2026-11-25T03:30:00.000Z" }], TZ)).toEqual({ firstMinute: 480, hours: 16 });
  });

  it("posição do bloco e faixas livres a partir do início da grade", () => {
    // 06:00–06:30 numa grade que começa às 06h
    expect(blockGeometry("2026-11-24T09:00:00.000Z", "2026-11-24T09:30:00.000Z", TZ, 360)).toEqual({ top: 1, height: 20 });
    expect(freeRects([{ weekday: 1, startMinute: 360, endMinute: 1380 }], 1, 360)).toEqual([{ top: 0, height: 680 }]);
  });

  it("detalhe do bloco (W16)", () => {
    expect(
      blockDetail(
        { start: "2026-11-16T23:00:00.000Z", end: "2026-11-17T00:30:00.000Z" },
        "2026-11-16",
        TZ,
      ),
    ).toEqual({ when: "Hoje, 16/11 · 20:00–21:30", duration: "1h30" });
    expect(
      blockDetail({ start: "2026-11-18T23:00:00.000Z", end: "2026-11-18T23:30:00.000Z" }, "2026-11-16", TZ).when,
    ).toBe("Qua, 18/11 · 20:00–20:30");
  });
});
