import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ScheduledBlock } from '@oitenta/scheduling';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaGoalRepository } from '../src/modules/goals/goal.prisma';
import { PrismaScheduledBlockRepository } from '../src/modules/scheduling/scheduled-block.prisma';

// Integração das tarefas únicas (docs/4-contrato-api.md §3, MC7, MC8, MC10, MC11; lista 1 a 6)
// e do plano do dia/semana com bloco de objetivo apagado. Exige o Postgres no ar.
// Fuso padrão do cadastro: America/Sao_Paulo.
interface LoginBody {
  token: string;
  user: { id: string };
}
interface PlanBody {
  totalMinutes: number;
  days: number;
  goals: { goalId: string }[];
}
interface CreateGoalBody {
  goal: { id: string; steps: { id: string }[] };
  plan: PlanBody;
}
interface GoalListItemBody {
  id: string;
  title: string;
  kind: string;
  plannedDate: string | null;
  estimatedMinutes: number;
  done: number;
  total: number;
  status: string;
}
interface GoalListBody {
  goals: GoalListItemBody[];
}
interface DoneBody {
  goal: { id: string; status: string; progressPct: number };
  plan: PlanBody;
}
interface DayBody {
  date: string;
  blocks: { goalId: string }[];
}

const TIMEZONE = 'America/Sao_Paulo';
const DAY_MS = 86_400_000;
const localDateOf = (instant: Date) =>
  instant.toLocaleDateString('en-CA', { timeZone: TIMEZONE });
const localDateIn = (days: number) =>
  localDateOf(new Date(Date.now() + days * DAY_MS));

// Todo dia das 06:00 às 23:00 locais: há tempo livre nos próximos dias qualquer que seja a hora do teste.
const EVERY_DAY = {
  windows: [0, 1, 2, 3, 4, 5, 6].map((weekday) => ({
    weekday,
    startMinute: 360,
    endMinute: 1380,
  })),
  dailyLimitMinutes: 180,
};

describe('goals: tarefas únicas (integração)', () => {
  let app: INestApplication<App>;

  const unique = () =>
    `single.${Date.now()}.${Math.round(Math.random() * 1e6)}@bora.app`;

  async function registerAndLogin(): Promise<LoginBody> {
    const email = unique();
    await request(app.getHttpServer())
      .post('/auth/register')
      .send({ name: 'Ana Souza', email, password: 'Senha@123' });
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password: 'Senha@123' });
    return login.body as LoginBody;
  }

  async function onboarded(): Promise<LoginBody> {
    const login = await registerAndLogin();
    await request(app.getHttpServer())
      .put('/scheduling/availability')
      .set('Authorization', `Bearer ${login.token}`)
      .send(EVERY_DAY);
    return login;
  }

  const singleBody = (overrides: Record<string, unknown> = {}) => ({
    title: 'Pagar o boleto',
    deadline: null,
    kind: 'single',
    plannedDate: null,
    steps: [{ title: 'Pagar o boleto', estimatedMinutes: 30 }],
    ...overrides,
  });

  const goalBody = (overrides: Record<string, unknown> = {}) => ({
    title: 'Trabalho de Algoritmos',
    deadline: localDateIn(14),
    kind: 'goal',
    steps: [
      { title: 'Ler o enunciado', estimatedMinutes: 30 },
      { title: 'Montar o esqueleto', estimatedMinutes: 60 },
    ],
    ...overrides,
  });

  const postGoal = (token: string, body: unknown) =>
    request(app.getHttpServer())
      .post('/goals')
      .set('Authorization', `Bearer ${token}`)
      .send(body as object);

  async function createdId(token: string, body: unknown): Promise<string> {
    const res = await postGoal(token, body);
    return (res.body as CreateGoalBody).goal.id;
  }

  const listGoals = (token: string, query = '') =>
    request(app.getHttpServer())
      .get(`/goals${query}`)
      .set('Authorization', `Bearer ${token}`);

  const patchDone = (token: string, goalId: string, body: unknown) =>
    request(app.getHttpServer())
      .patch(`/goals/${goalId}/done`)
      .set('Authorization', `Bearer ${token}`)
      .send(body as object);

  const deleteGoal = (token: string, goalId: string) =>
    request(app.getHttpServer())
      .delete(`/goals/${goalId}`)
      .set('Authorization', `Bearer ${token}`);

  async function futureBlocksOf(userId: string, goalId: string) {
    const blocks = await app
      .get(PrismaScheduledBlockRepository)
      .findByUserInRange(
        userId,
        new Date(),
        new Date(Date.now() + 30 * DAY_MS),
      );
    return blocks.filter((block) => block.goalId === goalId);
  }

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /goals com plannedDate (MC7)', () => {
    it('single com plannedDate amanhã → 201, nenhum bloco hoje e o primeiro bloco é amanhã', async () => {
      const { token, user } = await onboarded();
      const tomorrow = localDateIn(1);

      const res = await postGoal(token, singleBody({ plannedDate: tomorrow }));
      const goalId = (res.body as CreateGoalBody).goal.id;
      const days = (await futureBlocksOf(user.id, goalId))
        .map((block) => localDateOf(block.start))
        .sort();

      expect({ status: res.status, firstDay: days[0] }).toEqual({
        status: 201,
        firstDay: tomorrow,
      });
    });

    it('single com plannedDate → a lista devolve a data planejada', async () => {
      const { token } = await onboarded();
      const tomorrow = localDateIn(1);
      await postGoal(token, singleBody({ plannedDate: tomorrow }));

      const res = await listGoals(token);

      expect((res.body as GoalListBody).goals[0].plannedDate).toBe(tomorrow);
    });

    it('single sem data (null) → 201', async () => {
      const { token } = await onboarded();

      const res = await postGoal(token, singleBody({ plannedDate: null }));

      expect(res.status).toBe(201);
    });

    it('goal com plannedDate → 422 e nada é gravado', async () => {
      const { token, user } = await onboarded();

      const res = await postGoal(
        token,
        goalBody({ plannedDate: localDateIn(1) }),
      );
      const goals = await app.get(PrismaGoalRepository).findAllByUser(user.id);

      expect([res.status, goals.length]).toEqual([422, 0]);
    });

    it('plannedDate malformado → 400', async () => {
      const { token } = await onboarded();

      const res = await postGoal(token, singleBody({ plannedDate: '21/11' }));

      expect(res.status).toBe(400);
    });
  });

  describe('GET /goals?kind (MC8)', () => {
    it('?kind=single → só as tarefas, com kind, plannedDate e estimatedMinutes', async () => {
      const { token } = await onboarded();
      const tomorrow = localDateIn(1);
      await postGoal(token, goalBody());
      const singleId = await createdId(
        token,
        singleBody({ plannedDate: tomorrow }),
      );

      const res = await listGoals(token, '?kind=single');
      const body = res.body as GoalListBody;

      expect({
        status: res.status,
        goals: body.goals.map((goal) => ({
          id: goal.id,
          kind: goal.kind,
          plannedDate: goal.plannedDate,
          estimatedMinutes: goal.estimatedMinutes,
          done: goal.done,
          total: goal.total,
          status: goal.status,
        })),
      }).toEqual({
        status: 200,
        goals: [
          {
            id: singleId,
            kind: 'single',
            plannedDate: tomorrow,
            estimatedMinutes: 30,
            done: 0,
            total: 1,
            status: 'active',
          },
        ],
      });
    });

    it('?kind=goal → só os objetivos comuns, com plannedDate null', async () => {
      const { token } = await onboarded();
      const goalId = await createdId(token, goalBody());
      await postGoal(token, singleBody());

      const res = await listGoals(token, '?kind=goal');
      const body = res.body as GoalListBody;

      expect(
        body.goals.map((goal) => [
          goal.id,
          goal.kind,
          goal.plannedDate,
          goal.estimatedMinutes,
        ]),
      ).toEqual([[goalId, 'goal', null, 90]]);
    });

    it('sem kind → os dois tipos', async () => {
      const { token } = await onboarded();
      await postGoal(token, goalBody());
      await postGoal(token, singleBody());

      const res = await listGoals(token);

      expect(
        (res.body as GoalListBody).goals.map((goal) => goal.kind).sort(),
      ).toEqual(['goal', 'single']);
    });

    it('?kind=xyz → 400', async () => {
      const { token } = await onboarded();

      const res = await listGoals(token, '?kind=xyz');

      expect(res.status).toBe(400);
    });
  });

  describe('PATCH /goals/:goalId/done (MC10)', () => {
    it('done true → 200 com status done e os blocos futuros da tarefa somem', async () => {
      const { token, user } = await onboarded();
      const goalId = await createdId(token, singleBody());
      const before = await futureBlocksOf(user.id, goalId);

      const res = await patchDone(token, goalId, { done: true });
      const body = res.body as DoneBody;

      expect({
        before: before.length > 0,
        status: res.status,
        goalStatus: body.goal.status,
        progressPct: body.goal.progressPct,
        planHasGoal: body.plan.goals.some((goal) => goal.goalId === goalId),
        after: (await futureBlocksOf(user.id, goalId)).length,
      }).toEqual({
        before: true,
        status: 200,
        goalStatus: 'done',
        progressPct: 100,
        planHasGoal: false,
        after: 0,
      });
    });

    it('done false depois de feita → 200 com status active e os blocos voltam', async () => {
      const { token, user } = await onboarded();
      const goalId = await createdId(token, singleBody());
      await patchDone(token, goalId, { done: true });

      const res = await patchDone(token, goalId, { done: false });
      const body = res.body as DoneBody;
      const blocks = await futureBlocksOf(user.id, goalId);

      expect({
        status: res.status,
        goalStatus: body.goal.status,
        progressPct: body.goal.progressPct,
        planHasGoal: body.plan.goals.some((goal) => goal.goalId === goalId),
        blocks: blocks.reduce((sum, block) => sum + block.durationMinutes, 0),
      }).toEqual({
        status: 200,
        goalStatus: 'active',
        progressPct: 0,
        planHasGoal: true,
        blocks: 30,
      });
    });

    it('a lista mostra a tarefa feita com status done', async () => {
      const { token } = await onboarded();
      const goalId = await createdId(token, singleBody());
      await patchDone(token, goalId, { done: true });

      const res = await listGoals(token, '?kind=single');

      expect(
        (res.body as GoalListBody).goals.map((goal) => [goal.id, goal.status]),
      ).toEqual([[goalId, 'done']]);
    });

    it('objetivo comum → 422', async () => {
      const { token } = await onboarded();
      const goalId = await createdId(token, goalBody());

      const res = await patchDone(token, goalId, { done: true });

      expect(res.status).toBe(422);
    });

    it('tarefa de outro usuário → 404 e ela não muda', async () => {
      const owner = await onboarded();
      const other = await onboarded();
      const goalId = await createdId(owner.token, singleBody());

      const res = await patchDone(other.token, goalId, { done: true });
      const goal = await app
        .get(PrismaGoalRepository)
        .findById(owner.user.id, goalId);

      expect([res.status, goal?.status]).toEqual([404, 'active']);
    });

    it('tarefa inexistente → 404', async () => {
      const { token } = await onboarded();

      const res = await patchDone(token, randomUUID(), { done: true });

      expect(res.status).toBe(404);
    });

    it('sem token → 401', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/goals/${randomUUID()}/done`)
        .send({ done: true });

      expect(res.status).toBe(401);
    });

    it('corpo com campo a mais → 400', async () => {
      const { token } = await onboarded();
      const goalId = await createdId(token, singleBody());

      const res = await patchDone(token, goalId, {
        done: true,
        userId: randomUUID(),
      });

      expect(res.status).toBe(400);
    });

    it('done que não é booleano → 400', async () => {
      const { token } = await onboarded();
      const goalId = await createdId(token, singleBody());

      const res = await patchDone(token, goalId, { done: 'true' });

      expect(res.status).toBe(400);
    });

    it('goalId que não é UUID → 400', async () => {
      const { token } = await onboarded();

      const res = await patchDone(token, 'abc', { done: true });

      expect(res.status).toBe(400);
    });
  });

  describe('DELETE /goals/:goalId (MC11)', () => {
    it('dono → 200 com o plano, o objetivo some da lista e os blocos futuros somem', async () => {
      const { token, user } = await onboarded();
      const goalId = await createdId(token, singleBody());
      const keptId = await createdId(token, goalBody());
      const before = await futureBlocksOf(user.id, goalId);

      const res = await deleteGoal(token, goalId);
      const list = await listGoals(token);

      expect({
        before: before.length > 0,
        status: res.status,
        planGoals: (res.body as { plan: PlanBody }).plan.goals.map(
          (goal) => goal.goalId,
        ),
        list: (list.body as GoalListBody).goals.map((goal) => goal.id),
        after: (await futureBlocksOf(user.id, goalId)).length,
      }).toEqual({
        before: true,
        status: 200,
        planGoals: [keptId],
        list: [keptId],
        after: 0,
      });
    });

    it('apaga também objetivo comum (qualquer kind)', async () => {
      const { token } = await onboarded();
      const goalId = await createdId(token, goalBody());

      const res = await deleteGoal(token, goalId);
      const detail = await request(app.getHttpServer())
        .get(`/goals/${goalId}`)
        .set('Authorization', `Bearer ${token}`);

      expect([res.status, detail.status]).toEqual([200, 404]);
    });

    it('objetivo de outro usuário → 404 e nada é apagado', async () => {
      const owner = await onboarded();
      const other = await onboarded();
      const goalId = await createdId(owner.token, singleBody());

      const res = await deleteGoal(other.token, goalId);
      const goal = await app
        .get(PrismaGoalRepository)
        .findById(owner.user.id, goalId);

      expect([res.status, goal?.id]).toEqual([404, goalId]);
    });

    it('objetivo inexistente → 404', async () => {
      const { token } = await onboarded();

      const res = await deleteGoal(token, randomUUID());

      expect(res.status).toBe(404);
    });

    it('sem token → 401', async () => {
      const res = await request(app.getHttpServer()).delete(
        `/goals/${randomUUID()}`,
      );

      expect(res.status).toBe(401);
    });

    it('goalId que não é UUID → 400', async () => {
      const { token } = await onboarded();

      const res = await deleteGoal(token, 'abc');

      expect(res.status).toBe(400);
    });
  });

  describe('plano do dia e da semana com bloco passado de objetivo apagado', () => {
    // Terça 18/11/2025 19:00–19:30 locais (UTC−3): bloco no passado, que o recálculo não apaga.
    const PAST_MONDAY = '2025-11-17';
    const PAST_DAY = '2025-11-18';

    async function deletedWithPastBlock(): Promise<LoginBody> {
      const login = await onboarded();
      const goalId = await createdId(login.token, singleBody());
      const stepId = (
        await app.get(PrismaGoalRepository).findById(login.user.id, goalId)
      )?.steps[0].id as string;
      await app
        .get(PrismaScheduledBlockRepository)
        .replaceFutureAutoBlocks(
          login.user.id,
          new Date(`${PAST_DAY}T23:59:00.000Z`),
          [
            new ScheduledBlock({
              userId: login.user.id,
              goalId,
              stepId,
              start: new Date(`${PAST_DAY}T22:00:00.000Z`),
              end: new Date(`${PAST_DAY}T22:30:00.000Z`),
              status: 'planned',
              pinned: false,
              origin: 'auto',
            }),
          ],
        );
      await deleteGoal(login.token, goalId);
      return login;
    }

    it('GET /scheduling/plan/day → 200 sem o bloco do objetivo apagado', async () => {
      const { token } = await deletedWithPastBlock();

      const res = await request(app.getHttpServer())
        .get(`/scheduling/plan/day?date=${PAST_DAY}`)
        .set('Authorization', `Bearer ${token}`);

      expect([res.status, (res.body as DayBody).blocks]).toEqual([200, []]);
    });

    it('GET /scheduling/plan/week → 200 sem o bloco do objetivo apagado', async () => {
      const { token } = await deletedWithPastBlock();

      const res = await request(app.getHttpServer())
        .get(`/scheduling/plan/week?start=${PAST_MONDAY}`)
        .set('Authorization', `Bearer ${token}`);

      expect([
        res.status,
        (res.body as { days: DayBody[] }).days.flatMap((day) => day.blocks),
      ]).toEqual([200, []]);
    });
  });
});
