import { NotFoundError, UseCase, ValidationError, ValidationException } from "@oitenta/shared";
import { Step } from "../model";
import { GoalRepository } from "../provider";
import { GoalView, toGoalView } from "./goal-view";

export interface SetSingleTaskDoneIn {
  userId: string;
  goalId: string;
  done: boolean;
}

export interface SetSingleTaskDoneOut {
  goal: GoalView;
}

/** Marca ou desmarca uma tarefa única como feita, sem sessão de foco (MC10). */
export class SetSingleTaskDone implements UseCase<SetSingleTaskDoneIn, SetSingleTaskDoneOut> {
  constructor(private readonly goalRepository: GoalRepository) {}

  async execute(input: SetSingleTaskDoneIn): Promise<SetSingleTaskDoneOut> {
    const goal = await this.goalRepository.findById(input.userId, input.goalId);
    if (!goal) {
      throw new NotFoundError("Objetivo não encontrado.");
    }

    if (goal.kind !== "single") {
      throw new ValidationException([new ValidationError("goal.kind.single")]);
    }

    const step = goal.steps[0] as Step;
    const updated = goal.withStep(step.withProgress(input.done ? 100 : 0));
    updated.validate();

    await this.goalRepository.update(updated);

    return { goal: toGoalView(updated) };
  }
}
