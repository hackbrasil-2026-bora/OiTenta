import { ValidationException } from "@oitenta/shared";
import { Commitment, CommitmentException } from "../../../src";
import { makeCommitment, makeCommitmentState, USER_A } from "../../mock";

function getValidationMessages(callback: () => void): string[] {
  try {
    callback();
    return [];
  } catch (error) {
    return (error as ValidationException).errors.map((item) => item.message);
  }
}

const TUESDAY_11 = "2025-11-11";
const WEDNESDAY_12 = "2025-11-12";

/** Recorrente iniciado na segunda 03/11/2025, toda segunda e quarta. */
function makeSeries(exceptions: CommitmentException[] = []): Commitment {
  return makeCommitment({
    startDate: "2025-11-03",
    recurrence: { weekdays: [0, 2] },
    exceptions,
  });
}

describe("Commitment", () => {
  test("deve expor os getters", () => {
    const commitment = makeCommitment({
      exceptions: [{ date: TUESDAY_11, type: "cancelled" }],
    });

    expect(commitment.userId).toBe(USER_A);
    expect(commitment.title).toBe("Aula de violão");
    expect(commitment.category).toBe("pessoal");
    expect(commitment.kind).toBe("commitment");
    expect(commitment.startDate).toBe("2025-11-04");
    expect(commitment.startMinute).toBe(1140);
    expect(commitment.endMinute).toBe(1200);
    expect(commitment.recurrence).toEqual({ weekdays: [1] });
    expect(commitment.exceptions).toEqual([{ date: TUESDAY_11, type: "cancelled" }]);
  });

  test("cenario 1: recorrente valido (Aula de violao, pessoal, ter, 19:00-20:00) passa no validate", () => {
    expect(() => makeCommitment().validate()).not.toThrow();
  });

  test("evento unico (sem recorrencia) valido passa no validate", () => {
    expect(() => makeCommitment({ recurrence: null }).validate()).not.toThrow();
  });

  test("deve permitir existir invalido ate chamar validate (lazy)", () => {
    const commitment = makeCommitment({ title: "" });

    expect(commitment.title).toBe("");
    expect(() => commitment.validate()).toThrow(ValidationException);
  });

  test("deve acusar campos obrigatorios vazios", () => {
    const commitment = makeCommitment({
      userId: "",
      title: " ",
      category: "" as unknown as "aula",
      startDate: "",
    });

    expect(getValidationMessages(() => commitment.validate())).toEqual([
      "commitment.userId.required",
      "commitment.title.required",
      "commitment.category.required",
      "commitment.startDate.required",
    ]);
  });

  test("cenario 2: titulo 'A' ou com 81 caracteres -> commitment.title", () => {
    const short = makeCommitment({ title: "A" });
    const long = makeCommitment({ title: "a".repeat(81) });

    expect(getValidationMessages(() => short.validate())).toEqual([
      "commitment.title.range.length",
    ]);
    expect(getValidationMessages(() => long.validate())).toEqual([
      "commitment.title.range.length",
    ]);
  });

  test("cenario 2: o tamanho do titulo e medido sem os espacos das pontas (2 e 80 passam)", () => {
    expect(() => makeCommitment({ title: "  Yo  " }).validate()).not.toThrow();
    expect(() => makeCommitment({ title: ` ${"a".repeat(80)} ` }).validate()).not.toThrow();
    expect(getValidationMessages(() => makeCommitment({ title: " A " }).validate())).toEqual([
      "commitment.title.range.length",
    ]);
  });

  test("cenario 3: category 'lazer' -> commitment.category", () => {
    const commitment = makeCommitment({ category: "lazer" as unknown as "aula" });

    expect(getValidationMessages(() => commitment.validate())).toEqual([
      "commitment.category.in",
    ]);
  });

  test("as quatro categorias do formulario sao validas", () => {
    for (const category of ["aula", "trabalho", "saude", "pessoal"] as const) {
      expect(() => makeCommitment({ category }).validate()).not.toThrow();
    }
  });

  test("deve rejeitar kind diferente de commitment", () => {
    const commitment = makeCommitment({ kind: "task" as unknown as "commitment" });

    expect(getValidationMessages(() => commitment.validate())).toEqual([
      "commitment.kind.in",
    ]);
  });

  test("deve rejeitar startDate que nao e data local YYYY-MM-DD ou inexistente", () => {
    const withTime = makeCommitment({ startDate: "2025-11-04T08:00", recurrence: null });
    const missing = makeCommitment({ startDate: "2025-02-30", recurrence: null });

    expect(getValidationMessages(() => withTime.validate())).toEqual([
      "commitment.startDate.local.date",
    ]);
    expect(getValidationMessages(() => missing.validate())).toEqual([
      "commitment.startDate.local.date",
    ]);
  });

  test("cenario 4: startMinute 482 (nao multiplo de 5) -> erro", () => {
    const commitment = makeCommitment({ startMinute: 482, endMinute: 580 });

    expect(getValidationMessages(() => commitment.validate())).toEqual([
      "commitment.startMinute.multiple.of",
    ]);
  });

  test("cenario 4: 08:00-09:40 (480-580) e valido (MC2)", () => {
    expect(() => makeCommitment({ startMinute: 480, endMinute: 580 }).validate()).not.toThrow();
  });

  test("cenario 5: endMinute <= startMinute -> erro", () => {
    const equal = makeCommitment({ startMinute: 600, endMinute: 600 });
    const before = makeCommitment({ startMinute: 600, endMinute: 540 });

    expect(getValidationMessages(() => equal.validate())).toEqual([
      "commitment.endMinute.after.start",
    ]);
    expect(getValidationMessages(() => before.validate())).toEqual([
      "commitment.endMinute.after.start",
    ]);
  });

  test("cenario 5: endMinute 1445 (cruza a meia-noite) -> erro; 1440 e o limite", () => {
    const after = makeCommitment({ startMinute: 1380, endMinute: 1445 });

    expect(getValidationMessages(() => after.validate())).toEqual([
      "commitment.endMinute.range.value",
    ]);
    expect(() => makeCommitment({ startMinute: 1380, endMinute: 1440 }).validate()).not.toThrow();
  });

  test("startMinute fora de 0-1435, nao inteiro ou ausente -> erro", () => {
    const late = makeCommitment({ startMinute: 1440, endMinute: 1440 });
    const fraction = makeCommitment({ startMinute: 2.5, endMinute: 60 });
    const missing = makeCommitment({
      startMinute: undefined as unknown as number,
      endMinute: undefined as unknown as number,
    });

    expect(getValidationMessages(() => late.validate())).toEqual([
      "commitment.startMinute.range.value",
      "commitment.endMinute.after.start",
    ]);
    expect(getValidationMessages(() => fraction.validate())).toEqual([
      "commitment.startMinute.integer",
      "commitment.startMinute.multiple.of",
    ]);
    expect(getValidationMessages(() => missing.validate())).toEqual([
      "commitment.startMinute.required",
      "commitment.endMinute.required",
    ]);
  });

  test("cenario 6: weekdays [], [1, 1] ou [7] -> erro", () => {
    const empty = makeCommitment({ recurrence: { weekdays: [] } });
    const repeated = makeCommitment({ recurrence: { weekdays: [1, 1] } });
    const invalid = makeCommitment({ recurrence: { weekdays: [7] } });

    expect(getValidationMessages(() => empty.validate())).toEqual([
      "commitment.recurrence.weekdays.required",
    ]);
    expect(getValidationMessages(() => repeated.validate())).toEqual([
      "commitment.recurrence.weekdays.unique.items",
    ]);
    expect(getValidationMessages(() => invalid.validate())).toEqual([
      "commitment.recurrence.weekdays.range.value",
    ]);
  });

  test("cenario 7: endDate < startDate -> erro; endDate invalida tambem", () => {
    const before = makeCommitment({ recurrence: { weekdays: [1], endDate: "2025-11-03" } });
    const invalid = makeCommitment({ recurrence: { weekdays: [1], endDate: "05/11/2025" } });

    expect(getValidationMessages(() => before.validate())).toEqual([
      "commitment.recurrence.endDate.before.start",
    ]);
    expect(getValidationMessages(() => invalid.validate())).toEqual([
      "commitment.recurrence.endDate.local.date",
    ]);
  });

  test("cenario 7: endDate igual ao startDate e valida", () => {
    const commitment = makeCommitment({ recurrence: { weekdays: [1], endDate: "2025-11-04" } });

    expect(() => commitment.validate()).not.toThrow();
  });

  describe("exceptions", () => {
    test("cancelled e moved em ocorrencias validas passam no validate", () => {
      const commitment = makeCommitment({
        exceptions: [
          { date: TUESDAY_11, type: "cancelled" },
          {
            date: "2025-11-18",
            type: "moved",
            newDate: "2025-11-19",
            startMinute: 1200,
            endMinute: 1260,
          },
        ],
      });

      expect(() => commitment.validate()).not.toThrow();
    });

    test("cenario 8: cancelled numa quarta de um compromisso so de terca -> not.occurrence", () => {
      const commitment = makeCommitment({
        exceptions: [{ date: WEDNESDAY_12, type: "cancelled" }],
      });

      expect(getValidationMessages(() => commitment.validate())).toEqual([
        "commitment.exceptions.date.not.occurrence",
      ]);
    });

    test("cenario 8: data antes do inicio ou depois do fim da serie nao e ocorrencia", () => {
      const series = makeCommitmentState({ recurrence: { weekdays: [1], endDate: "2025-11-18" } });
      const beforeStart = new Commitment({
        ...series,
        exceptions: [{ date: "2025-10-28", type: "cancelled" }],
      });
      const afterEnd = new Commitment({
        ...series,
        exceptions: [{ date: "2025-11-25", type: "cancelled" }],
      });

      expect(getValidationMessages(() => beforeStart.validate())).toEqual([
        "commitment.exceptions.date.not.occurrence",
      ]);
      expect(getValidationMessages(() => afterEnd.validate())).toEqual([
        "commitment.exceptions.date.not.occurrence",
      ]);
    });

    test("cenario 8: no compromisso unico, so a propria startDate e ocorrencia", () => {
      const ok = makeCommitment({
        recurrence: null,
        exceptions: [{ date: "2025-11-04", type: "cancelled" }],
      });
      const other = makeCommitment({
        recurrence: null,
        exceptions: [{ date: TUESDAY_11, type: "cancelled" }],
      });

      expect(() => ok.validate()).not.toThrow();
      expect(getValidationMessages(() => other.validate())).toEqual([
        "commitment.exceptions.date.not.occurrence",
      ]);
    });

    test("data da excecao ausente ou mal formada -> erro de data local", () => {
      const missing = makeCommitment({
        exceptions: [{ date: "", type: "cancelled" }],
      });
      const invalid = makeCommitment({
        exceptions: [{ date: "11/11/2025", type: "cancelled" }],
      });

      expect(getValidationMessages(() => missing.validate())).toEqual([
        "commitment.exceptions.date.required",
      ]);
      expect(getValidationMessages(() => invalid.validate())).toEqual([
        "commitment.exceptions.date.local.date",
      ]);
    });

    test("type fora de cancelled|moved -> erro", () => {
      const commitment = makeCommitment({
        exceptions: [{ date: TUESDAY_11, type: "skipped" as unknown as "cancelled" }],
      });

      expect(getValidationMessages(() => commitment.validate())).toEqual([
        "commitment.exceptions.type.in",
      ]);
    });

    test("cenario 9: moved sem newDate -> erro", () => {
      const commitment = makeCommitment({
        exceptions: [{ date: TUESDAY_11, type: "moved", startMinute: 1200, endMinute: 1260 }],
      });

      expect(getValidationMessages(() => commitment.validate())).toEqual([
        "commitment.exceptions.newDate.required",
      ]);
    });

    test("cenario 9: moved com endMinute <= startMinute -> erro", () => {
      const commitment = makeCommitment({
        exceptions: [
          {
            date: TUESDAY_11,
            type: "moved",
            newDate: WEDNESDAY_12,
            startMinute: 1200,
            endMinute: 1200,
          },
        ],
      });

      expect(getValidationMessages(() => commitment.validate())).toEqual([
        "commitment.exceptions.endMinute.after.start",
      ]);
    });

    test("moved segue as mesmas regras de horario (multiplo de 5, ate 1440, obrigatorio)", () => {
      const commitment = makeCommitment({
        exceptions: [
          {
            date: TUESDAY_11,
            type: "moved",
            newDate: "2025-13-01",
            startMinute: 1202,
            endMinute: 1445,
          },
        ],
      });
      const missing = makeCommitment({
        exceptions: [{ date: TUESDAY_11, type: "moved", newDate: WEDNESDAY_12 }],
      });

      expect(getValidationMessages(() => commitment.validate())).toEqual([
        "commitment.exceptions.newDate.local.date",
        "commitment.exceptions.startMinute.multiple.of",
        "commitment.exceptions.endMinute.range.value",
      ]);
      expect(getValidationMessages(() => missing.validate())).toEqual([
        "commitment.exceptions.startMinute.required",
        "commitment.exceptions.endMinute.required",
      ]);
    });

    test("cancelled nao aceita newDate, startMinute nem endMinute", () => {
      const commitment = makeCommitment({
        exceptions: [
          {
            date: TUESDAY_11,
            type: "cancelled",
            newDate: WEDNESDAY_12,
            startMinute: 1200,
            endMinute: 1260,
          },
        ],
      });

      expect(getValidationMessages(() => commitment.validate())).toEqual([
        "commitment.exceptions.newDate.not.allowed",
        "commitment.exceptions.startMinute.not.allowed",
        "commitment.exceptions.endMinute.not.allowed",
      ]);
    });

    test("cenario 10: duas excecoes na mesma data -> commitment.exceptions.date.unique", () => {
      const commitment = makeCommitment({
        exceptions: [
          { date: TUESDAY_11, type: "cancelled" },
          {
            date: TUESDAY_11,
            type: "moved",
            newDate: WEDNESDAY_12,
            startMinute: 1200,
            endMinute: 1260,
          },
        ],
      });

      expect(getValidationMessages(() => commitment.validate())).toEqual([
        "commitment.exceptions.date.unique",
      ]);
    });
  });

  describe("occursOn", () => {
    test("recorrente: dia da semana dentro de startDate..endDate", () => {
      const commitment = makeCommitment({ recurrence: { weekdays: [1], endDate: "2025-11-18" } });

      expect(commitment.occursOn("2025-11-04")).toBe(true);
      expect(commitment.occursOn("2025-11-18")).toBe(true);
      expect(commitment.occursOn("2025-10-28")).toBe(false);
      expect(commitment.occursOn("2025-11-25")).toBe(false);
      expect(commitment.occursOn(WEDNESDAY_12)).toBe(false);
    });

    test("unico: so na startDate", () => {
      const commitment = makeCommitment({ recurrence: null });

      expect(commitment.occursOn("2025-11-04")).toBe(true);
      expect(commitment.occursOn(TUESDAY_11)).toBe(false);
    });
  });

  describe("operacoes puras", () => {
    const moved: CommitmentException = {
      date: TUESDAY_11,
      type: "moved",
      newDate: WEDNESDAY_12,
      startMinute: 1200,
      endMinute: 1260,
    };

    test("cenario 11: withException acrescenta e devolve um clone (o original nao muda)", () => {
      const original = makeCommitment();

      const updated = original.withException({ date: TUESDAY_11, type: "cancelled" });

      expect(updated).not.toBe(original);
      expect(updated.id).toBe(original.id);
      expect(updated.exceptions).toEqual([{ date: TUESDAY_11, type: "cancelled" }]);
      expect(original.exceptions).toEqual([]);
    });

    test("cenario 11: withException numa data que ja tem excecao troca a anterior", () => {
      const original = makeCommitment({
        exceptions: [
          { date: "2025-11-18", type: "cancelled" },
          { date: TUESDAY_11, type: "cancelled" },
        ],
      });

      const updated = original.withException(moved);

      expect(updated.exceptions).toEqual([moved, { date: "2025-11-18", type: "cancelled" }]);
    });

    test("cenario 11: withoutException remove so a excecao daquela data", () => {
      const original = makeCommitment({
        exceptions: [moved, { date: "2025-11-18", type: "cancelled" }],
      });

      const updated = original.withoutException(TUESDAY_11);

      expect(updated.exceptions).toEqual([{ date: "2025-11-18", type: "cancelled" }]);
      expect(original.exceptions).toHaveLength(2);
    });

    test("cenario 12: endingBefore(17/11) num recorrente de 03/11 -> endDate 16/11 e so as excecoes anteriores", () => {
      const series = makeSeries([
        { date: "2025-11-10", type: "cancelled" },
        { date: "2025-11-17", type: "cancelled" },
        { date: "2025-11-19", type: "cancelled" },
      ]);

      const ended = series.endingBefore("2025-11-17");

      expect(ended?.id).toBe(series.id);
      expect(ended?.recurrence).toEqual({ weekdays: [0, 2], endDate: "2025-11-16" });
      expect(ended?.exceptions).toEqual([{ date: "2025-11-10", type: "cancelled" }]);
      expect(() => ended?.validate()).not.toThrow();
    });

    test("cenario 12: endingBefore(03/11) no recorrente iniciado em 03/11 -> null", () => {
      expect(makeSeries().endingBefore("2025-11-03")).toBeNull();
      expect(makeSeries().endingBefore("2025-11-01")).toBeNull();
    });

    test("endingBefore sem nenhuma ocorrencia antes da data -> null", () => {
      // Comeca na segunda 03/11 e so tem quarta: antes de 05/11 nao sobra nenhum dia.
      const commitment = makeCommitment({
        startDate: "2025-11-03",
        recurrence: { weekdays: [2] },
      });

      expect(commitment.endingBefore("2025-11-05")).toBeNull();
      expect(commitment.endingBefore("2025-11-06")?.recurrence?.endDate).toBe("2025-11-05");
    });

    test("endingBefore nao estende uma serie que ja terminava antes", () => {
      const commitment = makeCommitment({
        startDate: "2025-11-03",
        recurrence: { weekdays: [0, 2], endDate: "2025-11-10" },
      });

      expect(commitment.endingBefore("2025-11-24")?.recurrence?.endDate).toBe("2025-11-10");
    });

    test("endingBefore no compromisso unico -> null", () => {
      expect(makeCommitment({ recurrence: null }).endingBefore(TUESDAY_11)).toBeNull();
    });

    test("cenario 13: splitFrom(17/11, { startMinute: 1140 }) divide a serie (MC12)", () => {
      const series = makeSeries([
        { date: "2025-11-10", type: "cancelled" },
        { date: "2025-11-17", type: "cancelled" },
        { date: "2025-11-19", type: "cancelled" },
      ]).clone({ startMinute: 1080, endMinute: 1200 });

      const { previous, next } = series.splitFrom("2025-11-17", { startMinute: 1140 });

      expect(previous?.id).toBe(series.id);
      expect(previous?.recurrence?.endDate).toBe("2025-11-16");
      expect(previous?.startMinute).toBe(1080);
      expect(previous?.exceptions).toEqual([{ date: "2025-11-10", type: "cancelled" }]);
      expect(next.id).not.toBe(series.id);
      expect(next.userId).toBe(series.userId);
      expect(next.startDate).toBe("2025-11-17");
      expect(next.startMinute).toBe(1140);
      expect(next.endMinute).toBe(1200);
      expect(next.title).toBe(series.title);
      expect(next.recurrence).toEqual({ weekdays: [0, 2] });
      expect(next.exceptions).toEqual([
        { date: "2025-11-17", type: "cancelled" },
        { date: "2025-11-19", type: "cancelled" },
      ]);
      expect(() => next.validate()).not.toThrow();
    });

    test("splitFrom no primeiro dia: previous null e next com todas as excecoes", () => {
      const series = makeSeries([{ date: "2025-11-05", type: "cancelled" }]);

      const { previous, next } = series.splitFrom("2025-11-03");

      expect(previous).toBeNull();
      expect(next.startDate).toBe("2025-11-03");
      expect(next.exceptions).toEqual([{ date: "2025-11-05", type: "cancelled" }]);
    });

    test("splitFrom no compromisso unico: previous null e next unico na data escolhida", () => {
      const single = makeCommitment({ recurrence: null });

      const { previous, next } = single.splitFrom(TUESDAY_11);

      expect(previous).toBeNull();
      expect(next.recurrence).toBeNull();
      expect(next.startDate).toBe(TUESDAY_11);
    });

    test("splitFrom ignora campos undefined e descarta excecoes que deixaram de ser ocorrencias", () => {
      const series = makeSeries([
        { date: "2025-11-17", type: "cancelled" },
        { date: "2025-11-19", type: "cancelled" },
      ]);

      const { next } = series.splitFrom("2025-11-17", {
        title: undefined,
        recurrence: { weekdays: [2] },
      });

      expect(next.title).toBe(series.title);
      expect(next.recurrence).toEqual({ weekdays: [2] });
      expect(next.exceptions).toEqual([{ date: "2025-11-19", type: "cancelled" }]);
    });

    test("withChanges aplica os campos definidos e descarta excecoes que deixaram de ser ocorrencias", () => {
      const commitment = makeCommitment({
        exceptions: [{ date: TUESDAY_11, type: "cancelled" }],
      });

      const updated = commitment.withChanges({
        title: "Violão",
        category: undefined,
        recurrence: { weekdays: [2] },
      });

      expect(updated.id).toBe(commitment.id);
      expect(updated.title).toBe("Violão");
      expect(updated.category).toBe("pessoal");
      expect(updated.recurrence).toEqual({ weekdays: [2] });
      expect(updated.exceptions).toEqual([]);
    });

    test("withChanges mantem as excecoes que continuam sendo ocorrencias", () => {
      const commitment = makeCommitment({
        exceptions: [{ date: TUESDAY_11, type: "cancelled" }],
      });

      const updated = commitment.withChanges({ startMinute: 1080 });

      expect(updated.exceptions).toEqual([{ date: TUESDAY_11, type: "cancelled" }]);
    });
  });
});
