import {
  ConflictError,
  ForbiddenError,
  UnauthorizedError,
  UseCase,
} from "@oitenta/shared";
import { CryptoProvider, UserRepository } from "../provider";
import { normalizeEmail, PublicUser, toPublicUser } from "./public-user";

export const WRONG_CURRENT_PASSWORD_MESSAGE = "Senha atual incorreta.";

export interface UpdateProfileIn {
  /** Dono da conta, sempre do token (nunca do corpo). */
  userId: string;
  name?: string;
  email?: string;
  /** Obrigatória só quando o e-mail muda (decisão AT3). */
  currentPassword?: string;
}

export interface UpdateProfileOut {
  user: PublicUser;
}

/**
 * Troca o nome e/ou o e-mail do usuário logado (AT3). O id não muda. Trocar o
 * e-mail pede a senha atual; a senha errada é 403, não 401, para o cliente não
 * tratar como sessão expirada.
 */
export class UpdateProfile implements UseCase<UpdateProfileIn, UpdateProfileOut> {
  constructor(
    private readonly cryptoProvider: CryptoProvider,
    private readonly userRepository: UserRepository,
  ) {}

  async execute(input: UpdateProfileIn): Promise<UpdateProfileOut> {
    const user = await this.userRepository.findById(input.userId);
    if (!user) {
      throw new UnauthorizedError("Usuário não autenticado.");
    }

    const email =
      input.email === undefined ? user.email : normalizeEmail(input.email);
    if (email !== user.email) {
      const matches = await this.cryptoProvider.compare(
        input.currentPassword ?? "",
        user.password,
      );
      if (!matches) {
        throw new ForbiddenError(WRONG_CURRENT_PASSWORD_MESSAGE);
      }
      const owner = await this.userRepository.findByEmail(email);
      if (owner) {
        throw new ConflictError("E-mail já cadastrado.");
      }
    }

    const updated = user.clone({ name: input.name ?? user.name, email });
    updated.validate();
    await this.userRepository.update(updated);

    return { user: toPublicUser(updated) };
  }
}
