import type { LoginInput, LoginResponse, MeResponse, RegisterInput, RegisterResponse, UpdateProfileInput, ChangePasswordInput, DeleteAccountInput } from "./auth.types";

// Fronteira das telas com /auth/*. Etapa B: dados de exemplo; Etapa D: HTTP.
export interface AuthRepository {
  login(input: LoginInput): Promise<LoginResponse>;
  register(input: RegisterInput): Promise<RegisterResponse>;
  demo(): Promise<LoginResponse>;
  me(): Promise<MeResponse>;
  /** PATCH /auth/me (AT3): troca nome e/ou e-mail. Senha atual errada → 403 (não desloga); e-mail de outra conta → 409. */
  updateProfile(input: UpdateProfileInput): Promise<MeResponse>;
  /** PATCH /auth/me/password (AT9). Senha atual errada → 403; nova fraca → 422. */
  changePassword(input: ChangePasswordInput): Promise<void>;
  /** DELETE /auth/me (AT9): apaga a conta e todos os dados, e encerra a sessão. Senha errada ou conta demo → 403. */
  deleteAccount(input: DeleteAccountInput): Promise<void>;
  /** Encerra a sessão neste dispositivo (W26 "Sair"). O contrato não tem rota de logout: o JWT só é descartado. */
  logout(): Promise<void>;
}
