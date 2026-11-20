import { ValidationException } from "@oitenta/shared";
import { ListCommitmentOccurrences } from "../../../src";
import { FakeCommitmentRepository, makeCommitment, USER_A, USER_B } from "../../mock";

function getValidationMessages(error: unknown): string[] {
  return (error as ValidationException).errors.map((item) => item.message);
}

describe("ListCommitmentOccurrences", () => {
  const violin = makeCommitment({
    exceptions: [{ date: "2025-11-11", type: "cancelled" }],
  });
  const internship = makeCommitment({
    title: "Estágio",
    category: "trabalho",
    startDate: "2025-11-10",
    startMinute: 13 * 60,
    endMinute: 18 * 60,
    recurrence: { weekdays: [0, 1] },
  });
  const doctor = makeCommitment({
    userId: USER_B,
    title: "Dentista",
    category: "saude",
    startDate: "2025-11-11",
    recurrence: null,
  });

  function makeSut() {
    return new ListCommitmentOccurrences(
      new FakeCommitmentRepository([violin, internship, doctor]),
    );
  }

  test("cenario 3: A com 2 compromissos e B com 1 -> A recebe so as dela, ordenadas por data e horario", async () => {
    const { occurrences } = await makeSut().execute({
      userId: USER_A,
      from: "2025-11-10",
      to: "2025-11-16",
    });

    expect(occurrences).toEqual([
      {
        commitmentId: internship.id,
        title: "Estágio",
        category: "trabalho",
        date: "2025-11-10",
        originalDate: "2025-11-10",
        startMinute: 780,
        endMinute: 1080,
        status: "normal",
        recurrence: { weekdays: [0, 1] },
      },
      {
        commitmentId: internship.id,
        title: "Estágio",
        category: "trabalho",
        date: "2025-11-11",
        originalDate: "2025-11-11",
        startMinute: 780,
        endMinute: 1080,
        status: "normal",
        recurrence: { weekdays: [0, 1] },
      },
      {
        commitmentId: violin.id,
        title: "Aula de violão",
        category: "pessoal",
        date: "2025-11-11",
        originalDate: "2025-11-11",
        startMinute: 1140,
        endMinute: 1200,
        status: "cancelled",
        recurrence: { weekdays: [1] },
      },
    ]);
  });

  test("posse: B recebe so o compromisso dele", async () => {
    const { occurrences } = await makeSut().execute({
      userId: USER_B,
      from: "2025-11-10",
      to: "2025-11-16",
    });

    expect(occurrences.map((item) => item.commitmentId)).toEqual([doctor.id]);
  });

  test("intervalo de 62 dias (limite exato) e aceito; from = to tambem", async () => {
    await expect(
      makeSut().execute({ userId: USER_A, from: "2025-11-01", to: "2026-01-01" }),
    ).resolves.toBeDefined();
    await expect(
      makeSut().execute({ userId: USER_A, from: "2025-11-11", to: "2025-11-11" }),
    ).resolves.toBeDefined();
  });

  test("cenario 3: from > to -> ValidationException occurrences.range", async () => {
    const error = await makeSut()
      .execute({ userId: USER_A, from: "2025-11-16", to: "2025-11-10" })
      .catch((caught: unknown) => caught);

    expect(getValidationMessages(error)).toEqual(["occurrences.range"]);
  });

  test("cenario 3: mais de 62 dias -> ValidationException occurrences.range", async () => {
    const error = await makeSut()
      .execute({ userId: USER_A, from: "2025-11-01", to: "2026-01-02" })
      .catch((caught: unknown) => caught);

    expect(getValidationMessages(error)).toEqual(["occurrences.range"]);
  });

  test("datas mal formadas -> ValidationException de data local", async () => {
    const error = await makeSut()
      .execute({ userId: USER_A, from: "10/11/2025", to: "" })
      .catch((caught: unknown) => caught);

    expect(getValidationMessages(error)).toEqual([
      "occurrences.from.local.date",
      "occurrences.to.required",
    ]);
  });
});
