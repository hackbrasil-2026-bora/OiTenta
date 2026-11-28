import {
  CreateRepository,
  FindByIdRepository,
  UpdateRepository,
} from "@oitenta/shared";
import { User } from "../model";

export interface UserRepository
  extends CreateRepository<User>,
    FindByIdRepository<User>,
    UpdateRepository<User> {
  findByEmail(email: string): Promise<User | null>;
}
