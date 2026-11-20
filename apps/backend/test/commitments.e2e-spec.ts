import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Commitment } from '@oitenta/scheduling';
import { NotFoundError } from '@oitenta/shared';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaCommitmentRepository } from '../src/modules/scheduling/commitment.prisma';
import { PrismaScheduledBlockRepository } from '../src/modules/scheduling/scheduled-block.prisma';

// Integração dos compromissos (docs/4-contrato-api.md §5b; MC1–MC6, MC12). Exige o Postgres no ar.
// As rotas CRUD usam uma semana fixa de 2030 (segunda 18/11/2030), para não depender da data do
// teste; os efeitos no plano usam um dia de daqui a 3 dias. Fuso do cadastro: America/Sao_Paulo.
interface LoginBody {
  token: string;
  user: { id: string };
}
interface CommitmentBody {
  id: string;
  title: string;
  category: string;
  startDate: string;
  startMinute: number;
  endMinute: number;
  recurrence: { weekdays: number[]; endDate?: string } | null;
  exceptions: {
    date: string;
    type: string;
    newDate?: string;
    startMinute?: number;
    endMinute?: number;
  }[];
}
interface OccurrenceBody {
  commitmentId: string;
  date: string;
  originalDate: string;
  startMinute: number;
  endMinute: number;
  status: string;
}
interface BlockBody {
  start: string;
  end: string;
}

const TIMEZONE = 'America/Sao_Paulo';
const MONDAY = '2030-11-18';
const SUNDAY = '2030-11-24';

// Segunda e quarta, 08:00–09:40 (MC2: múltiplos de 5), até 13/12/2030.
const WEEKLY_BODY = {
  title: 'Aula de Cálculo',
  category: 'aula',
  startDate: MONDAY,
  startMinute: 480,
  endMinute: 580,
  recurrence: { weekdays: [0, 2], endDate: '2030-12-13' },
};

const SINGLE_BODY = {
  title: 'Consulta no dentista',
  category: 'saude',
  startDate: '2030-11-19',
  startMinute: 870,
  endMinute: 930,
  recurrence: null,
};

// Todo dia, sem fim, 08:00–09:40.
const DAILY_BODY = {
  title: 'Estágio',
  category: 'trabalho',
  startDate: MONDAY,
  startMinute: 480,
  endMinute: 580,
  recurrence: { weekdays: [0, 1, 2, 3, 4, 5, 6] },
};

const EVERY_DAY_AVAILABILITY = {
  windows: [0, 1, 2, 3, 4, 5, 6].map((weekday) => ({
    weekday,
    startMinute: 360,
    endMinute: 1380,
  })),
  dailyLimitMinutes: 180,
};

const ANY_PLAN = {
  totalMinutes: expect.any(Number) as number,
  days: expect.any(Number) as number,
  goals: expect.any(Array) as unknown[],
};

// Data e minuto locais de um instante no fuso do usuário.
function localParts(instant: Date): { date: string; minute: number } {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-CA', {
      timeZone: TIMEZONE,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hourCycle: 'h23',
    })
      .formatToParts(instant)
      .map((part) => [part.type, part.value]),
  );
  return {
    date: `${parts.year}-${parts.month}-${parts.day}`,
    minute: Number(parts.hour) * 60 + Number(parts.minute),
  };
}

function weekdayOf(date: string): number {
  return (new Date(`${date}T12:00:00.000Z`).getUTCDay() + 6) % 7;
}

function addDays(date: string, days: number): string {
  const base = new Date(`${date}T12:00:00.000Z`);
  base.setUTCDate(base.getUTCDate() + days);
  return base.toISOString().slice(0, 10);
}

describe('compromissos (integração)', () => {
  let app: INestApplication<App>;

  const unique = () =>
    `commitments.${Date.now()}.${Math.round(Math.random() * 1e6)}@bora.app`;

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

  // Usuário com a disponibilidade gravada (pré-requisito do POST, P12).
  async function onboarded(
    availability: object = EVERY_DAY_AVAILABILITY,
  ): Promise<LoginBody> {
    const login = await registerAndLogin();
    await request(app.getHttpServer())
      .put('/scheduling/availability')
      .set('Authorization', `Bearer ${login.token}`)
      .send(availability);
    return login;
  }

  const server = () => request(app.getHttpServer());
  const auth = (token: string) => `Bearer ${token}`;

  const post = (token: string, body: unknown) =>
    server()
      .post('/scheduling/commitments')
      .set('Authorization', auth(token))
      .send(body as object);

  const getOne = (token: string, id: string) =>
    server()
      .get(`/scheduling/commitments/${id}`)
      .set('Authorization', auth(token));

  const occurrences = (token: string, query: string) =>
    server()
      .get(`/scheduling/commitments/occurrences${query}`)
      .set('Authorization', auth(token));

  const patch = (token: string, id: string, body: unknown) =>
    server()
      .patch(`/scheduling/commitments/${id}`)
      .set('Authorization', auth(token))
      .send(body as object);

  const remove = (token: string, id: string, query: string) =>
    server()
      .delete(`/scheduling/commitments/${id}${query}`)
      .set('Authorization', auth(token));

  const putOccurrence = (token: string, id: string, date: string, body: unknown) =>
    server()
      .put(`/scheduling/commitments/${id}/occurrences/${date}`)
      .set('Authorization', auth(token))
      .send(body as object);

  const clearOccurrence = (token: string, id: string, date: string) =>
    server()
      .delete(`/scheduling/commitments/${id}/occurrences/${date}`)
      .set('Authorization', auth(token));

  async function created(token: string, body: object): Promise<CommitmentBody> {
    const res = await post(token, body);
    return (res.body as { commitment: CommitmentBody }).commitment;
  }

  async function weekOccurrences(token: string): Promise<OccurrenceBody[]> {
    const res = await occurrences(token, `?from=${MONDAY}&to=${SUNDAY}`);
    return (res.body as { occurrences: OccurrenceBody[] }).occurrences;
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

  describe('POST /scheduling/commitments', () => {
    it('semanal válido → 201 com o compromisso no formato do contrato e o plano', async () => {
      const { token } = await onboarded();

      const res = await post(token, WEEKLY_BODY);

      expect({ status: res.status, body: res.body as unknown }).toEqual({
        status: 201,
        body: {
          commitment: {
            id: expect.any(String) as string,
            ...WEEKLY_BODY,
            exceptions: [],
          },
          plan: { totalMinutes: 0, days: 0, goals: [] },
        },
      });
    });

    it('único (recurrence null) → 201 com recurrence null', async () => {
      const { token } = await onboarded();

      const res = await post(token, SINGLE_BODY);

      expect({ status: res.status, body: res.body as unknown }).toEqual({
        status: 201,
        body: {
          commitment: {
            id: expect.any(String) as string,
            ...SINGLE_BODY,
            exceptions: [],
          },
          plan: ANY_PLAN,
        },
      });
    });

    it('recorrência sem fim → recurrence sem endDate', async () => {
      const { token } = await onboarded();

      const commitment = await created(token, DAILY_BODY);

      expect(commitment.recurrence).toEqual({
        weekdays: [0, 1, 2, 3, 4, 5, 6],
      });
    });

    it('grava no banco: o GET devolve o mesmo compromisso', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await getOne(token, commitment.id);

      expect(res.body).toEqual({ commitment });
    });

    it('sem disponibilidade → 404 (P12) e nada é gravado', async () => {
      const { token } = await registerAndLogin();

      const res = await post(token, WEEKLY_BODY);

      expect({
        status: res.status,
        occurrences: await weekOccurrences(token),
      }).toEqual({ status: 404, occurrences: [] });
    });

    it('sem token → 401', async () => {
      const res = await server()
        .post('/scheduling/commitments')
        .send(WEEKLY_BODY);

      expect(res.status).toBe(401);
    });

    it('userId no corpo → 400', async () => {
      const { token } = await onboarded();
      const other = await registerAndLogin();

      const res = await post(token, { ...WEEKLY_BODY, userId: other.user.id });

      expect(res.status).toBe(400);
    });

    it.each([
      ['categoria fora da lista', { category: 'festa' }],
      ['startMinute como texto', { startMinute: '08:00' }],
      ['startDate fora do formato', { startDate: '18/11/2030' }],
      ['sem recurrence', { recurrence: undefined }],
      ['weekdays que não é lista', { recurrence: { weekdays: 'segunda' } }],
      ['endDate fora do formato', { recurrence: { weekdays: [0], endDate: '13/12' } }],
    ])('%s → 400', async (_, override) => {
      const { token } = await onboarded();

      const res = await post(token, { ...WEEKLY_BODY, ...override });

      expect(res.status).toBe(400);
    });

    it.each([
      ['fim antes do início', { startMinute: 600, endMinute: 540 }],
      ['horário fora dos múltiplos de 5', { startMinute: 482 }],
      ['título de 1 letra', { title: 'A' }],
      ['dia da semana 7', { recurrence: { weekdays: [7] } }],
      ['data inexistente', { startDate: '2030-02-30' }],
    ])('%s → 422', async (_, override) => {
      const { token } = await onboarded();

      const res = await post(token, { ...WEEKLY_BODY, ...override });

      expect(res.status).toBe(422);
    });
  });

  describe('GET /scheduling/commitments/:id', () => {
    it('do dono → 200 { commitment }', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, SINGLE_BODY);

      const res = await getOne(token, commitment.id);

      expect({ status: res.status, body: res.body as unknown }).toEqual({
        status: 200,
        body: { commitment },
      });
    });

    it('de outro usuário → 404', async () => {
      const { token } = await onboarded();
      const other = await registerAndLogin();
      const commitment = await created(token, SINGLE_BODY);

      const res = await getOne(other.token, commitment.id);

      expect(res.status).toBe(404);
    });

    it('id inexistente → 404', async () => {
      const { token } = await registerAndLogin();

      const res = await getOne(token, randomUUID());

      expect(res.status).toBe(404);
    });

    it('id que não é UUID → 400', async () => {
      const { token } = await registerAndLogin();

      const res = await getOne(token, 'abc');

      expect(res.status).toBe(400);
    });

    it('sem token → 401', async () => {
      const res = await server().get(`/scheduling/commitments/${randomUUID()}`);

      expect(res.status).toBe(401);
    });
  });

  describe('GET /scheduling/commitments/occurrences', () => {
    it('→ 200 com as ocorrências expandidas no intervalo, em ordem', async () => {
      const { token } = await onboarded();
      const weekly = await created(token, WEEKLY_BODY);
      const single = await created(token, SINGLE_BODY);

      const res = await occurrences(token, `?from=${MONDAY}&to=${SUNDAY}`);

      const occurrence = (
        commitment: CommitmentBody,
        date: string,
      ): Record<string, unknown> => ({
        commitmentId: commitment.id,
        title: commitment.title,
        category: commitment.category,
        date,
        originalDate: date,
        startMinute: commitment.startMinute,
        endMinute: commitment.endMinute,
        status: 'normal',
        recurrence: commitment.recurrence,
      });
      expect({ status: res.status, body: res.body as unknown }).toEqual({
        status: 200,
        body: {
          occurrences: [
            occurrence(weekly, '2030-11-18'),
            occurrence(single, '2030-11-19'),
            occurrence(weekly, '2030-11-20'),
          ],
        },
      });
    });

    it('não mostra os compromissos de outro usuário', async () => {
      const { token } = await onboarded();
      const other = await registerAndLogin();
      await created(token, WEEKLY_BODY);

      expect(await weekOccurrences(other.token)).toEqual([]);
    });

    it.each([
      ['from fora do formato', '?from=18/11/2030&to=2030-11-24'],
      ['sem to', '?from=2030-11-18'],
    ])('%s → 400', async (_, query) => {
      const { token } = await registerAndLogin();

      const res = await occurrences(token, query);

      expect(res.status).toBe(400);
    });

    it.each([
      ['mais de 62 dias', '?from=2030-11-18&to=2031-01-19'],
      ['to antes de from', '?from=2030-11-24&to=2030-11-18'],
    ])('%s → 422 (occurrences.range)', async (_, query) => {
      const { token } = await registerAndLogin();

      const res = await occurrences(token, query);

      expect(res.status).toBe(422);
    });

    it('sem token → 401', async () => {
      const res = await server().get(
        `/scheduling/commitments/occurrences?from=${MONDAY}&to=${SUNDAY}`,
      );

      expect(res.status).toBe(401);
    });
  });

  describe('PATCH /scheduling/commitments/:id', () => {
    it('scope all → 200 com o compromisso alterado e o plano', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await patch(token, commitment.id, {
        scope: 'all',
        title: 'Aula de Cálculo II',
        endMinute: 600,
      });

      expect({ status: res.status, body: res.body as unknown }).toEqual({
        status: 200,
        body: {
          commitment: {
            ...commitment,
            title: 'Aula de Cálculo II',
            endMinute: 600,
          },
          plan: ANY_PLAN,
        },
      });
    });

    it('scope all grava no banco', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      await patch(token, commitment.id, { scope: 'all', category: 'pessoal' });

      expect(
        ((await getOne(token, commitment.id)).body as { commitment: CommitmentBody })
          .commitment.category,
      ).toBe('pessoal');
    });

    it('recurrence ausente → mantém a recorrência', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await patch(token, commitment.id, {
        scope: 'all',
        title: 'Outra aula',
      });

      expect(
        (res.body as { commitment: CommitmentBody }).commitment.recurrence,
      ).toEqual(WEEKLY_BODY.recurrence);
    });

    it('recurrence null → vira compromisso único', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await patch(token, commitment.id, {
        scope: 'all',
        recurrence: null,
      });
      const stored = await getOne(token, commitment.id);

      expect({
        status: res.status,
        response: (res.body as { commitment: CommitmentBody }).commitment
          .recurrence,
        stored: (stored.body as { commitment: CommitmentBody }).commitment
          .recurrence,
      }).toEqual({ status: 200, response: null, stored: null });
    });

    it('recurrence objeto → nova recorrência', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, SINGLE_BODY);

      const res = await patch(token, commitment.id, {
        scope: 'all',
        recurrence: { weekdays: [1, 3] },
      });

      expect(
        (res.body as { commitment: CommitmentBody }).commitment.recurrence,
      ).toEqual({ weekdays: [1, 3] });
    });

    it('scope following → 200 com a série nova a partir de fromDate', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, DAILY_BODY);

      const res = await patch(token, commitment.id, {
        scope: 'following',
        fromDate: '2030-11-21',
        startMinute: 600,
        endMinute: 700,
      });

      expect({ status: res.status, body: res.body as unknown }).toEqual({
        status: 200,
        body: {
          commitment: {
            ...commitment,
            id: expect.not.stringMatching(commitment.id) as string,
            startDate: '2030-11-21',
            startMinute: 600,
            endMinute: 700,
          },
          plan: ANY_PLAN,
        },
      });
    });

    it('de outro usuário → 404 e o compromisso não muda', async () => {
      const { token } = await onboarded();
      const other = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await patch(other.token, commitment.id, {
        scope: 'all',
        title: 'Invadido',
      });
      const stored = await getOne(token, commitment.id);

      expect({
        status: res.status,
        title: (stored.body as { commitment: CommitmentBody }).commitment.title,
      }).toEqual({ status: 404, title: WEEKLY_BODY.title });
    });

    it('sem token → 401', async () => {
      const res = await server()
        .patch(`/scheduling/commitments/${randomUUID()}`)
        .send({ scope: 'all', title: 'Aula' });

      expect(res.status).toBe(401);
    });

    it.each([
      ['userId no corpo', { scope: 'all', userId: randomUUID() }],
      ['sem scope', { title: 'Aula' }],
      ['scope fora da lista', { scope: 'some' }],
      ['following sem fromDate', { scope: 'following', title: 'Aula' }],
      ['startMinute como texto', { scope: 'all', startMinute: '10:00' }],
      ['title null', { scope: 'all', title: null }],
    ])('%s → 400', async (_, body) => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await patch(token, commitment.id, body);

      expect(res.status).toBe(400);
    });

    it('fim antes do início → 422', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await patch(token, commitment.id, {
        scope: 'all',
        endMinute: 420,
      });

      expect(res.status).toBe(422);
    });
  });

  describe('DELETE /scheduling/commitments/:id', () => {
    it('scope all → 200 { plan } e o compromisso some', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await remove(token, commitment.id, '?scope=all');

      expect({
        status: res.status,
        body: res.body as unknown,
        after: (await getOne(token, commitment.id)).status,
      }).toEqual({ status: 200, body: { plan: ANY_PLAN }, after: 404 });
    });

    it('de outro usuário → 404 e o compromisso continua', async () => {
      const { token } = await onboarded();
      const other = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await remove(other.token, commitment.id, '?scope=all');

      expect({
        status: res.status,
        after: (await getOne(token, commitment.id)).status,
      }).toEqual({ status: 404, after: 200 });
    });

    it('sem token → 401', async () => {
      const res = await server().delete(
        `/scheduling/commitments/${randomUUID()}?scope=all`,
      );

      expect(res.status).toBe(401);
    });

    it.each([
      ['sem scope', ''],
      ['scope fora da lista', '?scope=some'],
      ['following sem fromDate', '?scope=following'],
      ['fromDate fora do formato', '?scope=following&fromDate=21/11/2030'],
    ])('%s → 400', async (_, query) => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await remove(token, commitment.id, query);

      expect(res.status).toBe(400);
    });
  });

  describe('PUT /scheduling/commitments/:id/occurrences/:date', () => {
    it('cancelled → 200 com a exceção e o plano', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await putOccurrence(token, commitment.id, '2030-11-20', {
        status: 'cancelled',
      });

      expect({ status: res.status, body: res.body as unknown }).toEqual({
        status: 200,
        body: {
          commitment: {
            ...commitment,
            exceptions: [{ date: '2030-11-20', type: 'cancelled' }],
          },
          plan: ANY_PLAN,
        },
      });
    });

    it('moved → 200 com o novo dia e horário; a ocorrência aparece movida', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await putOccurrence(token, commitment.id, '2030-11-20', {
        status: 'moved',
        newDate: '2030-11-21',
        startMinute: 600,
        endMinute: 700,
      });
      const moved = (await weekOccurrences(token)).find(
        (item) => item.originalDate === '2030-11-20',
      );

      expect({
        status: res.status,
        exceptions: (res.body as { commitment: CommitmentBody }).commitment
          .exceptions,
        moved,
      }).toEqual({
        status: 200,
        exceptions: [
          {
            date: '2030-11-20',
            type: 'moved',
            newDate: '2030-11-21',
            startMinute: 600,
            endMinute: 700,
          },
        ],
        moved: expect.objectContaining({
          date: '2030-11-21',
          startMinute: 600,
          endMinute: 700,
          status: 'moved',
        }) as OccurrenceBody,
      });
    });

    it('data que não é ocorrência → 422', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await putOccurrence(token, commitment.id, '2030-11-19', {
        status: 'cancelled',
      });

      expect(res.status).toBe(422);
    });

    it('moved sem o novo horário → 422', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await putOccurrence(token, commitment.id, '2030-11-20', {
        status: 'moved',
        newDate: '2030-11-21',
      });

      expect(res.status).toBe(422);
    });

    it('de outro usuário → 404', async () => {
      const { token } = await onboarded();
      const other = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await putOccurrence(other.token, commitment.id, '2030-11-20', {
        status: 'cancelled',
      });

      expect(res.status).toBe(404);
    });

    it('sem token → 401', async () => {
      const res = await server()
        .put(`/scheduling/commitments/${randomUUID()}/occurrences/2030-11-20`)
        .send({ status: 'cancelled' });

      expect(res.status).toBe(401);
    });

    it.each([
      ['userId no corpo', '2030-11-20', { status: 'cancelled', userId: randomUUID() }],
      ['status fora da lista', '2030-11-20', { status: 'skipped' }],
      ['startMinute como texto', '2030-11-20', { status: 'moved', newDate: '2030-11-21', startMinute: '10:00', endMinute: 700 }],
      ['data da rota fora do formato', '20-11-2030', { status: 'cancelled' }],
    ])('%s → 400', async (_, date, body) => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await putOccurrence(token, commitment.id, date, body);

      expect(res.status).toBe(400);
    });
  });

  describe('DELETE /scheduling/commitments/:id/occurrences/:date', () => {
    it('com exceção na data → 200 sem a exceção e o plano', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);
      await putOccurrence(token, commitment.id, '2030-11-20', {
        status: 'cancelled',
      });

      const res = await clearOccurrence(token, commitment.id, '2030-11-20');

      expect({ status: res.status, body: res.body as unknown }).toEqual({
        status: 200,
        body: { commitment: { ...commitment, exceptions: [] }, plan: ANY_PLAN },
      });
    });

    it('sem exceção na data → 404', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await clearOccurrence(token, commitment.id, '2030-11-20');

      expect(res.status).toBe(404);
    });

    it('de outro usuário → 404 e a exceção continua', async () => {
      const { token } = await onboarded();
      const other = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);
      await putOccurrence(token, commitment.id, '2030-11-20', {
        status: 'cancelled',
      });

      const res = await clearOccurrence(other.token, commitment.id, '2030-11-20');
      const stored = await getOne(token, commitment.id);

      expect({
        status: res.status,
        exceptions: (stored.body as { commitment: CommitmentBody }).commitment
          .exceptions,
      }).toEqual({
        status: 404,
        exceptions: [{ date: '2030-11-20', type: 'cancelled' }],
      });
    });

    it('sem token → 401', async () => {
      const res = await server().delete(
        `/scheduling/commitments/${randomUUID()}/occurrences/2030-11-20`,
      );

      expect(res.status).toBe(401);
    });

    it('data da rota fora do formato → 400', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, WEEKLY_BODY);

      const res = await clearOccurrence(token, commitment.id, '20-11-2030');

      expect(res.status).toBe(400);
    });
  });

  describe('efeitos no plano e nas ocorrências', () => {
    // Disponibilidade só no dia da semana de daqui a 3 dias (19:00–23:00): o primeiro bloco
    // do objetivo cai nesse dia, longe do "agora" do teste.
    async function userWithPlannedBlock(): Promise<{
      login: LoginBody;
      date: string;
      start: Date;
      end: Date;
    }> {
      const target = addDays(localParts(new Date()).date, 3);
      const login = await onboarded({
        windows: [
          { weekday: weekdayOf(target), startMinute: 1140, endMinute: 1380 },
        ],
        dailyLimitMinutes: 180,
      });
      await server()
        .post('/goals')
        .set('Authorization', auth(login.token))
        .send({
          title: 'TCC',
          kind: 'goal',
          deadline: addDays(target, 40),
          steps: [{ title: 'Ler os artigos', estimatedMinutes: 60 }],
        });
      const [first] = await app
        .get(PrismaScheduledBlockRepository)
        .findByUserInRange(
          login.user.id,
          new Date(),
          new Date(Date.now() + 60 * 86_400_000),
        );
      return {
        login,
        date: localParts(first.start).date,
        start: first.start,
        end: first.end,
      };
    }

    async function dayBlocks(token: string, date: string): Promise<BlockBody[]> {
      const res = await server()
        .get(`/scheduling/plan/day?date=${date}`)
        .set('Authorization', auth(token));
      return (res.body as { blocks: BlockBody[] }).blocks;
    }

    const overlaps = (block: BlockBody, start: Date, end: Date) =>
      new Date(block.start) < end && new Date(block.end) > start;

    // Compromisso único que cobre o horário do bloco (arredondado para os múltiplos de 5).
    const coveringBody = (date: string, start: Date, end: Date) => {
      const startMinute = localParts(start).minute;
      const endMinute = localParts(end).minute;
      return {
        title: 'Plantão',
        category: 'trabalho',
        startDate: date,
        startMinute: Math.floor(startMinute / 5) * 5,
        endMinute: Math.ceil(endMinute / 5) * 5,
        recurrence: null,
      };
    };

    it('1. compromisso sobre o bloco → o dia não tem mais bloco sobreposto', async () => {
      const { login, date, start, end } = await userWithPlannedBlock();

      const res = await post(login.token, coveringBody(date, start, end));
      const blocks = await dayBlocks(login.token, date);

      expect({
        status: res.status,
        scheduled: (res.body as { plan: { totalMinutes: number } }).plan
          .totalMinutes,
        overlapping: blocks.filter((block) => overlaps(block, start, end)),
      }).toEqual({ status: 201, scheduled: 60, overlapping: [] });
    });

    it('2. "Não vai ter nesse dia" → ocorrência cancelled e o horário volta a ter bloco', async () => {
      const { login, date, start, end } = await userWithPlannedBlock();
      const commitment = await created(login.token, coveringBody(date, start, end));

      const res = await putOccurrence(login.token, commitment.id, date, {
        status: 'cancelled',
      });
      const listed = await occurrences(login.token, `?from=${date}&to=${date}`);
      const blocks = await dayBlocks(login.token, date);

      expect({
        status: res.status,
        statuses: (listed.body as { occurrences: OccurrenceBody[] }).occurrences.map(
          (item) => item.status,
        ),
        overlapping: blocks.filter((block) => overlaps(block, start, end)).length,
      }).toEqual({ status: 200, statuses: ['cancelled'], overlapping: 1 });
    });

    it('3. PATCH scope=following → antes de fromDate o horário antigo, a partir dele o novo', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, DAILY_BODY);

      await patch(token, commitment.id, {
        scope: 'following',
        fromDate: '2030-11-21',
        startMinute: 600,
        endMinute: 700,
      });
      const previous = await getOne(token, commitment.id);

      expect({
        week: (await weekOccurrences(token)).map((item) => [
          item.date,
          item.startMinute,
          item.endMinute,
        ]),
        previousRecurrence: (previous.body as { commitment: CommitmentBody })
          .commitment.recurrence,
      }).toEqual({
        week: [
          ['2030-11-18', 480, 580],
          ['2030-11-19', 480, 580],
          ['2030-11-20', 480, 580],
          ['2030-11-21', 600, 700],
          ['2030-11-22', 600, 700],
          ['2030-11-23', 600, 700],
          ['2030-11-24', 600, 700],
        ],
        previousRecurrence: {
          weekdays: [0, 1, 2, 3, 4, 5, 6],
          endDate: '2030-11-20',
        },
      });
    });

    it('4. DELETE scope=following → nenhuma ocorrência a partir de fromDate', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, DAILY_BODY);

      const res = await remove(
        token,
        commitment.id,
        '?scope=following&fromDate=2030-11-21',
      );

      expect({
        status: res.status,
        dates: (await weekOccurrences(token)).map((item) => item.date),
      }).toEqual({
        status: 200,
        dates: ['2030-11-18', '2030-11-19', '2030-11-20'],
      });
    });

    it('DELETE scope=following desde o primeiro dia → a série é apagada', async () => {
      const { token } = await onboarded();
      const commitment = await created(token, DAILY_BODY);

      await remove(token, commitment.id, `?scope=following&fromDate=${MONDAY}`);

      expect((await getOne(token, commitment.id)).status).toBe(404);
    });
  });

  describe('PrismaCommitmentRepository', () => {
    let repository: PrismaCommitmentRepository;
    let ownerId: string;
    let otherId: string;

    const commitment = (userId: string) =>
      new Commitment({
        userId,
        title: 'Aula',
        category: 'aula',
        kind: 'commitment',
        startDate: MONDAY,
        startMinute: 480,
        endMinute: 580,
        recurrence: { weekdays: [0, 2] },
        exceptions: [
          { date: '2030-11-18', type: 'cancelled' },
          {
            date: '2030-11-20',
            type: 'moved',
            newDate: '2030-11-21',
            startMinute: 600,
            endMinute: 700,
          },
        ],
      });

    beforeEach(async () => {
      repository = app.get(PrismaCommitmentRepository);
      ownerId = (await registerAndLogin()).user.id;
      otherId = (await registerAndLogin()).user.id;
    });

    it('create + findById do dono devolve o agregado com as exceções', async () => {
      const owned = commitment(ownerId);
      await repository.create(owned);

      const found = await repository.findById(ownerId, owned.id);

      expect({
        recurrence: found?.recurrence,
        exceptions: found?.exceptions,
      }).toEqual({ recurrence: owned.recurrence, exceptions: owned.exceptions });
    });

    it('findById de outro usuário → null', async () => {
      const owned = commitment(ownerId);
      await repository.create(owned);

      expect(await repository.findById(otherId, owned.id)).toBeNull();
    });

    it('findAllByUser devolve só os do usuário', async () => {
      const owned = commitment(ownerId);
      await repository.create(owned);
      await repository.create(commitment(otherId));

      expect(
        (await repository.findAllByUser(ownerId)).map((item) => item.id),
      ).toEqual([owned.id]);
    });

    it('update sincroniza as exceções (tira, troca e acrescenta)', async () => {
      const owned = commitment(ownerId);
      await repository.create(owned);
      const changed = owned
        .withoutException('2030-11-18')
        .withException({ date: '2030-11-20', type: 'cancelled' })
        .withException({ date: '2030-11-25', type: 'cancelled' });

      await repository.update(changed);

      expect((await repository.findById(ownerId, owned.id))?.exceptions).toEqual([
        { date: '2030-11-20', type: 'cancelled' },
        { date: '2030-11-25', type: 'cancelled' },
      ]);
    });

    it('update de compromisso de outro usuário → NotFoundError e nada muda', async () => {
      const owned = commitment(ownerId);
      await repository.create(owned);

      await expect(
        repository.update(owned.clone({ userId: otherId, exceptions: [] })),
      ).rejects.toBeInstanceOf(NotFoundError);
      expect(
        (await repository.findById(ownerId, owned.id))?.exceptions,
      ).toHaveLength(2);
    });

    it('delete de outro usuário → NotFoundError e o compromisso continua', async () => {
      const owned = commitment(ownerId);
      await repository.create(owned);

      await expect(repository.delete(otherId, owned.id)).rejects.toBeInstanceOf(
        NotFoundError,
      );
      expect(await repository.findById(ownerId, owned.id)).not.toBeNull();
    });

    it('delete do dono apaga o compromisso e as exceções', async () => {
      const owned = commitment(ownerId);
      await repository.create(owned);

      await repository.delete(ownerId, owned.id);

      expect(await repository.findById(ownerId, owned.id)).toBeNull();
    });
  });
});
