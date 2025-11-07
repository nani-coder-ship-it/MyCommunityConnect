import express from 'express';
import http from 'http';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { Server as SocketIOServer } from 'socket.io';
import mongoose from 'mongoose';
import jwt from 'jsonwebtoken';

import { connectDB } from './config/db.js';
import { jwtConfig } from './config/jwtConfig.js';
import { initializeFirebase } from './services/notification.service.js';

// Routes
import authRoutes from './routes/auth.routes.js';
import usersRoutes from './routes/users.routes.js';
import postsRoutes from './routes/posts.routes.js';
import contactsRoutes from './routes/contacts.routes.js';
import eventsRoutes from './routes/events.routes.js';
import visitorsRoutes from './routes/visitors.routes.js';
import maintenanceRoutes from './routes/maintenance.routes.js';
import alertsRoutes from './routes/alerts.routes.js';
import chatRoutes from './routes/chat.routes.js';

// Models for socket handlers
import { Message } from './models/Message.js';
import { Alert } from './models/Alert.js';
import { User } from './models/User.js';
import { sendNotificationToUser, sendNotificationToAll } from './services/notification.service.js';

dotenv.config();
initializeFirebase();

const app = express();
const server = http.createServer(app);

const corsOrigins = (process.env.CORS_ORIGIN || '').split(',').filter(Boolean);
app.use(cors({ origin: corsOrigins.length ? corsOrigins : true }));
app.use(helmet());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));
// Serve uploaded files
app.use('/uploads', express.static('uploads'));

// Health check
app.get('/health', (_req, res) => res.json({ ok: true }));

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/posts', postsRoutes);
app.use('/api/contacts', contactsRoutes);
app.use('/api/events', eventsRoutes);
app.use('/api/visitors', visitorsRoutes);
app.use('/api/maintenance', maintenanceRoutes);
app.use('/api/alerts', alertsRoutes);
app.use('/api/chat', chatRoutes);

// Socket.IO
const io = new SocketIOServer(server, {
  cors: { origin: corsOrigins.length ? corsOrigins : '*' },
});
app.set('io', io);

io.use((socket, next) => {
  const token = socket.handshake.auth?.token || socket.handshake.headers['authorization']?.split(' ')[1];
  if (!token) return next(new Error('Unauthorized'));
  try {
    const payload = jwt.verify(token, jwtConfig.secret);
    socket.user = { id: payload.id, role: payload.role };
    return next();
  } catch (e) {
    return next(new Error('Unauthorized'));
  }
});

io.on('connection', async (socket) => {
  const userId = socket.user.id;
  
  // Get user info
  const user = await User.findById(userId).select('name');
  const userName = user?.name || 'User';
  
  socket.join('community');
  socket.join('residents');
  socket.join(`user:${userId}`);

  socket.on('chat:message', async ({ roomId = 'community', text, imageUrl }) => {
    console.log('[CHAT] Received message:', { roomId, userId, userName, text });
    if (!text && !imageUrl) return;
    const msg = await Message.create({ roomId, senderId: userId, senderName: userName, text, imageUrl });
    console.log('[CHAT] Message saved:', msg);
    
    // Get sender's profile picture
    const sender = await User.findById(userId).select('profilePicture');
    const messageWithProfile = {
      ...msg.toObject(),
      senderId: userId.toString(), // Ensure senderId is a string for mobile comparison
      senderProfilePicture: sender?.profilePicture || null,
    };
    
    io.to(roomId).emit('chat:new_message', messageWithProfile);
    console.log('[CHAT] Message broadcasted to room:', roomId);
    
    // Determine private vs group chat by roomId format
    const isPrivate = typeof roomId === 'string' && roomId.startsWith('user:');
    if (isPrivate) {
      // Private chat expects room format: "user:{senderId}-{recipientId}"
      const parts = roomId.split('-');
      if (parts.length === 2) {
        const left = parts[0];
        const right = parts[1];
        const leftId = left.replace('user:', '');
        const recipientId = leftId === String(userId) ? right : leftId;
        if (String(recipientId) !== String(userId)) {
          console.log('🔔 Attempting to send private chat notification...');
          sendNotificationToUser(
            recipientId,
            {
              title: `New message from ${userName}`,
              body: text.substring(0, 100),
            },
            {
              type: 'chat_message',
              roomId,
              senderId: userId.toString(),
            }
          )
            .then((result) => console.log('✅ Private chat notification result:', result))
            .catch((err) => console.error('❌ Failed to send private chat notification:', err));
        }
      }
    } else {
      // Any room that doesn't start with 'user:' is treated as a group chat
      console.log('🔔 Attempting to send group chat notification...');
      sendNotificationToAll(
        imageUrl
          ? { title: `${userName} in ${roomId}`, body: 'sent a photo' }
          : { title: `${userName} in ${roomId}`, body: (text || '').substring(0, 100) },
        {
          type: 'chat_message',
          roomId,
          senderId: userId.toString(),
        },
        [userId]
      )
        .then((result) => console.log('✅ Group chat notification result:', result))
        .catch((err) => console.error('❌ Failed to send group chat notification:', err));
    }
  });

  // Typing indicators
  socket.on('chat:typing', ({ roomId = 'community' } = {}) => {
    try {
      socket.to(roomId).emit('chat:typing', {
        roomId,
        userId: userId.toString(),
        userName,
      });
    } catch (e) {
      console.warn('[CHAT] typing emit failed', e);
    }
  });

  socket.on('chat:stop_typing', ({ roomId = 'community' } = {}) => {
    try {
      socket.to(roomId).emit('chat:stop_typing', {
        roomId,
        userId: userId.toString(),
        userName,
      });
    } catch (e) {
      console.warn('[CHAT] stop_typing emit failed', e);
    }
  });

  // Read receipts: client notifies server when it has seen messages
  socket.on('chat:read', async ({ roomId = 'community', messageIds = [] } = {}) => {
    try {
      if (!Array.isArray(messageIds) || messageIds.length === 0) return;
      const updates = await Promise.all(messageIds.map(async (id) => {
        const msg = await Message.findById(id);
        if (!msg) return null;
        // Add userId to readBy if not present
        const uid = new mongoose.Types.ObjectId(userId);
        if (!msg.readBy?.some(r => String(r) === String(userId))) {
          msg.readBy = msg.readBy || [];
          msg.readBy.push(uid);
          await msg.save();
          // Notify room about read change
          io.to(roomId).emit('chat:message_read', { messageId: id, userId: userId.toString() });
        }
        return id;
      }));
      console.log('[CHAT] Marked read for messages:', updates.filter(Boolean).length);
    } catch (e) {
      console.error('[CHAT] read handler failed', e);
    }
  });

  socket.on('alert:raise', async ({ alertType, details, location }) => {
    // Only admin can raise alerts and reason (details) is required
    if (socket.user?.role !== 'admin') {
      console.warn(`🚫 Non-admin tried to raise alert: ${userId}`);
      socket.emit('alert:error', 'Only admin can raise alerts');
      return;
    }
    if (!alertType || !details) {
      socket.emit('alert:error', 'alertType and reason are required');
      return;
    }

    const a = await Alert.create({ userId, userName, alertType, details, location });
    io.to('residents').emit('alert:new', a);
    
    // Send push notification to all residents
    console.log('🔔 Attempting to send alert notification...');
    sendNotificationToAll(
      {
        title: `🚨 ${alertType} Alert`,
        body: `${userName}: ${details}`,
      },
      {
        type: 'alert',
        alertId: a._id.toString(),
        alertType,
      },
      [userId]
    )
      .then((result) => console.log('✅ Alert notification result:', result))
      .catch((err) => console.error('❌ Failed to send alert notification:', err));
  });

  socket.on('disconnect', () => {});
});

const PORT = process.env.PORT || 4000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/connectapp';

connectDB(MONGO_URI)
  .then(() => {
    server.listen(PORT, () => console.log(`API running on :${PORT}`));
  })
  .catch((err) => {
    console.error('Failed to connect DB', err);
    process.exit(1);
  });

// Global Express error handler – prevents crashes from async route errors
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  const status = err.status || 500;
  res.status(status).json({ message: err.message || 'Internal Server Error' });
});

// Avoid process crashing on unhandled rejections
process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection:', reason);
});
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
});

// Close Mongo connection on graceful shutdown
process.on('SIGINT', async () => {
  try { await mongoose.connection.close(); } catch {}
  process.exit(0);
});
