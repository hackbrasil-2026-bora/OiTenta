import {
  AvailabilityWindow,
  Commitment,
  CommitmentState,
  ScheduledBlock,
  ScheduledBlockState,
  WeeklyAvailability,
} from "../../src";
import { GOAL_1, stepId, USER_A } from "./ids";

export const EVERY_EVENING: AvailabilityWindow[] = [0, 1, 2, 3, 4, 5, 6].map((weekday) => ({
  weekday,
  startMinute: 19 * 60,
  endMinute: 23 * 60,
}));

export function makeAvailability(
  userId = USER_A,
  dailyLimitMinutes = 120,
  windows: AvailabilityWindow[] = EVERY_EVENING,
): WeeklyAvailability {
  return new WeeklyAvailability({ userId, windows, dailyLimitMinutes });
}

export function makeBlock(overrides: Partial<ScheduledBlockState> = {}): ScheduledBlock {
  return new ScheduledBlock({
    userId: USER_A,
    goalId: GOAL_1,
    stepId: stepId(1),
    start: new Date("2026-11-10T22:00:00.000Z"),
    end: new Date("2026-11-10T23:00:00.000Z"),
    status: "planned",
    pinned: false,
    origin: "auto",
    ...overrides,
  });
}

/** Compromisso recorrente padrão: "Aula de violão", toda terça, 19:00–20:00, desde 04/11/2025. */
export function makeCommitmentState(overrides: Partial<CommitmentState> = {}): CommitmentState {
  return {
    userId: USER_A,
    title: "Aula de violão",
    category: "pessoal",
    kind: "commitment",
    startDate: "2025-11-04",
    startMinute: 19 * 60,
    endMinute: 20 * 60,
    recurrence: { weekdays: [1] },
    exceptions: [],
    ...overrides,
  };
}

export function makeCommitment(overrides: Partial<CommitmentState> = {}): Commitment {
  return new Commitment(makeCommitmentState(overrides));
}
