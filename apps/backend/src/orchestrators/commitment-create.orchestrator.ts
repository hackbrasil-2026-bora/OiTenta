import { Inject, Injectable } from '@nestjs/common';
import {
  Commitment,
  CommitmentBusySource,
  CreateCommitment,
  CreateCommitmentIn,
  GetWeeklyAvailability,
} from '@oitenta/scheduling';
import type { BusySource } from '@oitenta/scheduling';
import { PrismaUserRepository } from '../modules/auth/user.prisma';
import { PrismaGoalRepository } from '../modules/goals/goal.prisma';
import { PrismaCommitmentRepository } from '../modules/scheduling/commitment.prisma';
import { PrismaScheduledBlockRepository } from '../modules/scheduling/scheduled-block.prisma';
import { PrismaWeeklyAvailabilityRepository } from '../modules/scheduling/weekly-availability.prisma';
import { PlanView } from './plan-input';
import { regeneratePlan } from './plan-regeneration';
import { userTimezone } from './user-timezone';

export interface CommitmentCreateOut {
  commitment: Commitment;
  plan: PlanView;
}

// docs/4 §5b: CreateCommitment → GeneratePlan. A disponibilidade é lida antes de gravar,
// como no create-goal: sem ela o plano daria 404 (P12) com o compromisso já criado.
@Injectable()
export class CommitmentCreateOrchestrator {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly goalRepository: PrismaGoalRepository,
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
    private readonly blockRepository: PrismaScheduledBlockRepository,
    private readonly commitmentRepository: PrismaCommitmentRepository,
    @Inject(CommitmentBusySource) private readonly busySource: BusySource,
  ) {}

  async execute(input: CreateCommitmentIn): Promise<CommitmentCreateOut> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    await new GetWeeklyAvailability(this.availabilityRepository).execute({
      userId: input.userId,
    });
    const { commitment } = await new CreateCommitment(
      this.commitmentRepository,
    ).execute(input);
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
    return { commitment, plan };
  }
}
