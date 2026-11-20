import { UseCase } from "@oitenta/shared";
import { Commitment, CommitmentCategory, CommitmentRecurrence } from "../model";
import { CommitmentRepository } from "../provider";
import { findOwnedCommitment, validateFromDate } from "./find-owned-commitment";

export interface SplitCommitmentFromIn {
  userId: string;
  commitmentId: string;
  fromDate: string;
  title?: string;
  category?: CommitmentCategory;
  startMinute?: number;
  endMinute?: number;
  /** Ausente = mantém; `null` = vira compromisso único (na data de início); objeto = nova recorrência. */
  recurrence?: CommitmentRecurrence | null;
}

export interface SplitCommitmentFromOut {
  commitment: Commitment;
}

/**
 * "Desse dia em diante" (MC12): encerra a série antes de `fromDate` (ou apaga,
 * se ela ficar sem ocorrência) e cria a série nova a partir de `fromDate`.
 */
export class SplitCommitmentFrom implements UseCase<SplitCommitmentFromIn, SplitCommitmentFromOut> {
  constructor(private readonly commitmentRepository: CommitmentRepository) {}

  async execute(input: SplitCommitmentFromIn): Promise<SplitCommitmentFromOut> {
    const existing = await findOwnedCommitment(
      this.commitmentRepository,
      input.userId,
      input.commitmentId,
    );
    validateFromDate(input.fromDate);

    const { previous, next } = existing.splitFrom(input.fromDate, {
      title: input.title?.trim(),
      category: input.category,
      startMinute: input.startMinute,
      endMinute: input.endMinute,
      recurrence: input.recurrence,
    });
    previous?.validate();
    next.validate();

    if (previous) {
      await this.commitmentRepository.update(previous);
    } else {
      await this.commitmentRepository.delete(input.userId, existing.id);
    }
    await this.commitmentRepository.create(next);

    return { commitment: next };
  }
}
