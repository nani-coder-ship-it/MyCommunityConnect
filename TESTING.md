# MyCommunityConnect - Testing Guide

## 🎯 What Was Fixed

### 1. **Chat Sender Name Issue** ✅
- **Problem**: Chat messages were showing MongoDB ObjectId instead of actual user names
- **Fix**: Updated `server/server.js` to fetch user name from database before creating chat messages
- **Location**: Lines 59-84 in server.js

### 2. **Socket Connection Flow** ✅
- **Problem**: Socket not connecting after login
- **Fix**: Added socket connection logic in login flow and disconnect on logout
- **Files Updated**:
  - `mobile/lib/src/screens/login_screen.dart`
  - `mobile/lib/src/screens/profile_screen.dart`
  - `mobile/lib/src/services/socket_service.dart`

### 3. **Test Data Added** ✅
- Created seed script with:
  - Test user: `test@test.com` / `password123`
  - 2 sample posts
  - 3 emergency contacts (Security, Plumber, Ambulance)
  - 1 upcoming event

## 📱 How to Test

### Step 1: Verify Backend is Running
```bash
# In server directory
node server.js
```
You should see: `API running on :4000`

### Step 2: Test with Existing User
**Login Credentials:**
- Email: `test@test.com`
- Password: `password123`
- Room: A101
- Owner: Owner One
- Phone: 1234567890

### Step 3: Test Features

#### ✅ **Posts Screen**
1. Navigate to Posts tab
2. You should see 2 test posts
3. Click the + button to create a new post
4. Enter message and click Create
5. New post should appear at the top

#### ✅ **Chat Screen**
1. Navigate to Chat tab
2. Type a message and send
3. You should see your name (not an ID) next to the message
4. Open the app on another device/emulator and login with different user
5. Send messages from both - they should appear in real-time

#### ✅ **Contacts Screen**
1. Navigate to Contacts tab
2. You should see 3 contacts:
   - Main Gate Security (555-0101)
   - Plumber Service (555-0102)
   - Ambulance (108)
3. Click on any contact to call

#### ✅ **Profile Screen**
1. Navigate to Profile tab
2. Verify all fields show correctly:
   - Name: Test User
   - Email: test@test.com
   - Flat/Room: A101
   - Owner Name: Owner One
   - Phone: 1234567890
3. Click Edit to update details
4. Click Logout to test logout flow

#### ⏳ **Events (Coming Soon)**
- Backend API ready at `/api/events`
- 1 test event already in database
- Frontend needs Events screen implementation

#### ⏳ **Visitors (Coming Soon)**
- Backend API ready at `/api/visitors`
- Frontend needs Visitors screen implementation

#### ⏳ **Maintenance (Coming Soon)**
- Backend API ready at `/api/maintenance`
- Frontend needs Maintenance screen implementation

## 🐛 Known Issues & Troubleshooting

### Issue: "Connection timeout"
**Solution**: Make sure you're using the correct IP address (10.2.1.19) in `api_service.dart` and `socket_service.dart`

### Issue: "Profile shows N/A"
**Possible Causes**:
1. User registered without filling all fields
2. Backend not returning data correctly

**Solution**:
1. Login with the test user: `test@test.com` / `password123`
2. If still showing N/A, check network inspector in VS Code
3. Check if `/api/auth/me` returns all user fields

### Issue: "Posts not loading"
**Solution**:
1. Verify backend is running on port 4000
2. Check if seed data was added: `node seed.js`
3. Check network tab for API errors

### Issue: "Chat messages not appearing"
**Solution**:
1. Restart the backend server to apply the socket fix
2. Make sure socket connects after login (check console logs)
3. Try logging out and back in

## 🔧 Development Commands

### Backend
```bash
cd server

# Start server
node server.js

# Add test data
node seed.js

# Add more events
node add-event.js
```

### Frontend
```bash
cd mobile

# Run on device
flutter run

# Hot reload
Press 'r' in terminal

# Hot restart
Press 'R' in terminal

# Clean build
flutter clean && flutter pub get && flutter run
```

## 📝 Next Steps

### 1. Implement Events Screen
- Create `events_screen.dart`
- Show list of upcoming events
- Add create event dialog (admin only)
- Connect to `/api/events` endpoint

### 2. Implement Visitors Screen
- Create `visitors_screen.dart`
- Add visitor registration form
- Show visitor history
- Connect to `/api/visitors` endpoint

### 3. Implement Maintenance Screen
- Create `maintenance_screen.dart`
- Add maintenance request form
- Show request status
- Connect to `/api/maintenance` endpoint

### 4. Add Admin Features
- Admin dashboard
- User management
- Approve/reject maintenance requests
- Manage events

### 5. Polish & Features
- Add image upload for posts
- Add push notifications
- Add profile picture upload
- Add search functionality
- Add filters and sorting

## 🎨 UI Improvements Suggestions

1. **Home Screen**: Add quick action cards for common tasks
2. **Chat**: Add message timestamps, read receipts
3. **Posts**: Add like/comment functionality
4. **Profile**: Add profile picture, edit inline
5. **Dark Mode**: Implement dark theme support

## 📊 API Endpoints Reference

### Auth
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user

### Posts
- `GET /api/posts` - List all posts
- `POST /api/posts` - Create post
- `PUT /api/posts/:id` - Update post
- `DELETE /api/posts/:id` - Delete post

### Chat
- `GET /api/chat/history/:roomId` - Get chat history
- Socket.IO events: `chat:message`, `chat:new_message`

### Contacts
- `GET /api/contacts` - List all contacts
- `POST /api/contacts` - Create contact (admin)

### Events
- `GET /api/events` - List events
- `POST /api/events` - Create event
- `PUT /api/events/:id` - Update event
- `DELETE /api/events/:id` - Delete event

### Visitors
- `GET /api/visitors` - List visitors
- `POST /api/visitors` - Register visitor
- `PUT /api/visitors/:id` - Update visitor

### Maintenance
- `GET /api/maintenance` - List requests
- `POST /api/maintenance` - Create request
- `PUT /api/maintenance/:id` - Update request status

### Emergency Alerts
- `GET /api/alerts` - List alerts
- `POST /api/alerts` - Raise alert
- Socket.IO events: `alert:raise`, `alert:new`

## ✅ Testing Checklist

- [ ] Backend server starts without errors
- [ ] Can register new user with all 6 fields
- [ ] Can login with existing user
- [ ] Posts screen loads test posts
- [ ] Can create new post
- [ ] Chat shows user names correctly
- [ ] Chat messages appear in real-time
- [ ] Contacts screen shows 3 test contacts
- [ ] Profile shows all user information (not N/A)
- [ ] Can edit profile
- [ ] Logout works and disconnects socket
- [ ] Emergency alert button exists on home screen

## 📞 Support

If you encounter any issues:
1. Check this testing guide first
2. Review the error messages in terminal/console
3. Check backend logs in `server` terminal
4. Check Flutter logs in `mobile` terminal
5. Restart both backend and frontend if needed
