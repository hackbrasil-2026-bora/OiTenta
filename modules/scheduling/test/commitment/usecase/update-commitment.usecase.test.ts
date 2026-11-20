import { NotFoundError, ValidationException } from "@oitenta/shared";
import { UpdateCommitment } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

describe("UpdateCommitment", () => {
  test("cenario 4: muda o titulo (aparado) e o horario de todas as ocorrencias", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    const output = await new UpdateCommitment(repository).execute({
      userId: USER_A,
      commitmentId: commitment.id,
      title: "  Violão  ",
      startMinute: 18 * 60,
      endMinute: 19 * 60 + 30,
    });

    expect(output.commitment.id).toBe(commitment.id);
    expect(output.commitment.title).toBe("Violão");
    expect(output.commitment.startMinute).toBe(1080);
    expect(output.commitment.endMinute).toBe(1170);
    expect(output.commitment.category).toBe("pessoal");
    expect(repository.commitments).toEqual([output.commitment]);
  });

  test("aceita trocar categoria, startDate e recorrencia (inclusive para unico)", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    const output = await new UpdateCommitment(repository).execute({
      userId: USER_A,
      commitmentId: commitment.id,
      category: "aula",
      startDate: "2025-11-06",
      recurrence: null,
    });

    expect(output.commitment.category).toBe("aula");
    expect(output.commitment.startDate).toBe("2025-11-06");
    expect(output.commitment.recurrence).toBeNull();
    expect(output.commitment.title).toBe("Aula de violão");
  });

  test("cenario 4: mudou de terca para quarta -> as excecoes que deixaram de ser ocorrencias sao descartadas", async () => {
    const commitment = makeCommitment({
      exceptions: [{ date: "2025-11-11", type: "cancelled" }],
    });
    const repository = new FakeCommitmentRepository([commitment]);

    const output = await new UpdateCommitment(repository).execute({
      userId: USER_A,
      commitmentId: commitment.id,
      recurrence: { weekdays: [2] },
    });

    expect(output.commitment.recurrence).toEqual({ weekdays: [2] });
    expect(output.commitment.exceptions).toEqual([]);
  });

  test("recurrence null + startDate 11/11: o semanal vira unico em 11/11 e as excecoes que deixaram de ser ocorrencia sao descartadas", async () => {
    const commitment = makeCommitment({
      exceptions: [
        { date: "2025-11-18", type: "cancelled" },
        { date: "2025-11-25", type: "cancelled" },
      ],
    });
    const repository = new FakeCommitmentRepository([commitment]);

    const output = await new UpdateCommitment(repository).execute({
      userId: USER_A,
      commitmentId: commitment.id,
      startDate: "2025-11-11",
      recurrence: null,
    });

    expect(output.commitment.recurrence).toBeNull();
    expect(output.commitment.startDate).toBe("2025-11-11");
    expect(output.commitment.exceptions).toEqual([]);
    expect(await repository.findById(USER_A, commitment.id)).toBe(output.commitment);
  });

  test("recurrence ausente: a recorrencia e as excecoes nao mudam", async () => {
    const commitment = makeCommitment({
      recurrence: { weekdays: [1], endDate: "2025-12-16" },
      exceptions: [{ date: "2025-11-18", type: "cancelled" }],
    });
    const repository = new FakeCommitmentRepository([commitment]);

    const output = await new UpdateCommitment(repository).execute({
      userId: USER_A,
      commitmentId: commitment.id,
      title: "Violão",
    });

    expect(output.commitment.recurrence).toEqual({ weekdays: [1], endDate: "2025-12-16" });
    expect(output.commitment.exceptions).toEqual([{ date: "2025-11-18", type: "cancelled" }]);
  });

  test("dados invalidos -> ValidationException e nao grava", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    await expect(
      new UpdateCommitment(repository).execute({
        userId: USER_A,
        commitmentId: commitment.id,
        endMinute: 1100,
      }),
    ).rejects.toThrow(ValidationException);
    expect(repository.updateCalls).toBe(0);
  });

  test("posse: B nao altera o compromisso de A -> NotFoundError e nada muda", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    await expect(
      new UpdateCommitment(repository).execute({
        userId: USER_B,
        commitmentId: commitment.id,
        title: "Invasão",
      }),
    ).rejects.toThrow(new NotFoundError("Compromisso não encontrado."));
    expect(repository.updateCalls).toBe(0);
    expect(repository.commitments[0]?.title).toBe("Aula de violão");
  });
});
