import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/db/prisma.service';

// Integração do auth contra o banco local (docs/4-contrato-api.md §1). Exige o Postgres no ar.
interface UserBody {
  user: { timezone: string };
}
interface ErrorBody {
  details: string[];
}
interface LoginBody {
  token: string;
}

describe('auth (integração)', () => {
  let app: INestApplication<App>;
  const unique = () =>
    `teste.${Date.now()}.${Math.round(Math.random() * 1e6)}@bora.app`;

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

  it('C0: cadastro com fuso → 201 e devolve o fuso', async () => {
    const res = await request(app.getHttpServer()).post('/auth/register').send({
      name: 'Ana Souza',
      email: unique(),
      password: 'Senha@123',
      timezone: 'America/Manaus',
    });

    expect(res.status).toBe(201);
    expect((res.body as UserBody).user.timezone).toBe('America/Manaus');
  });

  it('C0: cadastro sem fuso → 201 com America/Sao_Paulo', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ name: 'Ana Souza', email: unique(), password: 'Senha@123' });

    expect(res.status).toBe(201);
    expect((res.body as UserBody).user.timezone).toBe('America/Sao_Paulo');
  });

  it('C0: cadastro com fuso inválido → 422', async () => {
    const res = await request(app.getHttpServer()).post('/auth/register').send({
      name: 'Ana Souza',
      email: unique(),
      password: 'Senha@123',
      timezone: 'Lua/Base',
    });

    expect(res.status).toBe(422);
    expect((res.body as ErrorBody).details).toContain(
      'user.timezone.invalid.timezone',
    );
  });

  it('MP2: cadastro com nome de uma palavra ("Arthur") → 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ name: 'Arthur', email: unique(), password: 'Senha@123' });

    expect(res.status).toBe(201);
    expect((res.body as { user: { name: string } }).user.name).toBe('Arthur');
  });

  it('MP2: cadastro com nome de um caractere ("A") → 422', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ name: 'A', email: unique(), password: 'Senha@123' });

    expect(res.status).toBe(422);
    expect((res.body as ErrorBody).details).toContain('user.name.min.length');
  });

  it('C0: /auth/me devolve o fuso do usuário do token', async () => {
    const email = unique();
    await request(app.getHttpServer()).post('/auth/register').send({
      name: 'Ana Souza',
      email,
      password: 'Senha@123',
      timezone: 'America/Recife',
    });
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password: 'Senha@123' });

    const me = await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${(login.body as LoginBody).token}`);

    expect(me.status).toBe(200);
    expect((me.body as UserBody).user.timezone).toBe('America/Recife');
  });

  it('P19: cadastro sem e-mail → 400', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ name: 'Ana Souza', password: 'Senha@123' });

    expect(res.status).toBe(400);
  });

  it('P19: cadastro com campo não previsto (userId) → 400', async () => {
    const res = await request(app.getHttpServer()).post('/auth/register').send({
      name: 'Ana Souza',
      email: unique(),
      password: 'Senha@123',
      userId: '00000000-0000-4000-8000-000000000000',
    });

    expect(res.status).toBe(400);
  });

  it('P19: login com tipo errado → 400', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 123, password: 'Senha@123' });

    expect(res.status).toBe(400);
  });

  it('/auth/me sem token → 401', async () => {
    const res = await request(app.getHttpServer()).get('/auth/me');

    expect(res.status).toBe(401);
  });

  describe('PATCH /auth/me (AT3: editar nome e e-mail)', () => {
    interface ProfileBody {
      user: { id: string; name: string; email: string };
    }

    /** Cadastra, entra e devolve o token e o id da conta nova. */
    async function newAccount() {
      const email = unique();
      const reg = await request(app.getHttpServer())
        .post('/auth/register')
        .send({ name: 'Ana Souza', email, password: 'Senha@123' });
      const login = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email, password: 'Senha@123' });
      return {
        email,
        id: (reg.body as ProfileBody).user.id,
        token: (login.body as LoginBody).token,
      };
    }

    const patch = (token: string, body: object) =>
      request(app.getHttpServer())
        .patch('/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send(body);

    it('troca o nome → 200, mesmo id, e o /auth/me já mostra', async () => {
      const ana = await newAccount();

      const res = await patch(ana.token, { name: 'Ana Clara' });

      expect(res.status).toBe(200);
      expect((res.body as ProfileBody).user).toMatchObject({
        id: ana.id,
        name: 'Ana Clara',
        email: ana.email,
      });
      const me = await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', `Bearer ${ana.token}`);
      expect((me.body as ProfileBody).user.name).toBe('Ana Clara');
    });

    it('troca o e-mail com a senha atual → 200 e o login passa a ser o novo', async () => {
      const ana = await newAccount();
      const novo = unique();

      const res = await patch(ana.token, {
        email: novo,
        currentPassword: 'Senha@123',
      });

      expect(res.status).toBe(200);
      const login = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: novo, password: 'Senha@123' });
      expect(login.status).toBe(200);
      // O token antigo continua valendo: o dono vem do id, não do e-mail.
      const me = await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', `Bearer ${ana.token}`);
      expect((me.body as ProfileBody).user.email).toBe(novo);
    });

    it('trocar o e-mail com a senha errada → 403 (não 401)', async () => {
      const ana = await newAccount();

      const res = await patch(ana.token, {
        email: unique(),
        currentPassword: 'Errada@123',
      });

      expect(res.status).toBe(403);
    });

    it('e-mail de outra conta → 409', async () => {
      const ana = await newAccount();
      const bia = await newAccount();

      const res = await patch(ana.token, {
        email: bia.email,
        currentPassword: 'Senha@123',
      });

      expect(res.status).toBe(409);
    });

    it('nome de um caractere → 422', async () => {
      const ana = await newAccount();

      const res = await patch(ana.token, { name: 'A' });

      expect(res.status).toBe(422);
    });

    it('campo não previsto (id) → 400: não dá para editar outra conta', async () => {
      const ana = await newAccount();
      const bia = await newAccount();

      const res = await patch(ana.token, { id: bia.id, name: 'Invasora' });

      expect(res.status).toBe(400);
    });

    it('sem token → 401', async () => {
      const res = await request(app.getHttpServer())
        .patch('/auth/me')
        .send({ name: 'Ana Clara' });

      expect(res.status).toBe(401);
    });
  });

  describe('Zona de risco (AT9)', () => {
    /** Cadastra, entra e devolve o e-mail, o token e o id da conta nova. */
    async function account() {
      const email = unique();
      const reg = await request(app.getHttpServer())
        .post('/auth/register')
        .send({ name: 'Ana Souza', email, password: 'Senha@123' });
      const login = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email, password: 'Senha@123' });
      return {
        email,
        id: (reg.body as { user: { id: string } }).user.id,
        token: (login.body as LoginBody).token,
      };
    }

    const changePassword = (token: string, body: object) =>
      request(app.getHttpServer())
        .patch('/auth/me/password')
        .set('Authorization', `Bearer ${token}`)
        .send(body);

    const deleteMe = (token: string, body: object) =>
      request(app.getHttpServer())
        .delete('/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .send(body);

    it('PATCH /auth/me/password → 204 e o login passa a ser com a senha nova', async () => {
      const ana = await account();

      const res = await changePassword(ana.token, {
        currentPassword: 'Senha@123',
        newPassword: 'Nova@4567',
      });

      expect(res.status).toBe(204);
      const novo = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: ana.email, password: 'Nova@4567' });
      expect(novo.status).toBe(200);
      const antigo = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: ana.email, password: 'Senha@123' });
      expect(antigo.status).toBe(401);
    });

    it('PATCH /auth/me/password com a senha atual errada → 403', async () => {
      const ana = await account();
      const res = await changePassword(ana.token, {
        currentPassword: 'Errada@123',
        newPassword: 'Nova@4567',
      });
      expect(res.status).toBe(403);
    });

    it('PATCH /auth/me/password com senha nova fraca → 422', async () => {
      const ana = await account();
      const res = await changePassword(ana.token, {
        currentPassword: 'Senha@123',
        newPassword: 'fraca',
      });
      expect(res.status).toBe(422);
    });

    it('PATCH /auth/me/password sem a senha nova → 400; sem token → 401', async () => {
      const ana = await account();
      expect(
        (await changePassword(ana.token, { currentPassword: 'Senha@123' }))
          .status,
      ).toBe(400);
      const semToken = await request(app.getHttpServer())
        .patch('/auth/me/password')
        .send({ currentPassword: 'Senha@123', newPassword: 'Nova@4567' });
      expect(semToken.status).toBe(401);
    });

    it('DELETE /auth/me → 204 e apaga a conta e todos os dados dela', async () => {
      const ana = await account();
      const bia = await account();
      const auth = { Authorization: `Bearer ${ana.token}` };
      await request(app.getHttpServer())
        .put('/scheduling/availability')
        .set(auth)
        .send({
          windows: [0, 1, 2, 3, 4, 5, 6].map((weekday) => ({
            weekday,
            startMinute: 360,
            endMinute: 1380,
          })),
          dailyLimitMinutes: 180,
        });
      await request(app.getHttpServer())
        .post('/goals')
        .set(auth)
        .send({
          title: 'TCC',
          deadline: new Date(Date.now() + 14 * 86_400_000)
            .toISOString()
            .slice(0, 10),
          kind: 'goal',
          steps: [{ title: 'Ler', estimatedMinutes: 60 }],
        });

      const res = await deleteMe(ana.token, { currentPassword: 'Senha@123' });

      expect(res.status).toBe(204);
      const prisma = app.get(PrismaService);
      const where = { userId: ana.id };
      expect(await prisma.user.count({ where: { id: ana.id } })).toBe(0);
      expect(await prisma.goal.count({ where })).toBe(0);
      expect(await prisma.scheduledBlock.count({ where })).toBe(0);
      expect(await prisma.weeklyAvailability.count({ where })).toBe(0);
      // O token antigo deixa de valer, e o e-mail pode ser usado de novo.
      const me = await request(app.getHttpServer())
        .get('/auth/me')
        .set(auth);
      expect(me.status).toBe(401);
      const again = await request(app.getHttpServer())
        .post('/auth/register')
        .send({ name: 'Ana Souza', email: ana.email, password: 'Senha@123' });
      expect(again.status).toBe(201);
      // Posse: a outra conta continua.
      expect(await prisma.user.count({ where: { id: bia.id } })).toBe(1);
    });

    it('DELETE /auth/me com a senha errada → 403 e nada é apagado', async () => {
      const ana = await account();
      const res = await deleteMe(ana.token, { currentPassword: 'Errada@123' });
      expect(res.status).toBe(403);
      const prisma = app.get(PrismaService);
      expect(await prisma.user.count({ where: { id: ana.id } })).toBe(1);
    });

    it('DELETE /auth/me da conta demo → 403', async () => {
      const demo = await request(app.getHttpServer()).post('/auth/demo');
      const token = (demo.body as LoginBody).token;
      // A senha do demo não importa: a regra do demo vem depois da senha;
      // com a senha errada também é 403.
      const res = await deleteMe(token, { currentPassword: 'qualquer' });
      expect(res.status).toBe(403);
      expect((await request(app.getHttpServer()).post('/auth/demo')).status).toBe(200);
    });

    it('DELETE /auth/me sem a senha → 400; sem token → 401', async () => {
      const ana = await account();
      expect((await deleteMe(ana.token, {})).status).toBe(400);
      const semToken = await request(app.getHttpServer())
        .delete('/auth/me')
        .send({ currentPassword: 'Senha@123' });
      expect(semToken.status).toBe(401);
    });
  });
});
