import type { LoginInput, LoginResponse, MeResponse, RegisterInput, RegisterResponse, UpdateProfileInput } from "./auth.types";

// Fronteira das telas com /auth/*. Etapa B: dados de exemplo; Etapa D: HTTP.
export interface AuthRepository {
  login(input: LoginInput): Promise<LoginResponse>;
  register(input: RegisterInput): Promise<RegisterResponse>;
  demo(): Promise<LoginResponse>;
  me(): Promise<MeResponse>;
  /** PATCH /auth/me (AT3): troca nome e/ou e-mail. Senha atual errada → 403 (não desloga); e-mail de outra conta → 409. */
  updateProfile(input: UpdateProfileInput): Promise<MeResponse>;
  /** Encerra a sessão neste dispositivo (W26 "Sair"). O contrato não tem rota de logout: o JWT só é descartado. */
  logout(): Promise<void>;
}
