import { UseCase } from "@oitenta/shared";
import { Commitment } from "../model";
import { CommitmentRepository } from "../provider";
import { findOwnedCommitment } from "./find-owned-commitment";

export interface GetCommitmentIn {
  userId: string;
  commitmentId: string;
}

export interface GetCommitmentOut {
  commitment: Commitment;
}

/** Lê um compromisso do usuário; de outro usuário ou inexistente → `NotFoundError`. */
export class GetCommitment implements UseCase<GetCommitmentIn, GetCommitmentOut> {
  constructor(private readonly commitmentRepository: CommitmentRepository) {}

  async execute(input: GetCommitmentIn): Promise<GetCommitmentOut> {
    const commitment = await findOwnedCommitment(
      this.commitmentRepository,
      input.userId,
      input.commitmentId,
    );

    return { commitment };
  }
}
