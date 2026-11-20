import { UseCase } from "@oitenta/shared";
import { GoalColorIndex, GoalKind, GoalProgressCalculator, GoalStatus, Step } from "../model";
import { GoalRepository } from "../provider";

export interface ListGoalsIn {
  userId: string;
  /** Filtro opcional por tipo (MC8): Objetivos pede `goal`, Tarefas únicas pede `single`. */
  kind?: GoalKind;
}

export interface GoalListItem {
  id: string;
  title: string;
  deadline: string | null;
  kind: GoalKind;
  plannedDate: string | null;
  /** Soma das estimativas das etapas não `superseded`. */
  estimatedMinutes: number;
  colorIndex: GoalColorIndex;
  progressPct: number;
  done: number;
  total: number;
  status: GoalStatus;
  /** Desempate do plano entre objetivos com o mesmo prazo (PlanGoalInput.createdAt). */
  createdAt: Date;
}

export interface ListGoalsOut {
  goals: GoalListItem[];
}

function estimatedMinutes(steps: readonly Step[]): number {
  return steps
    .filter((step) => step.status !== "superseded")
    .reduce((total, step) => total + step.estimatedMinutes, 0);
}

export class ListGoals implements UseCase<ListGoalsIn, ListGoalsOut> {
  constructor(private readonly goalRepository: GoalRepository) {}

  async execute(input: ListGoalsIn): Promise<ListGoalsOut> {
    const goals = await this.goalRepository.findAllByUser(input.userId);
    const filtered = input.kind ? goals.filter((goal) => goal.kind === input.kind) : goals;

    return {
      goals: filtered.map((goal) => ({
        id: goal.id,
        title: goal.title,
        deadline: goal.deadline,
        kind: goal.kind,
        plannedDate: goal.plannedDate,
        estimatedMinutes: estimatedMinutes(goal.steps),
        colorIndex: goal.colorIndex,
        progressPct: GoalProgressCalculator.goalProgressPct(goal.steps),
        ...GoalProgressCalculator.summary(goal.steps),
        status: goal.status,
        createdAt: goal.createdAt,
      })),
    };
  }
}
