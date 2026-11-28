import { addDays, Interval, toLocalParts } from "../../common";
import { BusySource } from "../../availability/provider/busy-source.provider";
import { CommitmentRepository } from "../provider/commitment.repository";
import { RecurrenceExpander } from "./recurrence-expander";

/** Ocupação vinda dos compromissos do usuário (único ou recorrentes), sem as ocorrências canceladas. */
export class CommitmentBusySource implements BusySource {
  constructor(
    private readonly commitmentRepository: CommitmentRepository,
    private readonly expander: RecurrenceExpander = new RecurrenceExpander(),
  ) {}

  async listBusy(userId: string, from: Date, to: Date, timezone: string): Promise<Interval[]> {
    const commitments = await this.commitmentRepository.findAllByUser(userId);
    // Um dia de folga antes: barato e protege as bordas do fuso. As canceladas já saem no expand.
    const fromDate = addDays(toLocalParts(from, timezone).date, -1);
    const toDate = toLocalParts(to, timezone).date;

    return commitments
      .flatMap((commitment) => this.expander.expand(commitment, fromDate, toDate, timezone))
      .filter((occurrence) => occurrence.start < to && occurrence.end > from)
      .sort((a, b) => a.start.getTime() - b.start.getTime());
  }
}
