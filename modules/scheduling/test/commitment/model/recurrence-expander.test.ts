import { Commitment, CommitmentException, CommitmentState, RecurrenceExpander } from "../../../src";
import { makeCommitment, SAO_PAULO } from "../../mock";

/** Aula seg-sex, 08:00-12:00, desde a segunda 03/11/2025 (cenarios 1-4 da §3.7). */
function makeClass(overrides: Partial<CommitmentState> = {}): Commitment {
  return makeCommitment({
    title: "Aula",
    category: "aula",
    startDate: "2025-11-03",
    startMinute: 8 * 60,
    endMinute: 12 * 60,
    recurrence: { weekdays: [0, 1, 2, 3, 4] },
    ...overrides,
  });
}

const MOVED_TO_WEDNESDAY: CommitmentException = {
  date: "2025-11-11",
  type: "moved",
  newDate: "2025-11-12",
  startMinute: 20 * 60,
  endMinute: 21 * 60,
};

const expander = new RecurrenceExpander();

describe("RecurrenceExpander.expand", () => {
  test("cenario 1: aula seg-sex expandida de 03/11 a 09/11 da 5 ocorrencias, nenhuma no fim de semana", () => {
    const occurrences = expander.expand(makeClass(), "2025-11-03", "2025-11-09", SAO_PAULO);

    expect(occurrences.map((item) => item.start.toISOString())).toEqual([
      "2025-11-03T11:00:00.000Z",
      "2025-11-04T11:00:00.000Z",
      "2025-11-05T11:00:00.000Z",
      "2025-11-06T11:00:00.000Z",
      "2025-11-07T11:00:00.000Z",
    ]);
  });

  test("cenario 2: endDate 05/11 limita a semana a 3 ocorrencias", () => {
    const commitment = makeClass({
      recurrence: { weekdays: [0, 1, 2, 3, 4], endDate: "2025-11-05" },
    });

    expect(expander.expand(commitment, "2025-11-03", "2025-11-09", SAO_PAULO)).toHaveLength(3);
  });

  test("cenario 3: compromisso unico em 06/11 aparece 1 vez na semana que o contem", () => {
    const commitment = makeClass({ startDate: "2025-11-06", recurrence: null });

    expect(expander.expand(commitment, "2025-11-03", "2025-11-09", SAO_PAULO)).toHaveLength(1);
  });

  test("cenario 3: compromisso unico em 06/11 nao aparece em outra semana", () => {
    const commitment = makeClass({ startDate: "2025-11-06", recurrence: null });

    expect(expander.expand(commitment, "2025-11-10", "2025-11-16", SAO_PAULO)).toEqual([]);
  });

  test("cenario 4: 08:00 em Sao Paulo comeca 11:00 UTC e termina no endMinute (12:00 locais)", () => {
    const [first] = expander.expand(makeClass(), "2025-11-03", "2025-11-03", SAO_PAULO);

    expect(first?.start.toISOString()).toBe("2025-11-03T11:00:00.000Z");
    expect(first?.end.toISOString()).toBe("2025-11-03T15:00:00.000Z");
  });

  test("respeita o startDate: nada antes do inicio do compromisso", () => {
    const commitment = makeClass({ startDate: "2025-11-05" });

    expect(expander.expand(commitment, "2025-11-03", "2025-11-09", SAO_PAULO)).toHaveLength(3);
  });

  test("endMinute 1440 termina na meia-noite local do dia seguinte", () => {
    const commitment = makeClass({ startMinute: 23 * 60, endMinute: 1440, recurrence: null });

    expect(expander.expand(commitment, "2025-11-03", "2025-11-03", SAO_PAULO)).toEqual([
      {
        start: new Date("2025-11-04T02:00:00.000Z"),
        end: new Date("2025-11-04T03:00:00.000Z"),
      },
    ]);
  });

  test("cenario 5: a ter 11/11 cancelled nao aparece no expand", () => {
    const commitment = makeCommitment({
      exceptions: [{ date: "2025-11-11", type: "cancelled" }],
    });

    expect(expander.expand(commitment, "2025-11-10", "2025-11-16", SAO_PAULO)).toEqual([]);
  });

  test("cenario 6: a ter 11/11 movida para qua 12/11 20:00-21:00 usa o horario novo no expand", () => {
    const commitment = makeCommitment({ exceptions: [MOVED_TO_WEDNESDAY] });

    expect(expander.expand(commitment, "2025-11-10", "2025-11-16", SAO_PAULO)).toEqual([
      {
        start: new Date("2025-11-12T23:00:00.000Z"),
        end: new Date("2025-11-13T00:00:00.000Z"),
      },
    ]);
  });
});

describe("RecurrenceExpander.occurrences", () => {
  test("devolve datas locais com o horario e status normal", () => {
    expect(expander.occurrences(makeCommitment(), "2025-11-03", "2025-11-16")).toEqual([
      {
        date: "2025-11-04",
        originalDate: "2025-11-04",
        startMinute: 1140,
        endMinute: 1200,
        status: "normal",
      },
      {
        date: "2025-11-11",
        originalDate: "2025-11-11",
        startMinute: 1140,
        endMinute: 1200,
        status: "normal",
      },
    ]);
  });

  test("cenario 5: a ter 11/11 cancelled aparece com status cancelled e o horario original", () => {
    const commitment = makeCommitment({
      exceptions: [{ date: "2025-11-11", type: "cancelled" }],
    });

    expect(expander.occurrences(commitment, "2025-11-10", "2025-11-16")).toEqual([
      {
        date: "2025-11-11",
        originalDate: "2025-11-11",
        startMinute: 1140,
        endMinute: 1200,
        status: "cancelled",
      },
    ]);
  });

  test("cenario 6: a movida sai de 11/11 e aparece em 12/11 com originalDate 11/11", () => {
    const commitment = makeCommitment({ exceptions: [MOVED_TO_WEDNESDAY] });

    expect(expander.occurrences(commitment, "2025-11-10", "2025-11-16")).toEqual([
      {
        date: "2025-11-12",
        originalDate: "2025-11-11",
        startMinute: 1200,
        endMinute: 1260,
        status: "moved",
      },
    ]);
  });

  test("cenario 7: com a janela so em 12/11, a movida aparece mesmo com 11/11 fora", () => {
    const commitment = makeCommitment({ exceptions: [MOVED_TO_WEDNESDAY] });

    expect(expander.occurrences(commitment, "2025-11-12", "2025-11-12")).toEqual([
      {
        date: "2025-11-12",
        originalDate: "2025-11-11",
        startMinute: 1200,
        endMinute: 1260,
        status: "moved",
      },
    ]);
  });

  test("a movida para fora da janela nao aparece nem no dia original", () => {
    const commitment = makeCommitment({ exceptions: [MOVED_TO_WEDNESDAY] });

    expect(expander.occurrences(commitment, "2025-11-11", "2025-11-11")).toEqual([]);
  });

  test("ordena por data e horario quando a movida cai antes de outra ocorrencia", () => {
    const commitment = makeCommitment({
      exceptions: [
        {
          date: "2025-11-18",
          type: "moved",
          newDate: "2025-11-10",
          startMinute: 600,
          endMinute: 660,
        },
      ],
    });

    expect(
      expander.occurrences(commitment, "2025-11-10", "2025-11-18").map((item) => item.date),
    ).toEqual(["2025-11-10", "2025-11-11"]);
  });

  test("no mesmo dia, a de horario mais cedo vem antes", () => {
    const commitment = makeCommitment({
      exceptions: [
        {
          date: "2025-11-18",
          type: "moved",
          newDate: "2025-11-11",
          startMinute: 600,
          endMinute: 660,
        },
      ],
    });

    expect(
      expander.occurrences(commitment, "2025-11-11", "2025-11-11").map((item) => item.startMinute),
    ).toEqual([600, 1140]);
  });
});
