import { Inject, Injectable } from '@nestjs/common';
import {
  GoalView,
  SetSingleTaskDone,
  SetSingleTaskDoneIn,
} from '@oitenta/goals';
import { CommitmentBusySource } from '@oitenta/scheduling';
import type { BusySource } from '@oitenta/scheduling';
import { PrismaUserRepository } from '../modules/auth/user.prisma';
import { PrismaGoalRepository } from '../modules/goals/goal.prisma';
import { PrismaScheduledBlockRepository } from '../modules/scheduling/scheduled-block.prisma';
import { PrismaWeeklyAvailabilityRepository } from '../modules/scheduling/weekly-availability.prisma';
import { PlanView } from './plan-input';
import { regeneratePlan } from './plan-regeneration';
import { userTimezone } from './user-timezone';

export interface SingleTaskDoneOrchestratorOut {
  goal: GoalView;
  plan: PlanView;
}

// docs/4 §3 (MC10): SetSingleTaskDone → (ListGoals + GetGoal) → GeneratePlan.
// A tarefa feita sai do plano (só os objetivos ativos entram); desfeita, volta.
@Injectable()
export class SingleTaskDoneOrchestrator {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly goalRepository: PrismaGoalRepository,
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
    private readonly blockRepository: PrismaScheduledBlockRepository,
    @Inject(CommitmentBusySource) private readonly busySource: BusySource,
  ) {}

  async execute(
    input: SetSingleTaskDoneIn,
  ): Promise<SingleTaskDoneOrchestratorOut> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    const { goal } = await new SetSingleTaskDone(this.goalRepository).execute(
      input,
    );
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
    return { goal, plan };
  }
}
