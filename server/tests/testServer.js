import express from 'express';
import http from 'http';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { Server as SocketIOServer } from 'socket.io';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';

import authRoutes from '../routes/auth.routes.js';
import postsRoutes from '../routes/posts.routes.js';

export async function createServer() {
  const mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  const app = express();
  const server = http.createServer(app);
  const io = new SocketIOServer(server, { cors: { origin: '*' } });
  app.set('io', io);

  app.use(cors());
  app.use(helmet());
  app.use(express.json());
  app.use(morgan('dev'));

  app.use('/api/auth', authRoutes);
  app.use('/api/posts', postsRoutes);

  return { app, server };
}
