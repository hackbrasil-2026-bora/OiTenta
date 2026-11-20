import { NotFoundError, Validator } from "@oitenta/shared";
import { localDateRules } from "../../common";
import { Commitment } from "../model";
import { CommitmentRepository } from "../provider";

export const COMMITMENT_NOT_FOUND_MESSAGE = "Compromisso não encontrado.";

/** Compromisso do usuário; inexistente ou de outro usuário → `NotFoundError`. */
export async function findOwnedCommitment(
  repository: CommitmentRepository,
  userId: string,
  commitmentId: string,
): Promise<Commitment> {
  const commitment = await repository.findById(userId, commitmentId);
  if (!commitment) {
    throw new NotFoundError(COMMITMENT_NOT_FOUND_MESSAGE);
  }
  return commitment;
}

/** `fromDate` de "desse dia em diante" precisa ser uma data local `YYYY-MM-DD`. */
export function validateFromDate(fromDate: string): void {
  Validator.validate([{ code: "commitment.fromDate", value: fromDate, rules: localDateRules() }]);
}
