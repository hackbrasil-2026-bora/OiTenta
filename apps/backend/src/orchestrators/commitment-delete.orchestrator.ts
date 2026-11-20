import { Inject, Injectable } from '@nestjs/common';
import {
  CommitmentBusySource,
  DeleteCommitment,
  EndCommitmentBefore,
} from '@oitenta/scheduling';
import type { BusySource } from '@oitenta/scheduling';
import { PrismaUserRepository } from '../modules/auth/user.prisma';
import { PrismaGoalRepository } from '../modules/goals/goal.prisma';
import type { CommitmentScope } from '../modules/scheduling/commitment.dto';
import { PrismaCommitmentRepository } from '../modules/scheduling/commitment.prisma';
import { PrismaScheduledBlockRepository } from '../modules/scheduling/scheduled-block.prisma';
import { PrismaWeeklyAvailabilityRepository } from '../modules/scheduling/weekly-availability.prisma';
import { PlanView } from './plan-input';
import { regeneratePlan } from './plan-regeneration';
import { userTimezone } from './user-timezone';

export interface CommitmentDeleteIn {
  userId: string;
  commitmentId: string;
  scope: CommitmentScope;
  fromDate?: string;
}

export interface CommitmentDeleteOut {
  plan: PlanView;
}

// docs/4 §5b: DeleteCommitment ("all") ou EndCommitmentBefore ("following", MC12) → GeneratePlan.
@Injectable()
export class CommitmentDeleteOrchestrator {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly goalRepository: PrismaGoalRepository,
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
    private readonly blockRepository: PrismaScheduledBlockRepository,
    private readonly commitmentRepository: PrismaCommitmentRepository,
    @Inject(CommitmentBusySource) private readonly busySource: BusySource,
  ) {}

  async execute(input: CommitmentDeleteIn): Promise<CommitmentDeleteOut> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    if (input.scope === 'following') {
      await new EndCommitmentBefore(this.commitmentRepository).execute({
        userId: input.userId,
        commitmentId: input.commitmentId,
        fromDate: input.fromDate as string,
      });
    } else {
      await new DeleteCommitment(this.commitmentRepository).execute({
        userId: input.userId,
        commitmentId: input.commitmentId,
      });
    }
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
