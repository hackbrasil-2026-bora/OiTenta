import { CreateRepository, UpdateRepository } from "@oitenta/shared";
import { Goal } from "../model";

export interface GoalRepository
  extends CreateRepository<Goal>,
    UpdateRepository<Goal> {
  findById(userId: string, goalId: string): Promise<Goal | null>;
  findAllByUser(userId: string): Promise<Goal[]>;
  /** Apaga o objetivo e as etapas, sempre escopado pelo dono (MC11). */
  delete(userId: string, goalId: string): Promise<void>;
}
