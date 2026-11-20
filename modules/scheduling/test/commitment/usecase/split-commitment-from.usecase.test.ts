import { NotFoundError, ValidationException } from "@oitenta/shared";
import { SplitCommitmentFrom } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

/** Recorrente iniciado na segunda 03/11/2025, toda segunda e quarta, 18:00-20:00. */
function makeSeries() {
  return makeCommitment({
    startDate: "2025-11-03",
    startMinute: 18 * 60,
    endMinute: 20 * 60,
    recurrence: { weekdays: [0, 2] },
    exceptions: [
      { date: "2025-11-10", type: "cancelled" },
      { date: "2025-11-19", type: "cancelled" },
    ],
  });
}

describe("SplitCommitmentFrom", () => {
  test("cenario 5: grava a anterior encerrada e cria a nova com as mudancas (MC12)", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    const { commitment: next } = await new SplitCommitmentFrom(repository).execute({
      userId: USER_A,
      commitmentId: series.id,
      fromDate: "2025-11-17",
      title: "  Violão  ",
      startMinute: 19 * 60,
    });

    const previous = await repository.findById(USER_A, series.id);
    expect(previous?.recurrence).toEqual({ weekdays: [0, 2], endDate: "2025-11-16" });
    expect(previous?.startMinute).toBe(1080);
    expect(previous?.exceptions).toEqual([{ date: "2025-11-10", type: "cancelled" }]);
    expect(next.id).not.toBe(series.id);
    expect(next.userId).toBe(USER_A);
    expect(next.title).toBe("Violão");
    expect(next.startDate).toBe("2025-11-17");
    expect(next.startMinute).toBe(1140);
    expect(next.exceptions).toEqual([{ date: "2025-11-19", type: "cancelled" }]);
    expect(await repository.findById(USER_A, next.id)).toBe(next);
    expect(repository.commitments).toHaveLength(2);
  });

  test("mantem a categoria quando nao vem titulo nem categoria", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    const { commitment: next } = await new SplitCommitmentFrom(repository).execute({
      userId: USER_A,
      commitmentId: series.id,
      fromDate: "2025-11-17",
      category: "aula",
      endMinute: 21 * 60,
      recurrence: { weekdays: [2] },
    });

    expect(next.title).toBe(series.title);
    expect(next.category).toBe("aula");
    expect(next.endMinute).toBe(1260);
    expect(next.recurrence).toEqual({ weekdays: [2] });
  });

  test("recurrence null: a nova vira unica em fromDate e as excecoes que deixaram de ser ocorrencia sao descartadas", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    const { commitment: next } = await new SplitCommitmentFrom(repository).execute({
      userId: USER_A,
      commitmentId: series.id,
      fromDate: "2025-11-17",
      recurrence: null,
    });

    expect(next.recurrence).toBeNull();
    expect(next.startDate).toBe("2025-11-17");
    expect(next.exceptions).toEqual([]);
    expect((await repository.findById(USER_A, series.id))?.recurrence?.endDate).toBe(
      "2025-11-16",
    );
  });

  test("recurrence ausente: a nova mantem a recorrencia da serie", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    const { commitment: next } = await new SplitCommitmentFrom(repository).execute({
      userId: USER_A,
      commitmentId: series.id,
      fromDate: "2025-11-17",
      title: "Violão",
    });

    expect(next.recurrence).toEqual({ weekdays: [0, 2] });
    expect(next.exceptions).toEqual([{ date: "2025-11-19", type: "cancelled" }]);
  });

  test("cenario 5: se a anterior fica sem ocorrencia, ela e apagada", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    const { commitment: next } = await new SplitCommitmentFrom(repository).execute({
      userId: USER_A,
      commitmentId: series.id,
      fromDate: "2025-11-03",
      startMinute: 19 * 60,
    });

    expect(await repository.findById(USER_A, series.id)).toBeNull();
    expect(repository.commitments).toEqual([next]);
    expect(repository.deleteCalls).toBe(1);
  });

  test("mudanca invalida -> ValidationException e nada e gravado", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    await expect(
      new SplitCommitmentFrom(repository).execute({
        userId: USER_A,
        commitmentId: series.id,
        fromDate: "2025-11-17",
        endMinute: 1000,
      }),
    ).rejects.toThrow(ValidationException);
    expect(repository.writeCalls).toBe(0);
  });

  test("fromDate mal formada -> ValidationException commitment.fromDate e nada e gravado", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    const error = await new SplitCommitmentFrom(repository)
      .execute({ userId: USER_A, commitmentId: series.id, fromDate: "17/11/2025" })
      .catch((caught: unknown) => caught);

    expect((error as ValidationException).errors.map((item) => item.message)).toEqual([
      "commitment.fromDate.local.date",
    ]);
    expect(repository.writeCalls).toBe(0);
  });

  test("posse: B nao divide o compromisso de A -> NotFoundError e nada e gravado", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    await expect(
      new SplitCommitmentFrom(repository).execute({
        userId: USER_B,
        commitmentId: series.id,
        fromDate: "2025-11-17",
      }),
    ).rejects.toThrow(new NotFoundError("Compromisso não encontrado."));
    expect(repository.writeCalls).toBe(0);
  });
});
