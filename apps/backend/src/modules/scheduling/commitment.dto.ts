import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  COMMITMENT_CATEGORIES,
  COMMITMENT_EXCEPTION_TYPES,
} from '@oitenta/scheduling';
import type {
  Commitment,
  CommitmentCategory,
  CommitmentException,
  CommitmentExceptionType,
  CommitmentOccurrenceStatus,
  CommitmentOccurrenceView,
  CommitmentRecurrence,
} from '@oitenta/scheduling';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsIn,
  IsInt,
  IsObject,
  IsString,
  IsUUID,
  Matches,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

// Contrato: docs/4-contrato-api.md §5b (MC1–MC6, MC12). Os decorators checam só o formato (400, P19):
// tipos, listas fechadas e datas YYYY-MM-DD. Título 2–80, minutos múltiplos de 5, fim depois do
// início, dia da semana 0–6, data inexistente e data que não é ocorrência são do domínio (422).
const LOCAL_DATE = /^\d{4}-\d{2}-\d{2}$/;
const localDateMessage = (field: string) =>
  `${field} deve estar no formato YYYY-MM-DD`;

export const COMMITMENT_SCOPES = ['all', 'following'] as const;
export type CommitmentScope = (typeof COMMITMENT_SCOPES)[number];

// Campo opcional que, se vier, não pode ser null (só a recurrence aceita null).
const isPresent = (_: object, value: unknown) => value !== undefined;
const isFollowing = (body: { scope?: unknown; fromDate?: unknown }) =>
  body.scope === 'following' || body.fromDate !== undefined;

export class CommitmentRecurrenceBody implements CommitmentRecurrence {
  @ApiProperty({
    example: [0, 2],
    description: 'Dias da semana: 0 = segunda … 6 = domingo.',
  })
  @IsArray()
  @IsInt({ each: true })
  weekdays!: number[];

  @ApiPropertyOptional({
    example: '2026-12-12',
    description:
      'Último dia da série (data local YYYY-MM-DD); sem ele, não termina.',
  })
  @ValidateIf(isPresent)
  @Matches(LOCAL_DATE, { message: localDateMessage('endDate') })
  endDate?: string;
}

export class CreateCommitmentBody {
  @ApiProperty({
    example: 'Aula de Cálculo',
    description: '2 a 80 caracteres.',
  })
  @IsString()
  title!: string;

  @ApiProperty({ enum: COMMITMENT_CATEGORIES })
  @IsIn([...COMMITMENT_CATEGORIES])
  category!: CommitmentCategory;

  @ApiProperty({
    example: '2026-11-23',
    description:
      'Data local YYYY-MM-DD do compromisso único ou do início da série.',
  })
  @Matches(LOCAL_DATE, { message: localDateMessage('startDate') })
  startDate!: string;

  @ApiProperty({
    example: 480,
    description: 'Minutos desde 00:00, múltiplo de 5 (MC2).',
  })
  @IsInt()
  startMinute!: number;

  @ApiProperty({
    example: 580,
    description: 'Minutos desde 00:00, múltiplo de 5, depois do início.',
  })
  @IsInt()
  endMinute!: number;

  @ApiProperty({
    type: CommitmentRecurrenceBody,
    nullable: true,
    description: 'null = compromisso único.',
  })
  @ValidateIf((_, value) => value !== null)
  @IsObject()
  @ValidateNested()
  @Type(() => CommitmentRecurrenceBody)
  recurrence!: CommitmentRecurrenceBody | null;
}

export class UpdateCommitmentBody {
  @ApiProperty({
    enum: COMMITMENT_SCOPES,
    description:
      '"all" = a série toda; "following" = desse dia em diante (MC12).',
  })
  @IsIn([...COMMITMENT_SCOPES])
  scope!: CommitmentScope;

  @ApiPropertyOptional({
    example: '2026-11-25',
    description: 'Obrigatório em "following": primeiro dia da série nova.',
  })
  @ValidateIf(isFollowing)
  @Matches(LOCAL_DATE, { message: localDateMessage('fromDate') })
  fromDate?: string;

  @ApiPropertyOptional({ example: 'Aula de Cálculo II' })
  @ValidateIf(isPresent)
  @IsString()
  title?: string;

  @ApiPropertyOptional({ enum: COMMITMENT_CATEGORIES })
  @ValidateIf(isPresent)
  @IsIn([...COMMITMENT_CATEGORIES])
  category?: CommitmentCategory;

  @ApiPropertyOptional({
    example: '2026-11-23',
    description:
      'Só no escopo "all" (em "following" a série nova começa em fromDate).',
  })
  @ValidateIf(isPresent)
  @Matches(LOCAL_DATE, { message: localDateMessage('startDate') })
  startDate?: string;

  @ApiPropertyOptional({ example: 480 })
  @ValidateIf(isPresent)
  @IsInt()
  startMinute?: number;

  @ApiPropertyOptional({ example: 580 })
  @ValidateIf(isPresent)
  @IsInt()
  endMinute?: number;

  @ApiPropertyOptional({
    type: CommitmentRecurrenceBody,
    nullable: true,
    description:
      'Ausente = mantém; null = vira compromisso único; objeto = nova recorrência.',
  })
  @ValidateIf((_, value) => value !== undefined && value !== null)
  @IsObject()
  @ValidateNested()
  @Type(() => CommitmentRecurrenceBody)
  recurrence?: CommitmentRecurrenceBody | null;
}

export class DeleteCommitmentQuery {
  @ApiProperty({ enum: COMMITMENT_SCOPES })
  @IsIn([...COMMITMENT_SCOPES])
  scope!: CommitmentScope;

  @ApiPropertyOptional({
    example: '2026-11-25',
    description:
      'Obrigatório em "following": a partir desse dia não há mais ocorrência.',
  })
  @ValidateIf(isFollowing)
  @Matches(LOCAL_DATE, { message: localDateMessage('fromDate') })
  fromDate?: string;
}

export class CommitmentOccurrencesQuery {
  @ApiProperty({ example: '2026-11-23', description: 'Data local YYYY-MM-DD.' })
  @Matches(LOCAL_DATE, { message: localDateMessage('from') })
  from!: string;

  @ApiProperty({
    example: '2026-11-29',
    description: 'Data local YYYY-MM-DD; no máximo 62 dias depois de from.',
  })
  @Matches(LOCAL_DATE, { message: localDateMessage('to') })
  to!: string;
}

export class CommitmentIdParams {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  id!: string;
}

export class CommitmentOccurrenceParams extends CommitmentIdParams {
  @ApiProperty({
    example: '2026-11-25',
    description: 'Dia da série (data local).',
  })
  @Matches(LOCAL_DATE, { message: localDateMessage('date') })
  date!: string;
}

export class SetOccurrenceBody {
  @ApiProperty({
    enum: COMMITMENT_EXCEPTION_TYPES,
    description:
      '"cancelled" = não vai ter; "moved" = horário alterado (pede newDate e horários).',
  })
  @IsIn([...COMMITMENT_EXCEPTION_TYPES])
  status!: CommitmentExceptionType;

  @ApiPropertyOptional({ example: '2026-11-26' })
  @ValidateIf(isPresent)
  @Matches(LOCAL_DATE, { message: localDateMessage('newDate') })
  newDate?: string;

  @ApiPropertyOptional({ example: 600 })
  @ValidateIf(isPresent)
  @IsInt()
  startMinute?: number;

  @ApiPropertyOptional({ example: 700 })
  @ValidateIf(isPresent)
  @IsInt()
  endMinute?: number;
}

export class CommitmentExceptionView implements CommitmentException {
  @ApiProperty({ example: '2026-11-25' })
  date!: string;

  @ApiProperty({ enum: COMMITMENT_EXCEPTION_TYPES })
  type!: CommitmentExceptionType;

  @ApiPropertyOptional({ example: '2026-11-26' })
  newDate?: string;

  @ApiPropertyOptional({ example: 600 })
  startMinute?: number;

  @ApiPropertyOptional({ example: 700 })
  endMinute?: number;
}

export class CommitmentRecurrenceView implements CommitmentRecurrence {
  @ApiProperty({ example: [0, 2] })
  weekdays!: number[];

  @ApiPropertyOptional({ example: '2026-12-12' })
  endDate?: string;
}

export class CommitmentView {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ example: 'Aula de Cálculo' })
  title!: string;

  @ApiProperty({ enum: COMMITMENT_CATEGORIES })
  category!: CommitmentCategory;

  @ApiProperty({ example: '2026-11-23' })
  startDate!: string;

  @ApiProperty({ example: 480 })
  startMinute!: number;

  @ApiProperty({ example: 580 })
  endMinute!: number;

  @ApiProperty({ type: CommitmentRecurrenceView, nullable: true })
  recurrence!: CommitmentRecurrenceView | null;

  @ApiProperty({ type: [CommitmentExceptionView] })
  exceptions!: CommitmentExceptionView[];
}

export class CommitmentResponse {
  @ApiProperty({ type: CommitmentView })
  commitment!: CommitmentView;
}

export class CommitmentOccurrenceResponse implements CommitmentOccurrenceView {
  @ApiProperty({ format: 'uuid' })
  commitmentId!: string;

  @ApiProperty({ example: 'Aula de Cálculo' })
  title!: string;

  @ApiProperty({ enum: COMMITMENT_CATEGORIES })
  category!: CommitmentCategory;

  @ApiProperty({
    example: '2026-11-25',
    description: 'Dia em que acontece (na movida, o novo dia).',
  })
  date!: string;

  @ApiProperty({
    example: '2026-11-25',
    description: 'Dia da série de onde veio.',
  })
  originalDate!: string;

  @ApiProperty({ example: 480 })
  startMinute!: number;

  @ApiProperty({ example: 580 })
  endMinute!: number;

  @ApiProperty({ enum: ['normal', 'cancelled', 'moved'] })
  status!: CommitmentOccurrenceStatus;

  @ApiProperty({ type: CommitmentRecurrenceView, nullable: true })
  recurrence!: CommitmentRecurrenceView | null;
}

export class CommitmentOccurrencesResponse {
  @ApiProperty({ type: [CommitmentOccurrenceResponse] })
  occurrences!: CommitmentOccurrenceResponse[];
}

// Corpo → entrada do caso de uso, sem as instâncias de classe do class-transformer.
export function toRecurrence(
  recurrence: CommitmentRecurrence | null,
): CommitmentRecurrence | null;
export function toRecurrence(
  recurrence: CommitmentRecurrence | null | undefined,
): CommitmentRecurrence | null | undefined;
export function toRecurrence(
  recurrence: CommitmentRecurrence | null | undefined,
): CommitmentRecurrence | null | undefined {
  if (!recurrence) {
    return recurrence;
  }
  return {
    weekdays: [...recurrence.weekdays],
    ...(recurrence.endDate !== undefined
      ? { endDate: recurrence.endDate }
      : {}),
  };
}

export function toCommitmentView(commitment: Commitment): CommitmentView {
  return {
    id: commitment.id,
    title: commitment.title,
    category: commitment.category,
    startDate: commitment.startDate,
    startMinute: commitment.startMinute,
    endMinute: commitment.endMinute,
    recurrence: toRecurrence(commitment.recurrence),
    exceptions: commitment.exceptions.map((exception) => ({
      date: exception.date,
      type: exception.type,
      ...(exception.newDate !== undefined
        ? { newDate: exception.newDate }
        : {}),
      ...(exception.startMinute !== undefined
        ? { startMinute: exception.startMinute }
        : {}),
      ...(exception.endMinute !== undefined
        ? { endMinute: exception.endMinute }
        : {}),
    })),
  };
}

export function toOccurrencesResponse(
  occurrences: CommitmentOccurrenceView[],
): CommitmentOccurrencesResponse {
  return {
    occurrences: occurrences.map((occurrence) => ({
      commitmentId: occurrence.commitmentId,
      title: occurrence.title,
      category: occurrence.category,
      date: occurrence.date,
      originalDate: occurrence.originalDate,
      startMinute: occurrence.startMinute,
      endMinute: occurrence.endMinute,
      status: occurrence.status,
      recurrence: toRecurrence(occurrence.recurrence),
    })),
  };
}
