import { UseCase } from "@oitenta/shared";
import { Commitment, CommitmentCategory, CommitmentRecurrence } from "../model";
import { CommitmentRepository } from "../provider";

export interface CreateCommitmentIn {
  userId: string;
  title: string;
  category: CommitmentCategory;
  startDate: string;
  startMinute: number;
  endMinute: number;
  recurrence: CommitmentRecurrence | null;
}

export interface CreateCommitmentOut {
  commitment: Commitment;
}

/** Cadastra um compromisso único ou recorrente, sem exceções. */
export class CreateCommitment implements UseCase<CreateCommitmentIn, CreateCommitmentOut> {
  constructor(private readonly commitmentRepository: CommitmentRepository) {}

  async execute(input: CreateCommitmentIn): Promise<CreateCommitmentOut> {
    const commitment = new Commitment({
      userId: input.userId,
      title: input.title.trim(),
      category: input.category,
      kind: "commitment",
      startDate: input.startDate,
      startMinute: input.startMinute,
      endMinute: input.endMinute,
      recurrence: input.recurrence,
      exceptions: [],
    });
    commitment.validate();

    await this.commitmentRepository.create(commitment);

    return { commitment };
  }
}
