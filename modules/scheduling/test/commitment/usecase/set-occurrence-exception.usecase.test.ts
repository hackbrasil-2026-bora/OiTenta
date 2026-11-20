import { NotFoundError, ValidationException } from "@oitenta/shared";
import { SetOccurrenceException } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

describe("SetOccurrenceException", () => {
  test("cenario 8: cancelled numa ocorrencia valida grava e devolve o compromisso", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    const output = await new SetOccurrenceException(repository).execute({
      userId: USER_A,
      commitmentId: commitment.id,
      date: "2025-11-11",
      type: "cancelled",
    });

    expect(output.commitment.exceptions).toEqual([{ date: "2025-11-11", type: "cancelled" }]);
    expect(await repository.findById(USER_A, commitment.id)).toBe(output.commitment);
  });

  test("moved grava o novo dia e horario, trocando a excecao anterior da mesma data", async () => {
    const commitment = makeCommitment({
      exceptions: [{ date: "2025-11-11", type: "cancelled" }],
    });
    const repository = new FakeCommitmentRepository([commitment]);

    const output = await new SetOccurrenceException(repository).execute({
      userId: USER_A,
      commitmentId: commitment.id,
      date: "2025-11-11",
      type: "moved",
      newDate: "2025-11-12",
      startMinute: 20 * 60,
      endMinute: 21 * 60,
    });

    expect(output.commitment.exceptions).toEqual([
      {
        date: "2025-11-11",
        type: "moved",
        newDate: "2025-11-12",
        startMinute: 1200,
        endMinute: 1260,
      },
    ]);
  });

  test("cenario 8: data que nao e ocorrencia -> ValidationException e nao grava", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    const error = await new SetOccurrenceException(repository)
      .execute({
        userId: USER_A,
        commitmentId: commitment.id,
        date: "2025-11-12",
        type: "cancelled",
      })
      .catch((caught: unknown) => caught);

    expect(error).toBeInstanceOf(ValidationException);
    expect((error as ValidationException).errors.map((item) => item.message)).toEqual([
      "commitment.exceptions.date.not.occurrence",
    ]);
    expect(repository.updateCalls).toBe(0);
  });

  test("posse: B nao altera o compromisso de A -> NotFoundError e nao grava", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    await expect(
      new SetOccurrenceException(repository).execute({
        userId: USER_B,
        commitmentId: commitment.id,
        date: "2025-11-11",
        type: "cancelled",
      }),
    ).rejects.toThrow(new NotFoundError("Compromisso não encontrado."));
    expect(repository.updateCalls).toBe(0);
  });
});
