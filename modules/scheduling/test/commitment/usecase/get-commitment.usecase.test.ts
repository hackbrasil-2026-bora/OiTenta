import { NotFoundError } from "@oitenta/shared";
import { GetCommitment } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

const UNKNOWN_ID = "55555555-5555-4555-8555-555555555555";

describe("GetCommitment", () => {
  test("cenario 2: o dono recebe o compromisso", async () => {
    const commitment = makeCommitment();
    const useCase = new GetCommitment(new FakeCommitmentRepository([commitment]));

    const output = await useCase.execute({ userId: USER_A, commitmentId: commitment.id });

    expect(output.commitment).toBe(commitment);
  });

  test("cenario 2: inexistente -> NotFoundError 'Compromisso não encontrado.'", async () => {
    const useCase = new GetCommitment(new FakeCommitmentRepository());

    await expect(useCase.execute({ userId: USER_A, commitmentId: UNKNOWN_ID })).rejects.toThrow(
      new NotFoundError("Compromisso não encontrado."),
    );
  });

  test("posse: B pede o compromisso de A -> NotFoundError", async () => {
    const commitment = makeCommitment();
    const useCase = new GetCommitment(new FakeCommitmentRepository([commitment]));

    await expect(
      useCase.execute({ userId: USER_B, commitmentId: commitment.id }),
    ).rejects.toThrow(new NotFoundError("Compromisso não encontrado."));
  });
});
