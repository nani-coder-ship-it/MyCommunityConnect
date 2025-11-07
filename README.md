# ConnectApp (Apartment Community App)

Full-stack apartment community management app with real-time chat and emergency alerts.

## Structure
- `server/`: Node.js + Express + MongoDB backend with Socket.IO
- `mobile/`: Flutter mobile app (Android/iOS)

## Quick Start

### Backend
```bash
cd server
cp .env.example .env
# Edit .env with your MongoDB URI
npm install
npm run dev
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

## Features
- Auth: JWT-based login/register
- Posts: Community announcements feed
- Chat: Real-time Socket.IO community chat
- Emergency: One-tap emergency alert broadcast
- Visitors: Visitor management with approval flow (TBD)
- Maintenance: Request tracking (TBD)
- Contacts: Directory of community contacts (TBD)
- Admin: User management dashboard (TBD)

## Deployment
- **Backend**: Deploy to Render/Railway with MongoDB Atlas
- **Mobile**: Build APK with `flutter build apk`

See individual README files for detailed setup and deployment instructions.
