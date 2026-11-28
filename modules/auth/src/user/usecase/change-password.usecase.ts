import {
  ForbiddenError,
  StrongPasswordRule,
  UnauthorizedError,
  UseCase,
  Validator,
} from "@oitenta/shared";
import { CryptoProvider, UserRepository } from "../provider";
import { WRONG_CURRENT_PASSWORD_MESSAGE } from "./update-profile.usecase";

export interface ChangePasswordIn {
  /** Dono da conta, sempre do token. */
  userId: string;
  currentPassword: string;
  newPassword: string;
}

/**
 * Troca a senha do usuário logado (AT9). Senha atual errada é 403 (não 401,
 * para o cliente não deslogar); senha nova fraca é 422.
 */
export class ChangePassword implements UseCase<ChangePasswordIn, void> {
  constructor(
    private readonly cryptoProvider: CryptoProvider,
    private readonly userRepository: UserRepository,
  ) {}

  async execute(input: ChangePasswordIn): Promise<void> {
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
    Validator.validate([
      {
        code: "user.password",
        value: input.newPassword,
        rules: [new StrongPasswordRule()],
      },
    ]);

    const password = await this.cryptoProvider.encrypt(input.newPassword);
    const updated = user.clone({ password });
    updated.validate();
    await this.userRepository.update(updated);
  }
}
