import { ForbiddenError, UnauthorizedError, ValidationException } from "@oitenta/shared";
import { ChangePassword, LoginUser, RegisterUser } from "../../../src";
import { FakeCryptoProvider, FakeTokenProvider, FakeUserRepository } from "../../mock";

/// Decisão AT9 (28/11/2026): trocar a senha logado, com a senha atual.
async function setup() {
  const userRepository = new FakeUserRepository();
  const crypto = new FakeCryptoProvider();
  const register = new RegisterUser(crypto, userRepository);
  const { user: ana } = await register.execute({ name: "Ana Souza", email: "ana@bora.app", password: "Strong@123" });
  const { user: bia } = await register.execute({ name: "Bia Lima", email: "bia@bora.app", password: "Strong@123" });
  const login = (email: string, password: string) =>
    new LoginUser(crypto, new FakeTokenProvider(), userRepository).execute({ email, password });
  return { ana, bia, login, userRepository, useCase: new ChangePassword(crypto, userRepository) };
}

describe("ChangePassword", () => {
  test("com a senha atual certa, a nova passa a valer e a antiga não", async () => {
    const { useCase, ana, login } = await setup();

    await useCase.execute({ userId: ana.id, currentPassword: "Strong@123", newPassword: "Nova@4567" });

    await expect(login("ana@bora.app", "Nova@4567")).resolves.toBeDefined();
    await expect(login("ana@bora.app", "Strong@123")).rejects.toThrow(UnauthorizedError);
  });

  test("senha atual errada dá ForbiddenError (não 401) e não troca", async () => {
    const { useCase, ana, login } = await setup();

    await expect(
      useCase.execute({ userId: ana.id, currentPassword: "Errada@123", newPassword: "Nova@4567" }),
    ).rejects.toThrow(ForbiddenError);
    await expect(login("ana@bora.app", "Strong@123")).resolves.toBeDefined();
  });

  test("senha nova fraca dá ValidationException", async () => {
    const { useCase, ana } = await setup();

    await expect(
      useCase.execute({ userId: ana.id, currentPassword: "Strong@123", newPassword: "fraca" }),
    ).rejects.toThrow(ValidationException);
  });

  test("usuário do token que não existe mais dá UnauthorizedError", async () => {
    const { useCase } = await setup();

    await expect(
      useCase.execute({
        userId: "8b0c9c7e-0000-4000-8000-000000000000",
        currentPassword: "Strong@123",
        newPassword: "Nova@4567",
      }),
    ).rejects.toThrow(UnauthorizedError);
  });

  test("posse: só troca a senha do usuário do token", async () => {
    const { useCase, ana, login } = await setup();

    await useCase.execute({ userId: ana.id, currentPassword: "Strong@123", newPassword: "Nova@4567" });

    await expect(login("bia@bora.app", "Strong@123")).resolves.toBeDefined();
  });
});
