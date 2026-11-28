import { CreateRepository, UpdateRepository } from "@oitenta/shared";
import { Commitment } from "../model";

/** Compromissos do usuário; toda leitura e escrita filtra pelo dono (`userId`). */
export interface CommitmentRepository
  extends CreateRepository<Commitment>,
    UpdateRepository<Commitment> {
  delete(userId: string, id: string): Promise<void>;
  /** `null` se não existe ou é de outro usuário. */
  findById(userId: string, id: string): Promise<Commitment | null>;
  findAllByUser(userId: string): Promise<Commitment[]>;
}
