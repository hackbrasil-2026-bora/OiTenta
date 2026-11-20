import { UseCase, ValidationRule, Validator } from "@oitenta/shared";
import { addDays, localDateRules } from "../../common";
import {
  CommitmentCategory,
  CommitmentOccurrenceStatus,
  CommitmentRecurrence,
  RecurrenceExpander,
} from "../model";
import { CommitmentRepository } from "../provider";

/** Janela máxima da listagem, em dias contados com as duas pontas (MC4). */
export const MAX_OCCURRENCE_RANGE_DAYS = 62;

export interface ListCommitmentOccurrencesIn {
  userId: string;
  from: string;
  to: string;
}

export interface CommitmentOccurrenceView {
  commitmentId: string;
  title: string;
  category: CommitmentCategory;
  date: string;
  originalDate: string;
  startMinute: number;
  endMinute: number;
  status: CommitmentOccurrenceStatus;
  recurrence: CommitmentRecurrence | null;
}

export interface ListCommitmentOccurrencesOut {
  occurrences: CommitmentOccurrenceView[];
}

/** Ocorrências dos compromissos do usuário entre duas datas locais, com as exceções. */
export class ListCommitmentOccurrences
  implements UseCase<ListCommitmentOccurrencesIn, ListCommitmentOccurrencesOut>
{
  constructor(
    private readonly commitmentRepository: CommitmentRepository,
    private readonly expander: RecurrenceExpander = new RecurrenceExpander(),
  ) {}

  async execute(input: ListCommitmentOccurrencesIn): Promise<ListCommitmentOccurrencesOut> {
    this.validateRange(input.from, input.to);

    const commitments = await this.commitmentRepository.findAllByUser(input.userId);
    const occurrences = commitments.flatMap((commitment) =>
      this.expander.occurrences(commitment, input.from, input.to).map((occurrence) => ({
        commitmentId: commitment.id,
        title: commitment.title,
        category: commitment.category,
        ...occurrence,
        recurrence: commitment.recurrence,
      })),
    );

    return {
      occurrences: occurrences.sort(
        (a, b) => a.date.localeCompare(b.date) || a.startMinute - b.startMinute,
      ),
    };
  }

  private validateRange(from: string, to: string): void {
    Validator.validate([
      { code: "occurrences.from", value: from, rules: localDateRules() },
      { code: "occurrences.to", value: to, rules: localDateRules() },
    ]);

    const rangeRule: ValidationRule = {
      validate: () =>
        from <= to && to <= addDays(from, MAX_OCCURRENCE_RANGE_DAYS - 1) ? null : "range",
    };
    Validator.validate([{ code: "occurrences", value: null, rules: [rangeRule] }]);
  }
}
