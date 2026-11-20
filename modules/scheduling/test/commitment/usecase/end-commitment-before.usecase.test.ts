import { NotFoundError, ValidationException } from "@oitenta/shared";
import { EndCommitmentBefore } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

function makeSeries() {
  return makeCommitment({
    startDate: "2025-11-04",
    recurrence: { weekdays: [1] },
    exceptions: [
      { date: "2025-11-11", type: "cancelled" },
      { date: "2025-11-25", type: "cancelled" },
    ],
  });
}

describe("EndCommitmentBefore", () => {
  test("cenario 7: encerra a serie no dia anterior e mantem so as excecoes anteriores", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    await expect(
      new EndCommitmentBefore(repository).execute({
        userId: USER_A,
        commitmentId: series.id,
        fromDate: "2025-11-18",
      }),
    ).resolves.toBeUndefined();

    const ended = await repository.findById(USER_A, series.id);
    expect(ended?.recurrence).toEqual({ weekdays: [1], endDate: "2025-11-17" });
    expect(ended?.exceptions).toEqual([{ date: "2025-11-11", type: "cancelled" }]);
  });

  test("cenario 7: fromDate <= startDate -> apaga", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    await new EndCommitmentBefore(repository).execute({
      userId: USER_A,
      commitmentId: series.id,
      fromDate: "2025-11-04",
    });

    expect(repository.commitments).toEqual([]);
    expect(repository.deleteCalls).toBe(1);
  });

  test("fromDate mal formada -> ValidationException e nada e gravado", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    await expect(
      new EndCommitmentBefore(repository).execute({
        userId: USER_A,
        commitmentId: series.id,
        fromDate: "amanhã",
      }),
    ).rejects.toThrow(ValidationException);
    expect(repository.writeCalls).toBe(0);
  });

  test("posse: B nao encerra o compromisso de A -> NotFoundError e nada e gravado", async () => {
    const series = makeSeries();
    const repository = new FakeCommitmentRepository([series]);

    await expect(
      new EndCommitmentBefore(repository).execute({
        userId: USER_B,
        commitmentId: series.id,
        fromDate: "2025-11-18",
      }),
    ).rejects.toThrow(new NotFoundError("Compromisso não encontrado."));
    expect(repository.writeCalls).toBe(0);
  });
});
