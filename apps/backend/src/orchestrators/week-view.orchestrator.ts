import { Injectable } from '@nestjs/common';
import { ListGoals } from '@oitenta/goals';
import { GetWeekPlan } from '@oitenta/scheduling';
import { PrismaUserRepository } from '../modules/auth/user.prisma';
import { PrismaGoalRepository } from '../modules/goals/goal.prisma';
import { PrismaScheduledBlockRepository } from '../modules/scheduling/scheduled-block.prisma';
import { PrismaWeeklyAvailabilityRepository } from '../modules/scheduling/weekly-availability.prisma';
import { DayPlanView, loadGoalsOf, toDayPlanView } from './plan-block-view';
import { userTimezone } from './user-timezone';

export interface WeekViewIn {
  userId: string;
  start: string;
}

export interface WeekView {
  days: DayPlanView[];
}

// docs/3 §5: GetWeekPlan + títulos dos objetivos e etapas (calendário). Só encadeia casos de uso.
@Injectable()
export class WeekViewOrchestrator {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly goalRepository: PrismaGoalRepository,
    private readonly blockRepository: PrismaScheduledBlockRepository,
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
  ) {}

  async execute(input: WeekViewIn): Promise<WeekView> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    const { days } = await new GetWeekPlan(
      this.blockRepository,
      this.availabilityRepository,
    ).execute({ userId: input.userId, weekStart: input.start, timezone });
    // MC11: bloco passado de objetivo apagado fica no histórico, mas não aparece na semana.
    const { goals: existing } = await new ListGoals(
      this.goalRepository,
    ).execute({ userId: input.userId });
    const goalIds = new Set(existing.map((goal) => goal.id));
    const visible = days.map((day) => ({
      ...day,
      blocks: day.blocks.filter((block) => goalIds.has(block.goalId)),
    }));
    const goals = await loadGoalsOf(this.goalRepository, input.userId, visible);
    return { days: visible.map((day) => toDayPlanView(day, goals)) };
  }
}
