import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';

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
});
