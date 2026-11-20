import { addDays, Interval, localToUtc } from "../../common";
import { Commitment } from "./commitment.entity";

export type CommitmentOccurrenceStatus = "normal" | "cancelled" | "moved";

/** Uma ocorrência em data local, já com a exceção do dia aplicada (MC1). */
export interface CommitmentOccurrence {
  /** Dia em que a ocorrência acontece (na `moved`, o `newDate`). */
  date: string;
  /** Dia da série de onde a ocorrência veio. */
  originalDate: string;
  startMinute: number;
  endMinute: number;
  status: CommitmentOccurrenceStatus;
}

function compareOccurrences(a: CommitmentOccurrence, b: CommitmentOccurrence): number {
  return a.date.localeCompare(b.date) || a.startMinute - b.startMinute;
}

/**
 * Expande um compromisso (único ou recorrente) nas ocorrências que caem entre
 * duas datas locais, inclusive (D 4e), aplicando as exceções por dia (MC1).
 */
export class RecurrenceExpander {
  /**
   * Ocorrências em datas locais, ordenadas por data e horário. A `cancelled`
   * aparece com o horário original; a `moved` aparece só no `newDate` (mesmo
   * que o dia original esteja fora da janela).
   */
  occurrences(commitment: Commitment, fromDate: string, toDate: string): CommitmentOccurrence[] {
    const exceptions = new Map(commitment.exceptions.map((item) => [item.date, item]));
    const recurrence = commitment.recurrence;
    const firstDate = fromDate > commitment.startDate ? fromDate : commitment.startDate;
    const seriesEnd = recurrence === null ? commitment.startDate : recurrence.endDate || toDate;
    const lastDate = seriesEnd < toDate ? seriesEnd : toDate;
    const result: CommitmentOccurrence[] = [];

    for (let date = firstDate; date <= lastDate; date = addDays(date, 1)) {
      const exception = exceptions.get(date);
      if (!commitment.occursOn(date) || exception?.type === "moved") {
        continue;
      }
      result.push({
        date,
        originalDate: date,
        startMinute: commitment.startMinute,
        endMinute: commitment.endMinute,
        status: exception ? "cancelled" : "normal",
      });
    }

    for (const exception of exceptions.values()) {
      const newDate = exception.newDate as string;
      if (exception.type !== "moved" || newDate < fromDate || newDate > toDate) {
        continue;
      }
      result.push({
        date: newDate,
        originalDate: exception.date,
        startMinute: exception.startMinute as number,
        endMinute: exception.endMinute as number,
        status: "moved",
      });
    }

    return result.sort(compareOccurrences);
  }

  /** Ocupação em UTC: ignora as canceladas e usa o horário movido. */
  expand(commitment: Commitment, fromDate: string, toDate: string, timezone: string): Interval[] {
    return this.occurrences(commitment, fromDate, toDate)
      .filter((occurrence) => occurrence.status !== "cancelled")
      .map((occurrence) => ({
        start: localToUtc(occurrence.date, occurrence.startMinute, timezone),
        end: localToUtc(occurrence.date, occurrence.endMinute, timezone),
      }));
  }
}
