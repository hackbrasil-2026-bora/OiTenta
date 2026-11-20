import { Inject, Injectable } from '@nestjs/common';
import { DeleteGoal, DeleteGoalIn } from '@oitenta/goals';
import { CommitmentBusySource } from '@oitenta/scheduling';
import type { BusySource } from '@oitenta/scheduling';
import { PrismaUserRepository } from '../modules/auth/user.prisma';
import { PrismaGoalRepository } from '../modules/goals/goal.prisma';
import { PrismaScheduledBlockRepository } from '../modules/scheduling/scheduled-block.prisma';
import { PrismaWeeklyAvailabilityRepository } from '../modules/scheduling/weekly-availability.prisma';
import { PlanView } from './plan-input';
import { regeneratePlan } from './plan-regeneration';
import { userTimezone } from './user-timezone';

export interface GoalDeleteOrchestratorOut {
  plan: PlanView;
}

// docs/4 §3 (MC11): DeleteGoal → (ListGoals + GetGoal) → GeneratePlan.
// O recálculo troca os blocos futuros e tira os do objetivo apagado; blocos e sessões
// passados ficam no histórico (o plano do dia e da semana ignora esses blocos).
@Injectable()
export class GoalDeleteOrchestrator {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly goalRepository: PrismaGoalRepository,
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
    private readonly blockRepository: PrismaScheduledBlockRepository,
    @Inject(CommitmentBusySource) private readonly busySource: BusySource,
  ) {}

  async execute(input: DeleteGoalIn): Promise<GoalDeleteOrchestratorOut> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    await new DeleteGoal(this.goalRepository).execute(input);
    const plan = await regeneratePlan(
      {
        goalRepository: this.goalRepository,
        availabilityRepository: this.availabilityRepository,
        blockRepository: this.blockRepository,
        busySource: this.busySource,
      },
      input.userId,
      timezone,
    );
    return { plan };
  }
}
