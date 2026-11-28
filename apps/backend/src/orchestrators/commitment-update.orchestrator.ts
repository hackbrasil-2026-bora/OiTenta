import { Inject, Injectable } from '@nestjs/common';
import {
  Commitment,
  CommitmentBusySource,
  CommitmentCategory,
  CommitmentRecurrence,
  SplitCommitmentFrom,
  UpdateCommitment,
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

export interface CommitmentUpdateIn {
  userId: string;
  commitmentId: string;
  scope: CommitmentScope;
  fromDate?: string;
  title?: string;
  category?: CommitmentCategory;
  startDate?: string;
  startMinute?: number;
  endMinute?: number;
  // Ausente = mantém; null = vira compromisso único; objeto = nova recorrência.
  recurrence?: CommitmentRecurrence | null;
}

export interface CommitmentUpdateOut {
  commitment: Commitment;
  plan: PlanView;
}

// docs/4 §5b: UpdateCommitment ("all") ou SplitCommitmentFrom ("following", MC12) → GeneratePlan.
// Em "following" a série nova começa em fromDate, então o startDate do corpo não se aplica.
@Injectable()
export class CommitmentUpdateOrchestrator {
  constructor(
    private readonly userRepository: PrismaUserRepository,
    private readonly goalRepository: PrismaGoalRepository,
    private readonly availabilityRepository: PrismaWeeklyAvailabilityRepository,
    private readonly blockRepository: PrismaScheduledBlockRepository,
    private readonly commitmentRepository: PrismaCommitmentRepository,
    @Inject(CommitmentBusySource) private readonly busySource: BusySource,
  ) {}

  async execute(input: CommitmentUpdateIn): Promise<CommitmentUpdateOut> {
    const timezone = await userTimezone(this.userRepository, input.userId);
    const changes = {
      userId: input.userId,
      commitmentId: input.commitmentId,
      title: input.title,
      category: input.category,
      startMinute: input.startMinute,
      endMinute: input.endMinute,
      recurrence: input.recurrence,
    };
    const { commitment } =
      input.scope === 'following'
        ? await new SplitCommitmentFrom(this.commitmentRepository).execute({
            ...changes,
            fromDate: input.fromDate as string,
          })
        : await new UpdateCommitment(this.commitmentRepository).execute({
            ...changes,
            startDate: input.startDate,
          });
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
