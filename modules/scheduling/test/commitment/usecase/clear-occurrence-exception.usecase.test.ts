import { NotFoundError } from "@oitenta/shared";
import { ClearOccurrenceException } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

function makeWithExceptions() {
  return makeCommitment({
    exceptions: [
      { date: "2025-11-11", type: "cancelled" },
      { date: "2025-11-18", type: "cancelled" },
    ],
  });
}

describe("ClearOccurrenceException", () => {
  test("cenario 9: remove a excecao da data e grava", async () => {
    const commitment = makeWithExceptions();
    const repository = new FakeCommitmentRepository([commitment]);

    const output = await new ClearOccurrenceException(repository).execute({
      userId: USER_A,
      commitmentId: commitment.id,
      date: "2025-11-11",
    });

    expect(output.commitment.exceptions).toEqual([{ date: "2025-11-18", type: "cancelled" }]);
    expect(await repository.findById(USER_A, commitment.id)).toBe(output.commitment);
  });

  test("cenario 9: sem excecao na data -> NotFoundError e nao grava", async () => {
    const commitment = makeWithExceptions();
    const repository = new FakeCommitmentRepository([commitment]);

    await expect(
      new ClearOccurrenceException(repository).execute({
        userId: USER_A,
        commitmentId: commitment.id,
        date: "2025-11-25",
      }),
    ).rejects.toThrow(new NotFoundError("Exceção não encontrada nesta data."));
    expect(repository.updateCalls).toBe(0);
  });

  test("posse: B nao altera o compromisso de A -> NotFoundError e nao grava", async () => {
    const commitment = makeWithExceptions();
    const repository = new FakeCommitmentRepository([commitment]);

    await expect(
      new ClearOccurrenceException(repository).execute({
        userId: USER_B,
        commitmentId: commitment.id,
        date: "2025-11-11",
      }),
    ).rejects.toThrow(new NotFoundError("Compromisso não encontrado."));
    expect(repository.updateCalls).toBe(0);
  });
});
