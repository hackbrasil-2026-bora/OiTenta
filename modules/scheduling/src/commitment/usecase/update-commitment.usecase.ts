import { UseCase } from "@oitenta/shared";
import { Commitment, CommitmentCategory, CommitmentRecurrence } from "../model";
import { CommitmentRepository } from "../provider";
import { findOwnedCommitment } from "./find-owned-commitment";

export interface UpdateCommitmentIn {
  userId: string;
  commitmentId: string;
  title?: string;
  category?: CommitmentCategory;
  startDate?: string;
  startMinute?: number;
  endMinute?: number;
  recurrence?: CommitmentRecurrence | null;
}

export interface UpdateCommitmentOut {
  commitment: Commitment;
}

/**
 * Edita a série inteira (escopo "todas"). As exceções que deixaram de ser
 * ocorrências da série são descartadas.
 */
export class UpdateCommitment implements UseCase<UpdateCommitmentIn, UpdateCommitmentOut> {
  constructor(private readonly commitmentRepository: CommitmentRepository) {}

  async execute(input: UpdateCommitmentIn): Promise<UpdateCommitmentOut> {
    const existing = await findOwnedCommitment(
      this.commitmentRepository,
      input.userId,
      input.commitmentId,
    );

    const commitment = existing.withChanges({
      title: input.title?.trim(),
      category: input.category,
      startDate: input.startDate,
      startMinute: input.startMinute,
      endMinute: input.endMinute,
      recurrence: input.recurrence,
    });
    commitment.validate();

    await this.commitmentRepository.update(commitment);

    return { commitment };
  }
}
