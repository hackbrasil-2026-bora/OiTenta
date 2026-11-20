import { NotFoundError, UseCase } from "@oitenta/shared";
import { Commitment } from "../model";
import { CommitmentRepository } from "../provider";
import { findOwnedCommitment } from "./find-owned-commitment";

export const EXCEPTION_NOT_FOUND_MESSAGE = "Exceção não encontrada nesta data.";

export interface ClearOccurrenceExceptionIn {
  userId: string;
  commitmentId: string;
  date: string;
}

export interface ClearOccurrenceExceptionOut {
  commitment: Commitment;
}

/** Volta a ocorrência ao normal ("Vai ter sim", "Voltar pro horário normal"). */
export class ClearOccurrenceException
  implements UseCase<ClearOccurrenceExceptionIn, ClearOccurrenceExceptionOut>
{
  constructor(private readonly commitmentRepository: CommitmentRepository) {}

  async execute(input: ClearOccurrenceExceptionIn): Promise<ClearOccurrenceExceptionOut> {
    const existing = await findOwnedCommitment(
      this.commitmentRepository,
      input.userId,
      input.commitmentId,
    );
    if (!existing.exceptions.some((exception) => exception.date === input.date)) {
      throw new NotFoundError(EXCEPTION_NOT_FOUND_MESSAGE);
    }

    const commitment = existing.withoutException(input.date);
    commitment.validate();

    await this.commitmentRepository.update(commitment);

    return { commitment };
  }
}
