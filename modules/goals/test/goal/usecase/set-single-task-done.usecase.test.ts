import { NotFoundError, ValidationException } from "@oitenta/shared";
import { Goal, SetSingleTaskDone } from "../../../src";
import { buildGoal, FakeGoalRepository } from "../../mock";

const USER_A = "3b241101-e2bb-4255-8caf-4136c566a962";
const USER_B = "0b8f9e2a-3f4b-4c1d-9e8f-7a6b5c4d3e2f";

function makeSut(goals: Goal[]) {
  const goalRepository = new FakeGoalRepository(goals);
  const useCase = new SetSingleTaskDone(goalRepository);
  return { goalRepository, useCase };
}

function singleTask(progressPct = 0): Goal {
  return buildGoal({
    userId: USER_A,
    kind: "single",
    deadline: null,
    plannedDate: "2026-11-21",
    steps: [{ estimatedMinutes: 30, progressPct }],
  });
}

function getValidationMessages(error: unknown): string[] {
  return (error as ValidationException).errors.map((item) => item.message);
}

describe("SetSingleTaskDone", () => {
  test("8.2 cenario 4: done true -> etapa em 100% e status done", async () => {
    const task = singleTask();
    const { goalRepository, useCase } = makeSut([task]);

    const output = await useCase.execute({ userId: USER_A, goalId: task.id, done: true });

    const saved = (await goalRepository.findById(USER_A, task.id))!;
    expect(saved.steps[0].progressPct).toBe(100);
    expect(saved.steps[0].status).toBe("done");
    expect(saved.status).toBe("done");
    expect(saved.plannedDate).toBe("2026-11-21");
    expect(goalRepository.updateCalls).toBe(1);
    expect(output.goal).toMatchObject({
      id: task.id,
      kind: "single",
      status: "done",
      progressPct: 100,
    });
    expect(output.goal.steps[0]).toMatchObject({ progressPct: 100, status: "done" });
  });

  test("8.2 cenario 4: done false -> etapa em 0% e status active", async () => {
    const task = singleTask(100);
    const { goalRepository, useCase } = makeSut([task]);

    const output = await useCase.execute({ userId: USER_A, goalId: task.id, done: false });

    const saved = (await goalRepository.findById(USER_A, task.id))!;
    expect(saved.steps[0].progressPct).toBe(0);
    expect(saved.steps[0].status).toBe("pending");
    expect(saved.status).toBe("active");
    expect(output.goal).toMatchObject({ status: "active", progressPct: 0 });
  });

  test("8.2 cenario 4: objetivo kind goal -> ValidationException goal.kind.single e nao grava", async () => {
    const goal = buildGoal({ userId: USER_A });
    const { goalRepository, useCase } = makeSut([goal]);

    const error = await useCase
      .execute({ userId: USER_A, goalId: goal.id, done: true })
      .catch((caught: unknown) => caught);

    expect(error).toBeInstanceOf(ValidationException);
    expect(getValidationMessages(error)).toEqual(["goal.kind.single"]);
    expect(goalRepository.updateCalls).toBe(0);
  });

  test("8.2 cenario 4 (posse): tarefa de A pedida por B -> NotFoundError e nao grava", async () => {
    const task = singleTask();
    const { goalRepository, useCase } = makeSut([task]);

    await expect(
      useCase.execute({ userId: USER_B, goalId: task.id, done: true }),
    ).rejects.toThrow(NotFoundError);
    expect(goalRepository.updateCalls).toBe(0);
    expect(goalRepository.goals[0].status).toBe("active");
  });

  test("goalId inexistente -> NotFoundError", async () => {
    const { useCase } = makeSut([]);

    await expect(
      useCase.execute({
        userId: USER_A,
        goalId: "8f14e45f-ceea-467a-9b36-3b5a2b0e0c11",
        done: true,
      }),
    ).rejects.toThrow(NotFoundError);
  });
});
