import { describe, expect, it } from "vitest";
import { GRID_HEIGHT, GRID_HOURS, blockGeometry, initialScrollTop, dayLoadLabel, freeRects, weekRangeLabel, blockDetail } from "./calendar.logic";

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

  it("grade do dia inteiro: 00h a 24h, 40px por hora", () => {
    expect(GRID_HOURS).toBe(24);
    expect(GRID_HEIGHT).toBe(960);
  });

  it("posição do bloco a partir da meia-noite", () => {
    // 20:00–21:30 e 10:00–10:15 (horário de Brasília)
    expect(blockGeometry("2026-11-16T23:00:00.000Z", "2026-11-17T00:30:00.000Z", TZ)).toEqual({ top: 801, height: 57 });
    expect(blockGeometry("2026-11-21T13:00:00.000Z", "2026-11-21T13:15:00.000Z", TZ)).toEqual({ top: 401, height: 20 });
    // 00:00–00:30 e 06:00–06:30
    expect(blockGeometry("2026-11-24T03:00:00.000Z", "2026-11-24T03:30:00.000Z", TZ)).toEqual({ top: 1, height: 20 });
    expect(blockGeometry("2026-11-24T09:00:00.000Z", "2026-11-24T09:30:00.000Z", TZ)).toEqual({ top: 241, height: 20 });
  });

  it("bloco que passa da meia-noite para no fim do dia", () => {
    // 23:00–01:00: só cabe 1h (40px) até 24h
    expect(blockGeometry("2026-11-25T02:00:00.000Z", "2026-11-25T04:00:00.000Z", TZ)).toEqual({ top: 921, height: 37 });
  });

  it("grade abre rolada até 1h antes da hora atual, com o rótulo da hora inteiro", () => {
    expect(initialScrollTop(19 * 60 + 40)).toBe(708);
    expect(initialScrollTop(8 * 60)).toBe(268);
    expect(initialScrollTop(60)).toBe(0);
    expect(initialScrollTop(0)).toBe(0);
  });

  it("faixas livres a partir das janelas do dia", () => {
    expect(freeRects([{ weekday: 5, startMinute: 540, endMinute: 720 }, { weekday: 5, startMinute: 840, endMinute: 1080 }], 5)).toEqual([
      { top: 360, height: 120 },
      { top: 560, height: 160 },
    ]);
    expect(freeRects([{ weekday: 1, startMinute: 0, endMinute: 1440 }], 1)).toEqual([{ top: 0, height: 960 }]);
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
