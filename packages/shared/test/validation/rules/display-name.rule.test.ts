import { DisplayNameRule } from "../../../src/index";

describe("DisplayNameRule", () => {
  test("deve aceitar nome com uma palavra ou mais, com acentos, hifen e apostrofo", () => {
    const rule = new DisplayNameRule();

    expect(rule.validate("Arthur")).toBeNull();
    expect(rule.validate("Ana Souza")).toBeNull();
    expect(rule.validate("João-Pedro")).toBeNull();
    expect(rule.validate("D'Ávila")).toBeNull();
    expect(rule.validate("Ana  Souza")).toBeNull();
    expect(rule.validate("  Maria   Clara  ")).toBeNull();
    expect(rule.validate(["Arthur", "Ana Souza"])).toBeNull();
  });

  test("deve reprovar numeros, simbolos e hifen ou apostrofo fora de entre letras", () => {
    const rule = new DisplayNameRule();

    expect(rule.validate("Arthur2")).toBe("display.name");
    expect(rule.validate("@na")).toBe("display.name");
    expect(rule.validate("Ana_")).toBe("display.name");
    expect(rule.validate("-Ana")).toBe("display.name");
    expect(rule.validate("Ana-")).toBe("display.name");
    expect(rule.validate("'Ana")).toBe("display.name");
    expect(rule.validate("Ana--Souza")).toBe("display.name");
    expect(rule.validate(["Arthur", "Arthur2"])).toBe("display.name");
  });

  test("deve reprovar valores que nao sao string, como as outras regras de texto", () => {
    const rule = new DisplayNameRule();

    expect(rule.validate(123)).toBe("display.name");
    expect(rule.validate({ name: "Arthur" })).toBe("display.name");
    expect(rule.validate(true)).toBe("display.name");
  });

  // Vazio fica com a RequiredRule (mesmo contrato da PersonNameRule e das demais
  // regras): a DisplayNameRule ignora vazio para não duplicar o erro "required".
  // A recusa de "" e "   " no cadastro é provada no teste do User.
  test("deve ignorar valores vazios, deixando a obrigatoriedade para a RequiredRule", () => {
    const rule = new DisplayNameRule();

    expect(rule.validate("")).toBeNull();
    expect(rule.validate("   ")).toBeNull();
    expect(rule.validate(null)).toBeNull();
    expect(rule.validate(undefined)).toBeNull();
  });
});
