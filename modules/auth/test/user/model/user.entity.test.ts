import { ValidationException } from "@oitenta/shared";
import { User, UserState } from "../../../src";

const VALID_HASH =
  "$2b$10$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZa";

function makeState(overrides: Partial<UserState> = {}): UserState {
  return {
    name: "Ana Souza",
    email: "ana@bora.app",
    password: VALID_HASH,
    timezone: "America/Sao_Paulo",
    ...overrides,
  };
}

function getValidationMessages(callback: () => void): string[] {
  try {
    callback();
    return [];
  } catch (error) {
    return (error as ValidationException).errors.map((item) => item.message);
  }
}

describe("User", () => {
  test("deve criar usuario valido e expor os getters", () => {
    const user = new User(makeState());

    expect(user.name).toBe("Ana Souza");
    expect(user.email).toBe("ana@bora.app");
    expect(user.password).toBe(VALID_HASH);
    expect(user.timezone).toBe("America/Sao_Paulo");
    expect(user.id).toEqual(expect.any(String));
    expect(user.createdAt).toBeInstanceOf(Date);
    expect(user.updatedAt).toBeInstanceOf(Date);
    expect(user.deletedAt).toBeNull();
  });

  test("deve passar no validate com dados validos", () => {
    const user = new User(makeState());

    expect(() => user.validate()).not.toThrow();
  });

  test("deve permitir existir invalido ate chamar validate (validacao lazy)", () => {
    const user = new User(makeState({ name: "", email: "x", password: "123" }));

    expect(user.name).toBe("");
    expect(() => user.validate()).toThrow(ValidationException);
  });

  test("deve acusar todos os campos obrigatorios vazios", () => {
    const user = new User(makeState({ name: "", email: "", password: "", timezone: "" }));

    expect(getValidationMessages(() => user.validate())).toEqual([
      "user.name.required",
      "user.email.required",
      "user.password.required",
      "user.timezone.required",
    ]);
  });

  // MP2 (docs/2-decisoes-mvp.md): o nome passa a aceitar uma palavra só ("Como quer
  // ser chamado? Ex.: Arthur"). O antigo teste "deve rejeitar nome com uma palavra so"
  // (que esperava "user.name.person.name" para "Ana") foi invertido por essa decisão.
  test("MP2: deve aceitar nome com uma palavra so", () => {
    const user = new User(makeState({ name: "Arthur" }));

    expect(() => user.validate()).not.toThrow();
  });

  test("MP2: deve aceitar nome com duas letras", () => {
    const user = new User(makeState({ name: "Bo" }));

    expect(() => user.validate()).not.toThrow();
  });

  // MP2: o mínimo cai de 3 para 2 caracteres; "A" continua inválido só pelo tamanho.
  test("MP2: deve rejeitar nome com um caractere", () => {
    const user = new User(makeState({ name: "A" }));

    expect(getValidationMessages(() => user.validate())).toEqual([
      "user.name.min.length",
    ]);
  });

  test("MP2: deve rejeitar nome com numero ou simbolo", () => {
    expect(
      getValidationMessages(() => new User(makeState({ name: "Arthur2" })).validate()),
    ).toEqual(["user.name.display.name"]);
    expect(
      getValidationMessages(() => new User(makeState({ name: "@na" })).validate()),
    ).toEqual(["user.name.display.name"]);
  });

  test("MP2: deve rejeitar nome vazio ou so com espacos apenas como obrigatorio", () => {
    expect(
      getValidationMessages(() => new User(makeState({ name: "" })).validate()),
    ).toEqual(["user.name.required"]);
    expect(
      getValidationMessages(() => new User(makeState({ name: "   " })).validate()),
    ).toEqual(["user.name.required"]);
  });

  test("MP2: deve rejeitar nome com 81 caracteres", () => {
    const user = new User(makeState({ name: "a".repeat(81) }));

    expect(getValidationMessages(() => user.validate())).toEqual([
      "user.name.max.length",
    ]);
  });

  test("deve rejeitar nome com mais de 80 caracteres", () => {
    const user = new User(makeState({ name: `Ana ${"a".repeat(80)}` }));

    expect(getValidationMessages(() => user.validate())).toEqual([
      "user.name.max.length",
    ]);
  });

  test("deve aceitar nome com exatamente 80 caracteres", () => {
    const user = new User(makeState({ name: `Ana ${"a".repeat(76)}` }));

    expect(() => user.validate()).not.toThrow();
  });

  test("deve rejeitar e-mail invalido", () => {
    const user = new User(makeState({ email: "ana.bora.app" }));

    expect(getValidationMessages(() => user.validate())).toEqual([
      "user.email.invalid.email",
    ]);
  });

  test("deve rejeitar senha que nao esta em hash bcrypt", () => {
    const user = new User(makeState({ password: "SenhaForte@123" }));

    expect(getValidationMessages(() => user.validate())).toEqual([
      "user.password.bcrypt.hash",
    ]);
  });

  test("C0-1: deve aceitar fuso IANA valido", () => {
    const user = new User(makeState({ timezone: "America/Manaus" }));

    expect(() => user.validate()).not.toThrow();
  });

  test("C0-2: deve rejeitar fuso inexistente", () => {
    const user = new User(makeState({ timezone: "Lua/Base" }));

    expect(getValidationMessages(() => user.validate())).toEqual([
      "user.timezone.invalid.timezone",
    ]);
  });

  test("deve exigir fuso", () => {
    const user = new User(makeState({ timezone: "" }));

    expect(getValidationMessages(() => user.validate())).toEqual([
      "user.timezone.required",
    ]);
  });

  test("deve preservar id e createdAt no clone e atualizar updatedAt", () => {
    const createdAt = new Date("2026-11-01T10:00:00.000Z");
    const user = new User(makeState({ createdAt, updatedAt: createdAt }));

    const cloned = user.clone({ name: "Ana Lima" });

    expect(cloned.id).toBe(user.id);
    expect(cloned.createdAt).toEqual(createdAt);
    expect(cloned.updatedAt.getTime()).toBeGreaterThan(createdAt.getTime());
    expect(cloned.name).toBe("Ana Lima");
    expect(user.name).toBe("Ana Souza");
  });
});
