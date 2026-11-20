import { Module } from '@nestjs/common';
import { CommitmentBusySource } from '@oitenta/scheduling';
import { DbModule } from '../../db/db.module';
import { PrismaCommitmentRepository } from './commitment.prisma';
import { PrismaScheduledBlockRepository } from './scheduled-block.prisma';
import { SchedulingController } from './scheduling.controller';
import { PrismaWeeklyAvailabilityRepository } from './weekly-availability.prisma';

// A ocupação do plano vem dos compromissos do usuário (MC1; atualização da P8).
@Module({
  imports: [DbModule],
  controllers: [SchedulingController],
  providers: [
    PrismaWeeklyAvailabilityRepository,
    PrismaScheduledBlockRepository,
    PrismaCommitmentRepository,
    {
      provide: CommitmentBusySource,
      inject: [PrismaCommitmentRepository],
      useFactory: (repository: PrismaCommitmentRepository) =>
        new CommitmentBusySource(repository),
    },
  ],
  exports: [
    PrismaWeeklyAvailabilityRepository,
    PrismaScheduledBlockRepository,
    PrismaCommitmentRepository,
    CommitmentBusySource,
  ],
})
export class SchedulingModule {}
