import { NotFoundError, UseCase } from "@oitenta/shared";
import { GoalRepository } from "../provider";

export interface DeleteGoalIn {
  userId: string;
  goalId: string;
}

/** Apaga um objetivo (qualquer `kind`) e as etapas dele (MC11). */
export class DeleteGoal implements UseCase<DeleteGoalIn, void> {
  constructor(private readonly goalRepository: GoalRepository) {}

  async execute(input: DeleteGoalIn): Promise<void> {
    const goal = await this.goalRepository.findById(input.userId, input.goalId);
    if (!goal) {
      throw new NotFoundError("Objetivo não encontrado.");
    }

    await this.goalRepository.delete(input.userId, input.goalId);
  }
}
