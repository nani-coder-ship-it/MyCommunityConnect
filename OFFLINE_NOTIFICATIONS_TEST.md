# Offline Push Notifications Test Guide

## ✅ What's Now Enabled

Your app now supports **TRUE push notifications** that work:
- ✅ When app is **closed/terminated**
- ✅ When user is **logged out**
- ✅ When phone is **locked**
- ✅ Notifications show in **system notification bar**
- ✅ Tap notification → **Opens app directly**

---

## 🧪 How to Test (One Device)

### Step 1: Register Two Users

```bash
flutter run
```

In the app:
1. Register User A: `usera@test.com` / `123456`
2. **Keep app open** after login (FCM token registers)
3. Logout
4. Register User B: `userb@test.com` / `123456`
5. **Keep app open** after login (FCM token registers)

**Backend logs should show:**
```
✅ FCM token registered for user: usera@test.com
✅ FCM token registered for user: userb@test.com
```

---

### Step 2: Test Offline Post Notification

**Scenario:** User B receives notification even when logged out/app closed

1. **Stay logged in as User B**
2. **Close the app completely** (swipe away from recent apps)
3. **On your PC/another device:**
   - Login as User A (or use Postman/curl)
   - Create a new post

4. **Check User B's phone:**
   - 🔔 Notification appears in notification bar
   - Title: "New Community Post"
   - Body: "User A: [message preview]"
   - **Tap notification** → App opens to posts!

**Backend logs:**
```
📤 Broadcast notification: 1 succeeded, 0 failed
```

**Mobile logs (when notification arrives):**
```
🔔 Background notification received: New Community Post
   Message: User A: Hello everyone!
```

---

### Step 3: Test Offline Chat Notification

**Scenario:** User A receives chat even when app is closed

1. **Login as User A** → Close app completely
2. **Login as User B**
3. Go to Chat → Send message to User A
4. **Check User A's phone:**
   - 🔔 Notification in notification bar
   - Title: "New message from User B"
   - Body: "[message preview]"
   - **Tap notification** → App opens to chat!

**Backend logs:**
```
[CHAT] Message saved: ...
📤 Sent notification to user [User A ID]: 1 succeeded, 0 failed
```

---

### Step 4: Test All States

Test notifications in 3 states for complete coverage:

#### State 1: Foreground (App Open)
- Keep app open on screen
- Another user creates post
- **Result:** Console shows `📩 Foreground notification`

#### State 2: Background (App Minimized)
- Press home button (app still in recent apps)
- Another user creates post
- **Result:** 🔔 System notification appears
- Tap it → App comes to foreground

#### State 3: Terminated (App Closed)
- Swipe app away from recent apps
- Another user creates post
- **Result:** 🔔 System notification appears
- Tap it → App launches fresh
- Console shows `📭 Notification tapped (terminated)`

---

## 🎯 Key Points

### Notifications Work When:
- ✅ User is logged out
- ✅ App is closed/terminated
- ✅ Phone is locked
- ✅ Device is in Do Not Disturb (depends on user settings)
- ✅ Multiple devices (same user gets notification on all devices)

### Notifications DON'T Require:
- ❌ App to be running
- ❌ User to be logged in
- ❌ Active internet connection at the exact moment (queued by FCM)

### How It Works:
1. User logs in once → FCM token saved to backend
2. Token stays in database even after logout
3. When event happens (post/chat) → Backend sends to FCM
4. FCM delivers to device notification bar
5. User taps → App opens to relevant screen

---

## 🐛 Troubleshooting

### "No notification received"

**Check Mobile:**
```
✅ Firebase initialized
✅ FCM permission granted
✅ FCM Token: ey...
✅ FCM token registered with backend
```

**Check Backend:**
```
📤 Sent notification to user... : 1 succeeded, 0 failed
```

If you see `0 succeeded, 1 failed`:
- Check Firebase service account is valid
- Check user has FCM token in database
- Check device has internet connection

### "Permission denied"
- Android: Settings → Apps → connectapp_mobile → Notifications → Enable
- Android 13+: App will request permission on first launch

### "Token not found"
- User must login at least once to register FCM token
- Check database: User model should have fcmTokens array

---

## 📊 Expected Logs

### Mobile App (Receiver)
```
✅ Firebase initialized
✅ FCM permission granted
📱 FCM Token: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
✅ FCM token registered with backend

// When notification arrives (app closed):
🔔 Background notification received: New Community Post
   Message: User A: Check out this announcement!
   Data: {type: new_post, postId: 673c1a2b3d4e5f6a7b8c9d0e}
```

### Backend (Sender)
```
✅ Firebase Admin initialized with service account
API running on :4000

// When User A creates post:
📤 Broadcast notification: 1 succeeded, 0 failed

// When User A sends chat to User B:
[CHAT] Message saved: ...
📤 Sent notification to user 673c1a2b3d4e5f6a7b8c9d0e: 1 succeeded, 0 failed
```

---

## ✅ Success Checklist

Before reporting issues, verify:
- [ ] Backend running with "Firebase Admin initialized"
- [ ] Mobile shows "FCM token registered with backend"
- [ ] User has logged in at least once (to register token)
- [ ] Backend logs show "Sent notification: 1 succeeded"
- [ ] Phone notifications are enabled for the app
- [ ] Device has internet connection
- [ ] Test on real device (not emulator)

---

## 🚀 Quick Test Command

Use this to test from command line (replace token with User B's token):

```bash
# Start backend
cd server && npm start

# In another terminal, test notification directly:
curl -X POST http://10.2.3.255:4000/api/posts \
  -H "Authorization: Bearer <user_a_token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "Test notification from command line!"}'
```

User B should receive notification immediately, even if app is closed!
