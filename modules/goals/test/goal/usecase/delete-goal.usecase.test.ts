import { NotFoundError } from "@oitenta/shared";
import { DeleteGoal, Goal } from "../../../src";
import { buildGoal, FakeGoalRepository } from "../../mock";

const USER_A = "3b241101-e2bb-4255-8caf-4136c566a962";
const USER_B = "0b8f9e2a-3f4b-4c1d-9e8f-7a6b5c4d3e2f";

function makeSut(goals: Goal[]) {
  const goalRepository = new FakeGoalRepository(goals);
  const useCase = new DeleteGoal(goalRepository);
  return { goalRepository, useCase };
}

describe("DeleteGoal", () => {
  test("8.2 cenario 5: o dono apaga o objetivo", async () => {
    const task = buildGoal({ userId: USER_A, kind: "single", deadline: null });
    const other = buildGoal({ userId: USER_A });
    const { goalRepository, useCase } = makeSut([task, other]);

    const output = await useCase.execute({ userId: USER_A, goalId: task.id });

    expect(output).toBeUndefined();
    expect(goalRepository.deleteCalls).toBe(1);
    expect(await goalRepository.findById(USER_A, task.id)).toBeNull();
    expect(goalRepository.goals.map((goal) => goal.id)).toEqual([other.id]);
  });

  test("8.2 cenario 5 (posse): outro usuario -> NotFoundError e nada e apagado", async () => {
    const goal = buildGoal({ userId: USER_A });
    const { goalRepository, useCase } = makeSut([goal]);

    await expect(useCase.execute({ userId: USER_B, goalId: goal.id })).rejects.toThrow(
      NotFoundError,
    );
    expect(goalRepository.deleteCalls).toBe(0);
    expect(goalRepository.goals).toHaveLength(1);
  });

  test("goalId inexistente -> NotFoundError", async () => {
    const { goalRepository, useCase } = makeSut([]);

    await expect(
      useCase.execute({ userId: USER_A, goalId: "8f14e45f-ceea-467a-9b36-3b5a2b0e0c11" }),
    ).rejects.toThrow(NotFoundError);
    expect(goalRepository.deleteCalls).toBe(0);
  });
});
