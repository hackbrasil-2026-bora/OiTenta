import { ForbiddenError, UnauthorizedError } from "@oitenta/shared";
import { AccountEraser, DeleteAccount, RegisterUser } from "../../../src";
import { FakeCryptoProvider, FakeUserRepository } from "../../mock";

/** Apagador falso: grava de quem apagou os dados. */
class FakeAccountEraser implements AccountEraser {
  readonly erased: string[] = [];
  constructor(private readonly users: FakeUserRepository) {}
  async eraseAccount(userId: string): Promise<void> {
    this.erased.push(userId);
    await this.users.remove(userId);
  }
}

/// Decisão AT9 (28/11/2026): apagar a conta de verdade, com a senha atual.
async function setup() {
  const userRepository = new FakeUserRepository();
  const crypto = new FakeCryptoProvider();
  const register = new RegisterUser(crypto, userRepository);
  const { user: ana } = await register.execute({ name: "Ana Souza", email: "ana@bora.app", password: "Strong@123" });
  const { user: demo } = await register.execute({ name: "Arthur", email: "demo@bora.app", password: "Strong@123" });
  const eraser = new FakeAccountEraser(userRepository);
  return { ana, demo, eraser, userRepository, useCase: new DeleteAccount(crypto, userRepository, eraser) };
}

describe("DeleteAccount", () => {
  test("com a senha certa, apaga a conta e todos os dados dela", async () => {
    const { useCase, ana, eraser, userRepository } = await setup();

    await useCase.execute({ userId: ana.id, currentPassword: "Strong@123", demoEmail: "demo@bora.app" });

    expect(eraser.erased).toEqual([ana.id]);
    expect(await userRepository.findById(ana.id)).toBeNull();
  });

  test("senha errada dá ForbiddenError e não apaga nada", async () => {
    const { useCase, ana, eraser } = await setup();

    await expect(
      useCase.execute({ userId: ana.id, currentPassword: "Errada@123", demoEmail: "demo@bora.app" }),
    ).rejects.toThrow(ForbiddenError);
    expect(eraser.erased).toEqual([]);
  });

  test("a conta demo não pode ser apagada", async () => {
    const { useCase, demo, eraser } = await setup();

    await expect(
      useCase.execute({ userId: demo.id, currentPassword: "Strong@123", demoEmail: " DEMO@bora.app " }),
    ).rejects.toThrow(ForbiddenError);
    expect(eraser.erased).toEqual([]);
  });

  test("usuário do token que não existe mais dá UnauthorizedError", async () => {
    const { useCase } = await setup();

    await expect(
      useCase.execute({
        userId: "8b0c9c7e-0000-4000-8000-000000000000",
        currentPassword: "Strong@123",
        demoEmail: "demo@bora.app",
      }),
    ).rejects.toThrow(UnauthorizedError);
  });

  test("posse: só apaga a conta do token, nunca outra", async () => {
    const { useCase, ana, demo, userRepository } = await setup();

    await useCase.execute({ userId: ana.id, currentPassword: "Strong@123", demoEmail: "demo@bora.app" });

    expect(await userRepository.findById(demo.id)).not.toBeNull();
  });
});
