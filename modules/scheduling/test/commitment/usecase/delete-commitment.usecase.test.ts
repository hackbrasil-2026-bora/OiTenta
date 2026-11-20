import { NotFoundError } from "@oitenta/shared";
import { DeleteCommitment } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

describe("DeleteCommitment", () => {
  test("cenario 6: o dono apaga o compromisso", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    await expect(
      new DeleteCommitment(repository).execute({ userId: USER_A, commitmentId: commitment.id }),
    ).resolves.toBeUndefined();
    expect(repository.commitments).toEqual([]);
  });

  test("posse: B nao apaga o compromisso de A -> NotFoundError e ele continua la", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    await expect(
      new DeleteCommitment(repository).execute({ userId: USER_B, commitmentId: commitment.id }),
    ).rejects.toThrow(new NotFoundError("Compromisso não encontrado."));
    expect(repository.commitments).toEqual([commitment]);
  });
});
