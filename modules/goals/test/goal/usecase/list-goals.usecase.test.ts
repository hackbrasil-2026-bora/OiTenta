import { ListGoals } from "../../../src";
import { buildGoal, FakeGoalRepository } from "../../mock";

const USER_A = "3b241101-e2bb-4255-8caf-4136c566a962";
const USER_B = "0b8f9e2a-3f4b-4c1d-9e8f-7a6b5c4d3e2f";

describe("ListGoals", () => {
  test("cenario 1 (posse): A com 2 objetivos e B com 1 -> A recebe so os 2 dele", async () => {
    const a1 = buildGoal({ userId: USER_A, title: "A1" });
    const a2 = buildGoal({ userId: USER_A, title: "A2", colorIndex: 2 });
    const b1 = buildGoal({ userId: USER_B, title: "B1" });
    const useCase = new ListGoals(new FakeGoalRepository([a1, b1, a2]));

    const output = await useCase.execute({ userId: USER_A });

    expect(output.goals.map((goal) => goal.id).sort()).toEqual([a1.id, a2.id].sort());
    expect(output.goals.map((goal) => goal.id)).not.toContain(b1.id);
  });

  test("cenario 2: usuario sem objetivos recebe lista vazia", async () => {
    const useCase = new ListGoals(
      new FakeGoalRepository([buildGoal({ userId: USER_B })]),
    );

    const output = await useCase.execute({ userId: USER_A });

    expect(output.goals).toEqual([]);
  });

  test("cenario 3: 1 de 4 etapas iguais concluida -> 25%, done 1, total 4", async () => {
    const goal = buildGoal({
      userId: USER_A,
      deadline: null,
      colorIndex: 2,
      steps: [{ progressPct: 100 }, {}, {}, {}],
    });
    const useCase = new ListGoals(new FakeGoalRepository([goal]));

    const output = await useCase.execute({ userId: USER_A });

    expect(output.goals).toEqual([
      {
        id: goal.id,
        title: "Trabalho de Algoritmos",
        deadline: null,
        kind: "goal",
        plannedDate: null,
        estimatedMinutes: 240,
        colorIndex: 2,
        progressPct: 25,
        done: 1,
        total: 4,
        status: "active",
        createdAt: goal.createdAt,
      },
    ]);
  });

  test("C4 (decisao A): a saida traz o createdAt de cada objetivo, para montar a entrada do plano", async () => {
    const createdAt = new Date("2026-11-03T12:00:00.000Z");
    const goal = buildGoal({ userId: USER_A, createdAt });
    const useCase = new ListGoals(new FakeGoalRepository([goal]));

    const output = await useCase.execute({ userId: USER_A });

    expect(output.goals.map((item) => item.createdAt)).toEqual([createdAt]);
  });

  describe("8.2 cenario 3: filtro por kind e campos novos", () => {
    const goalA = buildGoal({ userId: USER_A, title: "Objetivo" });
    const taskA = buildGoal({
      userId: USER_A,
      title: "Tarefa",
      kind: "single",
      deadline: null,
      plannedDate: "2026-11-21",
      steps: [{ estimatedMinutes: 30 }],
    });
    const taskB = buildGoal({ userId: USER_B, kind: "single", deadline: null });
    const useCase = new ListGoals(new FakeGoalRepository([goalA, taskA, taskB]));

    test("kind single devolve so as tarefas do usuario", async () => {
      const output = await useCase.execute({ userId: USER_A, kind: "single" });

      expect(output.goals.map((item) => item.id)).toEqual([taskA.id]);
      expect(output.goals[0]).toMatchObject({
        kind: "single",
        plannedDate: "2026-11-21",
        estimatedMinutes: 30,
      });
    });

    test("kind goal devolve so os objetivos", async () => {
      const output = await useCase.execute({ userId: USER_A, kind: "goal" });

      expect(output.goals.map((item) => item.id)).toEqual([goalA.id]);
      expect(output.goals[0]).toMatchObject({ kind: "goal", plannedDate: null });
    });

    test("sem kind devolve todos", async () => {
      const output = await useCase.execute({ userId: USER_A });

      expect(output.goals.map((item) => item.id).sort()).toEqual([goalA.id, taskA.id].sort());
    });
  });

  test("8.2: estimatedMinutes soma so as etapas nao superseded", async () => {
    const goal = buildGoal({
      userId: USER_A,
      steps: [
        { estimatedMinutes: 60, progressPct: 50, status: "superseded" },
        { estimatedMinutes: 45 },
        { estimatedMinutes: 30, progressPct: 100 },
      ],
    });
    const useCase = new ListGoals(new FakeGoalRepository([goal]));

    const output = await useCase.execute({ userId: USER_A });

    expect(output.goals[0].estimatedMinutes).toBe(75);
  });
});
