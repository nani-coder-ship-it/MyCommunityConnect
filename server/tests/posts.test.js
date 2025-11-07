import request from 'supertest';
import mongoose from 'mongoose';
import { createServer } from './testServer.js';

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

describe('Posts CRUD', () => {
  let token;
  beforeAll(async () => {
    const reg = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Bob', email: 'bob@example.com', password: 'secret12' });
    token = reg.body.token;
  });

  it('creates and lists posts', async () => {
    const created = await request(app)
      .post('/api/posts')
      .set('Authorization', `Bearer ${token}`)
      .send({ message: 'Hello community!' });
    expect(created.status).toBe(201);

    const list = await request(app).get('/api/posts?limit=5&page=1');
    expect(list.status).toBe(200);
    expect(list.body.items.length).toBeGreaterThan(0);
  });
});
