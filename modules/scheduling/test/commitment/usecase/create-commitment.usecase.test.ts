import { ValidationException } from "@oitenta/shared";
import { CreateCommitment, CreateCommitmentIn } from "../../../src";
import { FakeCommitmentRepository, USER_A, USER_B } from "../../mock";

function makeInput(overrides: Partial<CreateCommitmentIn> = {}): CreateCommitmentIn {
  return {
    userId: USER_A,
    title: "  Aula de violão  ",
    category: "pessoal",
    startDate: "2025-11-04",
    startMinute: 19 * 60,
    endMinute: 20 * 60,
    recurrence: { weekdays: [1] },
    ...overrides,
  };
}

describe("CreateCommitment", () => {
  test("cenario 1: dados validos -> grava com o userId da entrada e devolve o compromisso", async () => {
    const repository = new FakeCommitmentRepository();
    const useCase = new CreateCommitment(repository);

    const { commitment } = await useCase.execute(makeInput());

    expect(commitment.userId).toBe(USER_A);
    expect(commitment.title).toBe("Aula de violão");
    expect(commitment.category).toBe("pessoal");
    expect(commitment.kind).toBe("commitment");
    expect(commitment.startDate).toBe("2025-11-04");
    expect(commitment.startMinute).toBe(1140);
    expect(commitment.endMinute).toBe(1200);
    expect(commitment.recurrence).toEqual({ weekdays: [1] });
    expect(commitment.exceptions).toEqual([]);
    expect(repository.commitments).toEqual([commitment]);
  });

  test("compromisso unico (recurrence null) e gravado", async () => {
    const repository = new FakeCommitmentRepository();

    const { commitment } = await new CreateCommitment(repository).execute(
      makeInput({ recurrence: null }),
    );

    expect(commitment.recurrence).toBeNull();
    expect(repository.createCalls).toBe(1);
  });

  test("cenario 1: dados invalidos -> ValidationException e nao grava", async () => {
    const repository = new FakeCommitmentRepository();
    const useCase = new CreateCommitment(repository);

    await expect(useCase.execute(makeInput({ title: "A", endMinute: 1100 }))).rejects.toThrow(
      ValidationException,
    );
    expect(repository.createCalls).toBe(0);
  });

  test("posse: o compromisso criado por A nao aparece para B", async () => {
    const repository = new FakeCommitmentRepository();
    const { commitment } = await new CreateCommitment(repository).execute(makeInput());

    expect(await repository.findById(USER_B, commitment.id)).toBeNull();
    expect(await repository.findAllByUser(USER_B)).toEqual([]);
  });
});
