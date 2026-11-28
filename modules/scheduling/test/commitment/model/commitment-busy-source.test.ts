import { Commitment, CommitmentBusySource, CommitmentState } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, SAO_PAULO, USER_A, USER_B } from "../../mock";

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

describe("CommitmentBusySource", () => {
  test("devolve as ocorrencias do usuario dentro do periodo, em ordem", async () => {
    const repository = new FakeCommitmentRepository([
      makeClass({ title: "Estagio", startMinute: 13 * 60 + 30, endMinute: 19 * 60 + 30 }),
      makeClass(),
    ]);
    const source = new CommitmentBusySource(repository);

    const busy = await source.listBusy(
      USER_A,
      new Date("2025-11-03T03:00:00.000Z"),
      new Date("2025-11-04T03:00:00.000Z"),
      SAO_PAULO,
    );

    expect(busy.map((item) => item.start.toISOString())).toEqual([
      "2025-11-03T11:00:00.000Z",
      "2025-11-03T16:30:00.000Z",
    ]);
  });

  test("inclui ocorrencia que comecou antes do periodo e ainda nao terminou", async () => {
    const lateNight = makeClass({ startMinute: 23 * 60, endMinute: 1440 });
    const source = new CommitmentBusySource(new FakeCommitmentRepository([lateNight]));

    const busy = await source.listBusy(
      USER_A,
      new Date("2025-11-04T02:30:00.000Z"),
      new Date("2025-11-04T04:00:00.000Z"),
      SAO_PAULO,
    );

    expect(busy).toEqual([
      {
        start: new Date("2025-11-04T02:00:00.000Z"),
        end: new Date("2025-11-04T03:00:00.000Z"),
      },
    ]);
  });

  test("cenario 1: uma ocorrencia cancelled nao entra na ocupacao", async () => {
    const commitment = makeClass({
      exceptions: [{ date: "2025-11-04", type: "cancelled" }],
    });
    const source = new CommitmentBusySource(new FakeCommitmentRepository([commitment]));

    const busy = await source.listBusy(
      USER_A,
      new Date("2025-11-03T03:00:00.000Z"),
      new Date("2025-11-05T03:00:00.000Z"),
      SAO_PAULO,
    );

    expect(busy.map((item) => item.start.toISOString())).toEqual(["2025-11-03T11:00:00.000Z"]);
  });

  test("uma ocorrencia moved ocupa o horario novo", async () => {
    const commitment = makeClass({
      exceptions: [
        {
          date: "2025-11-04",
          type: "moved",
          newDate: "2025-11-04",
          startMinute: 14 * 60,
          endMinute: 15 * 60,
        },
      ],
    });
    const source = new CommitmentBusySource(new FakeCommitmentRepository([commitment]));

    const busy = await source.listBusy(
      USER_A,
      new Date("2025-11-04T03:00:00.000Z"),
      new Date("2025-11-05T03:00:00.000Z"),
      SAO_PAULO,
    );

    expect(busy).toEqual([
      {
        start: new Date("2025-11-04T17:00:00.000Z"),
        end: new Date("2025-11-04T18:00:00.000Z"),
      },
    ]);
  });

  test("posse: compromissos de A nao ocupam a agenda de B", async () => {
    const source = new CommitmentBusySource(new FakeCommitmentRepository([makeClass()]));

    const busy = await source.listBusy(
      USER_B,
      new Date("2025-11-03T03:00:00.000Z"),
      new Date("2025-11-10T03:00:00.000Z"),
      SAO_PAULO,
    );

    expect(busy).toEqual([]);
  });
});
