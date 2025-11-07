import request from 'supertest';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { createServer } from './testServer.js';

dotenv.config({ path: '.env' });

let app, server;

beforeAll(async () => {
  const started = await createServer();
  app = started.app;
  server = started.server;
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
  server.close();
});

describe('Auth flow', () => {
  it('registers and logs in', async () => {
    const reg = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Alice', email: 'alice@example.com', password: 'secret12' });
    expect(reg.status).toBe(201);
    expect(reg.body.token).toBeTruthy();

    const login = await request(app)
      .post('/api/auth/login')
      .send({ email: 'alice@example.com', password: 'secret12' });
    expect(login.status).toBe(200);
    expect(login.body.token).toBeTruthy();

    const me = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${login.body.token}`);
    expect(me.status).toBe(200);
    expect(me.body.user.email).toBe('alice@example.com');
  });
});
