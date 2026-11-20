import { Inject, Injectable } from '@nestjs/common';
import {
  ClearOccurrenceException,
  ClearOccurrenceExceptionIn,
  Commitment,
  CommitmentBusySource,
  SetOccurrenceException,
  SetOccurrenceExceptionIn,
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

export interface CommitmentOccurrenceOut {
  commitment: Commitment;
  plan: PlanView;
}

// docs/4 §5b (MC1): SetOccurrenceException ("Não vai ter", "Horário alterado") ou
// ClearOccurrenceException ("Vai ter sim", "Voltar pro horário normal") → GeneratePlan.
@Injectable()
export class CommitmentOccurrenceOrchestrator {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly goalRepository: PrismaGoalRepository,
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
    private readonly blockRepository: PrismaScheduledBlockRepository,
    private readonly commitmentRepository: PrismaCommitmentRepository,
    @Inject(CommitmentBusySource) private readonly busySource: BusySource,
  ) {}

  async set(input: SetOccurrenceExceptionIn): Promise<CommitmentOccurrenceOut> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    const { commitment } = await new SetOccurrenceException(
      this.commitmentRepository,
    ).execute(input);
    return { commitment, plan: await this.plan(input.userId, timezone) };
  }

  async clear(
    input: ClearOccurrenceExceptionIn,
  ): Promise<CommitmentOccurrenceOut> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    const { commitment } = await new ClearOccurrenceException(
      this.commitmentRepository,
    ).execute(input);
    return { commitment, plan: await this.plan(input.userId, timezone) };
  }

  private plan(userId: string, timezone: string): Promise<PlanView> {
    return regeneratePlan(
      {
        goalRepository: this.goalRepository,
        availabilityRepository: this.availabilityRepository,
        blockRepository: this.blockRepository,
        busySource: this.busySource,
      },
      userId,
      timezone,
    );
  }
}
