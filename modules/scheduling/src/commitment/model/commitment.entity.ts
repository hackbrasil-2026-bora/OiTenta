import {
  Entity,
  EntityState,
  InRule,
  IntegerRule,
  RangeLengthRule,
  RangeValueRule,
  RequiredRule,
  UniqueItemsRule,
  UuidRule,
  ValidationField,
  ValidationRule,
  Validator,
} from "@oitenta/shared";
import { addDays, LocalDateRule, localDateRules, MultipleOfRule, weekdayOf } from "../../common";

export type CommitmentKind = "commitment";
export type CommitmentCategory = "aula" | "trabalho" | "saude" | "pessoal";
export type CommitmentExceptionType = "cancelled" | "moved";

export const COMMITMENT_CATEGORIES: readonly CommitmentCategory[] = [
  "aula",
  "trabalho",
  "saude",
  "pessoal",
];
export const COMMITMENT_EXCEPTION_TYPES: readonly CommitmentExceptionType[] = [
  "cancelled",
  "moved",
];
export const COMMITMENT_TITLE_MIN_LENGTH = 2;
export const COMMITMENT_TITLE_MAX_LENGTH = 80;
/** Horários do compromisso em múltiplos de 5 min (MC2). */
export const COMMITMENT_MINUTE_STEP = 5;
const MINUTES_IN_DAY = 1440;
const LAST_START_MINUTE = MINUTES_IN_DAY - COMMITMENT_MINUTE_STEP;
const DAYS_IN_WEEK = 7;

/** Recorrência semanal (subconjunto BYDAY da RRULE, D 4e). */
export interface CommitmentRecurrence {
  weekdays: number[];
  endDate?: string;
}

/**
 * Exceção de um dia da série (MC1): a ocorrência de `date` foi cancelada ou
 * movida para `newDate`, `startMinute`–`endMinute`.
 */
export interface CommitmentException {
  date: string;
  type: CommitmentExceptionType;
  newDate?: string;
  startMinute?: number;
  endMinute?: number;
}

export interface CommitmentState extends EntityState {
  userId: string;
  title: string;
  category: CommitmentCategory;
  kind: CommitmentKind;
  startDate: string;
  startMinute: number;
  endMinute: number;
  recurrence: CommitmentRecurrence | null;
  exceptions: CommitmentException[];
}

/**
 * Campos que a edição da série ("todas" ou "desse dia em diante") pode trocar.
 * `undefined` = mantém; em `recurrence`, `null` = vira compromisso único.
 */
export type CommitmentChanges = Partial<
  Pick<
    CommitmentState,
    "title" | "category" | "startDate" | "startMinute" | "endMinute" | "recurrence"
  >
>;

export interface CommitmentSplit {
  previous: Commitment | null;
  next: Commitment;
}

function startMinuteRules(): ValidationRule[] {
  return [
    new RequiredRule(),
    new IntegerRule(),
    new RangeValueRule(0, LAST_START_MINUTE),
    new MultipleOfRule(COMMITMENT_MINUTE_STEP),
  ];
}

/** Fim no mesmo dia: `startMinute < endMinute ≤ 1440`, múltiplo de 5 (sem cruzar a meia-noite). */
function endMinuteRules(startMinute: unknown): ValidationRule[] {
  const afterStartRule: ValidationRule = {
    validate: (value) =>
      typeof value === "number" && typeof startMinute === "number" && value <= startMinute
        ? "after.start"
        : null,
  };

  return [
    new RequiredRule(),
    new IntegerRule(),
    new RangeValueRule(0, MINUTES_IN_DAY),
    new MultipleOfRule(COMMITMENT_MINUTE_STEP),
    afterStartRule,
  ];
}

const notAllowedRule: ValidationRule = {
  validate: (value) => (value === undefined || value === null ? null : "not.allowed"),
};

const uniqueDatesRule: ValidationRule = {
  validate: (value) => {
    const dates = value as string[];
    return new Set(dates).size === dates.length ? null : "unique";
  },
};

function definedChanges(changes: CommitmentChanges): CommitmentChanges {
  return Object.fromEntries(
    Object.entries(changes).filter(([, value]) => value !== undefined),
  ) as CommitmentChanges;
}

function byDate(a: CommitmentException, b: CommitmentException): number {
  return a.date.localeCompare(b.date);
}

export class Commitment extends Entity<CommitmentState> {
  constructor(props: CommitmentState) {
    super(props);
  }

  get userId(): string {
    return this.props.userId;
  }

  get title(): string {
    return this.props.title;
  }

  get category(): CommitmentCategory {
    return this.props.category;
  }

  get kind(): CommitmentKind {
    return this.props.kind;
  }

  get startDate(): string {
    return this.props.startDate;
  }

  get startMinute(): number {
    return this.props.startMinute;
  }

  get endMinute(): number {
    return this.props.endMinute;
  }

  get recurrence(): CommitmentRecurrence | null {
    return this.props.recurrence;
  }

  get exceptions(): CommitmentException[] {
    return this.props.exceptions.map((exception) => ({ ...exception }));
  }

  /** A série tem ocorrência nessa data local (sem considerar as exceções)? */
  occursOn(date: string): boolean {
    const recurrence = this.recurrence;
    if (recurrence === null) {
      return date === this.startDate;
    }

    const endDate = recurrence.endDate;
    return (
      date >= this.startDate &&
      (!endDate || date <= endDate) &&
      recurrence.weekdays.includes(weekdayOf(date))
    );
  }

  /** Clone com a exceção daquela data (troca a anterior, se houver). */
  withException(exception: CommitmentException): Commitment {
    const others = this.exceptions.filter((item) => item.date !== exception.date);
    return this.clone({ exceptions: [...others, { ...exception }].sort(byDate) });
  }

  /** Clone sem a exceção daquela data. */
  withoutException(date: string): Commitment {
    return this.clone({ exceptions: this.exceptions.filter((item) => item.date !== date) });
  }

  /**
   * Clone com os campos definidos de `changes` (escopo "todas"). As exceções que
   * deixaram de ser ocorrências da série são descartadas.
   */
  withChanges(changes: CommitmentChanges): Commitment {
    const changed = this.clone(definedChanges(changes));
    return changed.clone({
      exceptions: changed.exceptions.filter((item) => changed.occursOn(item.date)),
      updatedAt: changed.updatedAt,
    });
  }

  /**
   * Série encerrada no dia anterior a `date`, só com as exceções anteriores.
   * Devolve `null` no compromisso único ou se não sobrar nenhuma ocorrência.
   */
  endingBefore(date: string): Commitment | null {
    const recurrence = this.recurrence;
    if (recurrence === null) {
      return null;
    }

    const dayBefore = addDays(date, -1);
    const endDate =
      recurrence.endDate && recurrence.endDate < dayBefore ? recurrence.endDate : dayBefore;
    const ended = this.clone({
      recurrence: { ...recurrence, endDate },
      exceptions: this.exceptions.filter((item) => item.date < date),
    });

    return ended.hasOccurrenceUntil(endDate) ? ended : null;
  }

  /**
   * "Desse dia em diante" (MC12): a série atual termina antes de `date` e uma
   * nova (id novo) começa em `date`, com as mudanças e as exceções a partir dela.
   */
  splitFrom(date: string, changes: Omit<CommitmentChanges, "startDate"> = {}): CommitmentSplit {
    const recurrence = this.recurrence;
    const base = new Commitment({
      userId: this.userId,
      title: this.title,
      category: this.category,
      kind: this.kind,
      startDate: date,
      startMinute: this.startMinute,
      endMinute: this.endMinute,
      recurrence: recurrence === null ? null : { ...recurrence },
      exceptions: this.exceptions.filter((item) => item.date >= date),
    });

    return { previous: this.endingBefore(date), next: base.withChanges(changes) };
  }

  public validate(): void {
    Validator.validate([
      {
        code: "commitment.userId",
        value: this.userId,
        rules: [new RequiredRule(), new UuidRule()],
      },
      {
        code: "commitment.title",
        value: this.title.trim(),
        rules: [
          new RequiredRule(),
          new RangeLengthRule(COMMITMENT_TITLE_MIN_LENGTH, COMMITMENT_TITLE_MAX_LENGTH),
        ],
      },
      {
        code: "commitment.category",
        value: this.category,
        rules: [new RequiredRule(), new InRule(COMMITMENT_CATEGORIES)],
      },
      {
        code: "commitment.kind",
        value: this.kind,
        rules: [new RequiredRule(), new InRule(["commitment"])],
      },
      {
        code: "commitment.startDate",
        value: this.startDate,
        rules: localDateRules(),
      },
      {
        code: "commitment.startMinute",
        value: this.startMinute,
        rules: startMinuteRules(),
      },
      {
        code: "commitment.endMinute",
        value: this.endMinute,
        rules: endMinuteRules(this.startMinute),
      },
      ...this.recurrenceFields(),
      ...this.exceptionFields(),
    ]);
  }

  private hasOccurrenceUntil(lastDate: string): boolean {
    let date = this.startDate;
    for (let day = 0; day < DAYS_IN_WEEK && date <= lastDate; day++) {
      if (this.occursOn(date)) {
        return true;
      }
      date = addDays(date, 1);
    }
    return false;
  }

  private recurrenceFields(): ValidationField[] {
    const recurrence = this.recurrence;
    if (recurrence === null) {
      return [];
    }

    const startDate = this.startDate;
    const localDateRule = new LocalDateRule();
    const notBeforeStartRule: ValidationRule = {
      validate: (value) =>
        localDateRule.validate(value) === null && (value as string) < startDate
          ? "before.start"
          : null,
    };

    return [
      {
        code: "commitment.recurrence.weekdays",
        value: recurrence.weekdays,
        rules: [
          new RequiredRule(),
          new IntegerRule(),
          new RangeValueRule(0, 6),
          new UniqueItemsRule(),
        ],
      },
      {
        code: "commitment.recurrence.endDate",
        value: recurrence.endDate,
        rules: [localDateRule, notBeforeStartRule],
      },
    ];
  }

  private exceptionFields(): ValidationField[] {
    const exceptions = this.props.exceptions;
    const localDateRule = new LocalDateRule();
    // Só confere a série quando a data está preenchida e bem formada (os outros erros já acusam).
    const occurrenceRule: ValidationRule = {
      validate: (value) =>
        typeof value === "string" &&
        value !== "" &&
        localDateRule.validate(value) === null &&
        !this.occursOn(value)
          ? "not.occurrence"
          : null,
    };

    return [
      ...exceptions.flatMap((exception): ValidationField[] => [
        {
          code: "commitment.exceptions.date",
          value: exception.date,
          rules: [...localDateRules(), occurrenceRule],
        },
        {
          code: "commitment.exceptions.type",
          value: exception.type,
          rules: [new RequiredRule(), new InRule(COMMITMENT_EXCEPTION_TYPES)],
        },
        ...this.movedFields(exception),
      ]),
      {
        code: "commitment.exceptions.date",
        value: exceptions.map((exception) => exception.date),
        rules: [uniqueDatesRule],
      },
    ];
  }

  /** `moved` exige novo dia e horário; `cancelled` não aceita esses campos. */
  private movedFields(exception: CommitmentException): ValidationField[] {
    const moved = exception.type === "moved";

    return [
      {
        code: "commitment.exceptions.newDate",
        value: exception.newDate,
        rules: moved ? localDateRules() : [notAllowedRule],
      },
      {
        code: "commitment.exceptions.startMinute",
        value: exception.startMinute,
        rules: moved ? startMinuteRules() : [notAllowedRule],
      },
      {
        code: "commitment.exceptions.endMinute",
        value: exception.endMinute,
        rules: moved ? endMinuteRules(exception.startMinute) : [notAllowedRule],
      },
    ];
  }
}
