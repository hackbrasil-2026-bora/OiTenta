import { Injectable } from '@nestjs/common';
import { ListGoals } from '@oitenta/goals';
import { GetDayPlan } from '@oitenta/scheduling';
import { PrismaUserRepository } from '../modules/auth/user.prisma';
import { PrismaGoalRepository } from '../modules/goals/goal.prisma';
import { PrismaScheduledBlockRepository } from '../modules/scheduling/scheduled-block.prisma';
import { PrismaWeeklyAvailabilityRepository } from '../modules/scheduling/weekly-availability.prisma';
import { DayPlanView, loadGoalsOf, toDayPlanView } from './plan-block-view';
import { userTimezone } from './user-timezone';

export interface DayViewIn {
  userId: string;
  date: string;
}

// docs/3 §5: GetDayPlan + títulos dos objetivos e etapas (tela Hoje). Só encadeia casos de uso.
@Injectable()
export class DayViewOrchestrator {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly goalRepository: PrismaGoalRepository,
    private readonly blockRepository: PrismaScheduledBlockRepository,
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
  ) {}

  async execute(input: DayViewIn): Promise<DayPlanView> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    const day = await new GetDayPlan(
      this.blockRepository,
      this.availabilityRepository,
    ).execute({ userId: input.userId, date: input.date, timezone });
    // MC11: bloco passado de objetivo apagado fica no histórico, mas não aparece no dia.
    const { goals: existing } = await new ListGoals(
      this.goalRepository,
    ).execute({ userId: input.userId });
    const goalIds = new Set(existing.map((goal) => goal.id));
    const visible = {
      ...day,
      blocks: day.blocks.filter((block) => goalIds.has(block.goalId)),
    };
    const goals = await loadGoalsOf(this.goalRepository, input.userId, [
      visible,
    ]);
    return toDayPlanView(visible, goals);
  }
}
