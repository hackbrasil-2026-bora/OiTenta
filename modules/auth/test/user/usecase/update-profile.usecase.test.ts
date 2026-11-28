import {
  ConflictError,
  ForbiddenError,
  UnauthorizedError,
  ValidationException,
} from "@oitenta/shared";
import { RegisterUser, UpdateProfile } from "../../../src";
import { FakeCryptoProvider, FakeUserRepository } from "../../mock";

/// Decisão AT3 (28/11/2026): trocar nome e e-mail; o e-mail pede a senha atual.
async function setup() {
  const userRepository = new FakeUserRepository();
  const crypto = new FakeCryptoProvider();
  const register = new RegisterUser(crypto, userRepository);
  const { user: ana } = await register.execute({
    name: "Ana Souza",
    email: "ana@bora.app",
    password: "Strong@123",
  });
  const { user: bia } = await register.execute({
    name: "Bia Lima",
    email: "bia@bora.app",
    password: "Strong@123",
  });
  return {
    userRepository,
    ana,
    bia,
    useCase: new UpdateProfile(crypto, userRepository),
  };
}

describe("UpdateProfile", () => {
  test("troca só o nome, sem pedir senha, e mantém o id", async () => {
    const { useCase, ana, userRepository } = await setup();

    const out = await useCase.execute({ userId: ana.id, name: "Ana Clara" });

    expect(out.user).toEqual({ ...ana, name: "Ana Clara" });
    expect((await userRepository.findById(ana.id))!.name).toBe("Ana Clara");
    expect(out.user).not.toHaveProperty("password");
  });

  test("troca o e-mail com a senha atual certa e normaliza", async () => {
    const { useCase, ana, userRepository } = await setup();

    const out = await useCase.execute({
      userId: ana.id,
      email: "  Ana.Nova@Bora.app ",
      currentPassword: "Strong@123",
    });

    expect(out.user.email).toBe("ana.nova@bora.app");
    expect(out.user.id).toBe(ana.id);
    expect(await userRepository.findByEmail("ana@bora.app")).toBeNull();
  });

  test("trocar o e-mail sem a senha atual dá ForbiddenError e não muda nada", async () => {
    const { useCase, ana, userRepository } = await setup();

    await expect(
      useCase.execute({ userId: ana.id, email: "outro@bora.app" }),
    ).rejects.toThrow(ForbiddenError);
    expect((await userRepository.findById(ana.id))!.email).toBe("ana@bora.app");
  });

  test("senha atual errada dá ForbiddenError (não 401, que deslogaria)", async () => {
    const { useCase, ana } = await setup();

    await expect(
      useCase.execute({
        userId: ana.id,
        email: "outro@bora.app",
        currentPassword: "Errada@123",
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  test("e-mail de outra conta dá ConflictError", async () => {
    const { useCase, ana } = await setup();

    await expect(
      useCase.execute({
        userId: ana.id,
        email: "BIA@bora.app",
        currentPassword: "Strong@123",
      }),
    ).rejects.toThrow(ConflictError);
  });

  test("o mesmo e-mail (só muda maiúscula) não conta como troca nem pede senha", async () => {
    const { useCase, ana } = await setup();

    const out = await useCase.execute({
      userId: ana.id,
      name: "Ana Clara",
      email: "ANA@bora.app",
    });

    expect(out.user.email).toBe("ana@bora.app");
    expect(out.user.name).toBe("Ana Clara");
  });

  test("nome inválido dá ValidationException e não grava", async () => {
    const { useCase, ana, userRepository } = await setup();

    await expect(useCase.execute({ userId: ana.id, name: "A" })).rejects.toThrow(
      ValidationException,
    );
    expect((await userRepository.findById(ana.id))!.name).toBe("Ana Souza");
  });

  test("usuário do token que não existe mais dá UnauthorizedError", async () => {
    const { useCase } = await setup();

    await expect(
      useCase.execute({
        userId: "8b0c9c7e-0000-4000-8000-000000000000",
        name: "Ana Clara",
      }),
    ).rejects.toThrow(UnauthorizedError);
  });

  test("posse: só altera o usuário do token, nunca outro", async () => {
    const { useCase, ana, bia, userRepository } = await setup();

    await useCase.execute({ userId: ana.id, name: "Ana Clara" });

    expect((await userRepository.findById(bia.id))!.name).toBe("Bia Lima");
  });
});
