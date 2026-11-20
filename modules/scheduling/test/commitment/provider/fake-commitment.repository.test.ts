import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

describe("FakeCommitmentRepository (contrato do CommitmentRepository)", () => {
  test("create, findById, findAllByUser, update e delete do dono", async () => {
    const repository = new FakeCommitmentRepository();
    const commitment = makeCommitment();

    await repository.create(commitment);
    const renamed = commitment.clone({ title: "Violão" });
    await repository.update(renamed);

    expect((await repository.findById(USER_A, commitment.id))?.title).toBe("Violão");
    expect(await repository.findAllByUser(USER_A)).toHaveLength(1);

    await repository.delete(USER_A, commitment.id);

    expect(await repository.findById(USER_A, commitment.id)).toBeNull();
  });

  test("posse: B nao ve, nao lista, nao altera e nao apaga o compromisso de A", async () => {
    const commitment = makeCommitment();
    const repository = new FakeCommitmentRepository([commitment]);

    expect(await repository.findById(USER_B, commitment.id)).toBeNull();
    expect(await repository.findAllByUser(USER_B)).toEqual([]);
    await expect(repository.update(commitment.clone({ userId: USER_B }))).rejects.toThrow();
    await expect(repository.delete(USER_B, commitment.id)).rejects.toThrow();
    expect(repository.commitments).toEqual([commitment]);
  });
});
