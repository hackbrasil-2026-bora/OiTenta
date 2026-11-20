import { UseCase } from "@oitenta/shared";
import { CommitmentRepository } from "../provider";
import { findOwnedCommitment, validateFromDate } from "./find-owned-commitment";

export interface EndCommitmentBeforeIn {
  userId: string;
  commitmentId: string;
  fromDate: string;
}

/**
 * "Excluir desse dia em diante" (MC12): a série termina no dia anterior a
 * `fromDate`; se não sobrar nenhuma ocorrência, é apagada.
 */
export class EndCommitmentBefore implements UseCase<EndCommitmentBeforeIn, void> {
  constructor(private readonly commitmentRepository: CommitmentRepository) {}

  async execute(input: EndCommitmentBeforeIn): Promise<void> {
    const existing = await findOwnedCommitment(
      this.commitmentRepository,
      input.userId,
      input.commitmentId,
    );
    validateFromDate(input.fromDate);

    const ended = existing.endingBefore(input.fromDate);
    if (!ended) {
      await this.commitmentRepository.delete(input.userId, existing.id);
      return;
    }

    ended.validate();
    await this.commitmentRepository.update(ended);
  }
}
