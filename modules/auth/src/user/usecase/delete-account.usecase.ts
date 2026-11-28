import { ForbiddenError, UnauthorizedError, UseCase } from "@oitenta/shared";
import { AccountEraser, CryptoProvider, UserRepository } from "../provider";
import { normalizeEmail } from "./public-user";
import { WRONG_CURRENT_PASSWORD_MESSAGE } from "./update-profile.usecase";

export interface DeleteAccountIn {
  /** Dono da conta, sempre do token. */
  userId: string;
  currentPassword: string;
  /** E-mail do usuário demo (`DEMO_EMAIL`): essa conta não pode ser apagada. */
  demoEmail: string;
}

/**
 * Apaga de verdade a conta do usuário logado e todos os dados dela (AT9,
 * LGPD). Pede a senha atual (errada → 403). A conta demo não pode ser
 * apagada, para o "Entrar como demo" continuar funcionando.
 */
export class DeleteAccount implements UseCase<DeleteAccountIn, void> {
  constructor(
    private readonly cryptoProvider: CryptoProvider,
    private readonly userRepository: UserRepository,
    private readonly accountEraser: AccountEraser,
  ) {}

  async execute(input: DeleteAccountIn): Promise<void> {
    const user = await this.userRepository.findById(input.userId);
    if (!user) {
      throw new UnauthorizedError("Usuário não autenticado.");
    }
    const matches = await this.cryptoProvider.compare(
      input.currentPassword,
      user.password,
    );
    if (!matches) {
      throw new ForbiddenError(WRONG_CURRENT_PASSWORD_MESSAGE);
    }
    if (user.email === normalizeEmail(input.demoEmail)) {
      throw new ForbiddenError("A conta demo não pode ser apagada.");
    }

    await this.accountEraser.eraseAccount(user.id);
  }
}
