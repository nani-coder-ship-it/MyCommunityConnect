# ConnectApp Server

Node.js + Express + MongoDB backend with Socket.IO for chat and emergency alerts.

## Features
- Auth: register, login, JWT middleware
- Users: admin list/update role
- Contacts, Posts, Events, Visitors, Maintenance
- Alerts: REST + Socket.IO broadcast
- Chat: Socket.IO rooms with stored history

## Setup
1. Copy `.env.example` to `.env` and edit values
2. Install dependencies

```bash
cd server
npm install
```

3. Run dev server

```bash
npm run dev
```

Server runs on http://localhost:4000 by default.

## API Quickstart
- POST /api/auth/register
- POST /api/auth/login
- GET  /api/auth/me  (Bearer token)

## Deployment
- Set env vars: `PORT`, `MONGO_URI`, `JWT_SECRET`, `CORS_ORIGIN`
- Deploy on Render/Railway/Heroku using `npm start`

## TODO
- File uploads (multer + cloud storage)
- FCM push notifications
- Rate limit auth endpoints
- Add pagination and filters across lists
