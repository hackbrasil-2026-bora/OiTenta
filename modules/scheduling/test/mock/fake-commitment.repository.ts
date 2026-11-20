import { Commitment, CommitmentRepository } from "../../src";

/** Repositório em memória de compromissos; toda operação respeita o dono (`userId`). */
export class FakeCommitmentRepository implements CommitmentRepository {
  private readonly storage = new Map<string, Commitment>();
  createCalls = 0;
  updateCalls = 0;
  deleteCalls = 0;

  constructor(initial: Commitment[] = []) {
    for (const commitment of initial) {
      this.storage.set(commitment.id, commitment);
    }
  }

  get commitments(): Commitment[] {
    return Array.from(this.storage.values());
  }

  get writeCalls(): number {
    return this.createCalls + this.updateCalls + this.deleteCalls;
  }

  async create(data: Commitment): Promise<Commitment> {
    this.createCalls += 1;
    this.storage.set(data.id, data);
    return data;
  }

  async update(data: Commitment): Promise<Commitment> {
    const current = this.storage.get(data.id);
    if (!current || current.userId !== data.userId) {
      throw new Error("Compromisso não encontrado para este usuário.");
    }
    this.updateCalls += 1;
    this.storage.set(data.id, data);
    return data;
  }

  async delete(userId: string, id: string): Promise<void> {
    const current = this.storage.get(id);
    if (!current || current.userId !== userId) {
      throw new Error("Compromisso não encontrado para este usuário.");
    }
    this.deleteCalls += 1;
    this.storage.delete(id);
  }

  async findById(userId: string, id: string): Promise<Commitment | null> {
    const commitment = this.storage.get(id);
    return commitment && commitment.userId === userId ? commitment : null;
  }

  async findAllByUser(userId: string): Promise<Commitment[]> {
    return this.commitments.filter((commitment) => commitment.userId === userId);
  }
}
