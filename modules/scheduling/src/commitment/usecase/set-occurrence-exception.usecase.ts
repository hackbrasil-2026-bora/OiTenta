import { UseCase } from "@oitenta/shared";
import { Commitment, CommitmentException, CommitmentExceptionType } from "../model";
import { CommitmentRepository } from "../provider";
import { findOwnedCommitment } from "./find-owned-commitment";

export interface SetOccurrenceExceptionIn {
  userId: string;
  commitmentId: string;
  date: string;
  type: CommitmentExceptionType;
  newDate?: string;
  startMinute?: number;
  endMinute?: number;
}

export interface SetOccurrenceExceptionOut {
  commitment: Commitment;
}

/** Cancela ou move uma ocorrência ("só nesse dia", MC1); troca a exceção que já houver na data. */
export class SetOccurrenceException
  implements UseCase<SetOccurrenceExceptionIn, SetOccurrenceExceptionOut>
{
  constructor(private readonly commitmentRepository: CommitmentRepository) {}

  async execute(input: SetOccurrenceExceptionIn): Promise<SetOccurrenceExceptionOut> {
    const existing = await findOwnedCommitment(
      this.commitmentRepository,
      input.userId,
      input.commitmentId,
    );

    const exception: CommitmentException = { date: input.date, type: input.type };
    if (input.newDate !== undefined) exception.newDate = input.newDate;
    if (input.startMinute !== undefined) exception.startMinute = input.startMinute;
    if (input.endMinute !== undefined) exception.endMinute = input.endMinute;

    const commitment = existing.withException(exception);
    commitment.validate();

    await this.commitmentRepository.update(commitment);

    return { commitment };
  }
}
