import { Injectable } from '@nestjs/common';
import {
  Commitment,
  CommitmentCategory,
  CommitmentException,
  CommitmentExceptionType,
  CommitmentKind,
  CommitmentRepository,
} from '@oitenta/scheduling';
import { NotFoundError } from '@oitenta/shared';
import {
  Commitment as CommitmentRecord,
  CommitmentException as CommitmentExceptionRecord,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../../db/prisma.service';

type CommitmentWithExceptions = CommitmentRecord & {
  exceptions: CommitmentExceptionRecord[];
};

const NOT_FOUND_MESSAGE = 'Compromisso não encontrado.';

// MC1: a série em `commitments` e as exceções por dia na tabela filha `commitment_exceptions`.
// Todo acesso é escopado pelo dono (userId), inclusive o update e o delete (R arquitetura-limpa).
@Injectable()
export class PrismaCommitmentRepository implements CommitmentRepository {
  constructor(private readonly prisma: PrismaService) {}

  private readonly withExceptions = {
    exceptions: { orderBy: { date: 'asc' } },
  } satisfies Prisma.CommitmentInclude;

  async create(data: Commitment): Promise<Commitment> {
    const created = await this.prisma.commitment.create({
      data: {
        ...this.toPersistence(data),
        exceptions: { create: this.toExceptionData(data.exceptions) },
      },
      include: this.withExceptions,
    });
    return this.toDomain(created);
  }

  // Regrava o agregado: a série e todas as exceções, numa transação.
  async update(data: Commitment): Promise<Commitment> {
    const updated = await this.prisma.$transaction(async (tx) => {
      const { id, userId, ...series } = this.toPersistence(data);
      const { count } = await tx.commitment.updateMany({
        where: { id, userId, deletedAt: null },
        data: series,
      });
      if (count === 0) {
        throw new NotFoundError(NOT_FOUND_MESSAGE);
      }

      await tx.commitmentException.deleteMany({ where: { commitmentId: id } });
      await tx.commitmentException.createMany({
        data: this.toExceptionData(data.exceptions).map((exception) => ({
          ...exception,
          commitmentId: id,
        })),
      });

      return tx.commitment.findFirstOrThrow({
        where: { id, userId },
        include: this.withExceptions,
      });
    });
    return this.toDomain(updated);
  }

  // Apaga a série do dono; as exceções saem pela cascata do banco.
  async delete(userId: string, id: string): Promise<void> {
    const { count } = await this.prisma.commitment.deleteMany({
      where: { id, userId },
    });
    if (count === 0) {
      throw new NotFoundError(NOT_FOUND_MESSAGE);
    }
  }

  async findById(userId: string, id: string): Promise<Commitment | null> {
    const found = await this.prisma.commitment.findFirst({
      where: { id, userId, deletedAt: null },
      include: this.withExceptions,
    });
    return found ? this.toDomain(found) : null;
  }

  async findAllByUser(userId: string): Promise<Commitment[]> {
    const found = await this.prisma.commitment.findMany({
      where: { userId, deletedAt: null },
      include: this.withExceptions,
      orderBy: { createdAt: 'asc' },
    });
    return found.map((commitment) => this.toDomain(commitment));
  }

  private toPersistence(commitment: Commitment): CommitmentRecord {
    const recurrence = commitment.recurrence;
    return {
      id: commitment.id,
      userId: commitment.userId,
      title: commitment.title,
      category: commitment.category,
      kind: commitment.kind,
      startDate: commitment.startDate,
      startMinute: commitment.startMinute,
      endMinute: commitment.endMinute,
      recurring: recurrence !== null,
      recurrenceWeekdays: recurrence ? [...recurrence.weekdays] : [],
      recurrenceEndDate: recurrence?.endDate ?? null,
      createdAt: commitment.createdAt,
      updatedAt: commitment.updatedAt,
      deletedAt: commitment.deletedAt ?? null,
    };
  }

  private toExceptionData(
    exceptions: CommitmentException[],
  ): Prisma.CommitmentExceptionCreateWithoutCommitmentInput[] {
    return exceptions.map((exception) => ({
      date: exception.date,
      type: exception.type,
      newDate: exception.newDate ?? null,
      startMinute: exception.startMinute ?? null,
      endMinute: exception.endMinute ?? null,
    }));
  }

  private toDomain(raw: CommitmentWithExceptions): Commitment {
    return new Commitment({
      id: raw.id,
      userId: raw.userId,
      title: raw.title,
      category: raw.category as CommitmentCategory,
      kind: raw.kind as CommitmentKind,
      startDate: raw.startDate,
      startMinute: raw.startMinute,
      endMinute: raw.endMinute,
      recurrence: raw.recurring
        ? {
            weekdays: [...raw.recurrenceWeekdays],
            ...(raw.recurrenceEndDate ? { endDate: raw.recurrenceEndDate } : {}),
          }
        : null,
      exceptions: raw.exceptions.map((exception) => this.toExceptionDomain(exception)),
      createdAt: raw.createdAt,
      updatedAt: raw.updatedAt,
      deletedAt: raw.deletedAt,
    });
  }

  private toExceptionDomain(raw: CommitmentExceptionRecord): CommitmentException {
    const exception: CommitmentException = {
      date: raw.date,
      type: raw.type as CommitmentExceptionType,
    };
    if (raw.newDate !== null) exception.newDate = raw.newDate;
    if (raw.startMinute !== null) exception.startMinute = raw.startMinute;
    if (raw.endMinute !== null) exception.endMinute = raw.endMinute;
    return exception;
  }
}
