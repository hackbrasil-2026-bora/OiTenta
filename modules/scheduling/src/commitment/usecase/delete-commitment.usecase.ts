import { UseCase } from "@oitenta/shared";
import { CommitmentRepository } from "../provider";
import { findOwnedCommitment } from "./find-owned-commitment";

export interface DeleteCommitmentIn {
  userId: string;
  commitmentId: string;
}

/** Apaga a série inteira (escopo "todas"). */
export class DeleteCommitment implements UseCase<DeleteCommitmentIn, void> {
  constructor(private readonly commitmentRepository: CommitmentRepository) {}

  async execute(input: DeleteCommitmentIn): Promise<void> {
    const commitment = await findOwnedCommitment(
      this.commitmentRepository,
      input.userId,
      input.commitmentId,
    );

    await this.commitmentRepository.delete(input.userId, commitment.id);
  }
}
