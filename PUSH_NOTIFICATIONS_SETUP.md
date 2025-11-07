# Push Notifications Setup Guide

## Backend Setup (Firebase Admin SDK)

### 1. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click the gear icon ⚙️ next to "Project Overview" → Project Settings
4. Navigate to "Service accounts" tab
5. Click "Generate new private key"
6. Save the downloaded JSON file securely (e.g., `firebase-service-account.json`)

### 2. Configure Backend Environment

Add to your `.env` file:

```bash
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/firebase-service-account.json
```

**Alternative:** Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable instead.

⚠️ **Security:** Never commit service account JSON to git. Add `firebase-service-account.json` to `.gitignore`.

### 3. Backend Endpoints Available

- `PUT /api/users/fcm-token` - Register FCM token (called automatically on mobile login)
- Notifications are sent automatically on:
  - New post creation → all users except author
  - New chat message → recipient user(s)

---

## Mobile Setup (Flutter)

### 1. Android Setup

#### a. Add google-services.json

1. In Firebase Console → Project Settings → Your apps
2. Add an Android app (or select existing)
3. Register your app with package name: `com.example.connectapp_mobile` (or your actual package)
4. Download `google-services.json`
5. Place it at: `mobile/android/app/google-services.json`

#### b. Update build.gradle files

**Project-level** (`mobile/android/build.gradle`):

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**App-level** (`mobile/android/app/build.gradle`):

```gradle
// At the top, after other plugins
apply plugin: 'com.google.gms.google-services'

android {
    // Ensure minSdkVersion is at least 21
    defaultConfig {
        minSdkVersion 21
    }
}
```

#### c. Update AndroidManifest.xml

Add inside `<application>` tag (`mobile/android/app/src/main/AndroidManifest.xml`):

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="default_channel" />
```

### 2. iOS Setup (Optional)

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `mobile/ios/Runner/` directory in Xcode
3. Update `ios/Runner/Info.plist` with required permissions

---

## Testing

### 1. Run the backend

```bash
cd server
npm start
```

Check console for:
- `✅ Firebase Admin initialized with service account` (success)
- `⚠️ Firebase Admin not initialized` (config issue)

### 2. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run
```

After login, check for:
- `✅ FCM permission granted`
- `📱 FCM Token: ...`
- `✅ FCM token registered with backend`

### 3. Test notifications

**Foreground (app open):**
1. User A creates a post
2. User B should see console: `📩 Foreground notification: New Community Post`

**Background (app minimized):**
1. Close app (don't terminate)
2. User A creates a post
3. User B should receive notification in system tray

**Terminated (app closed):**
1. Force-stop app
2. User A creates a post
3. User B receives notification
4. Tap notification → app opens

---

## Troubleshooting

### No notifications received

1. **Check FCM token registration:**
   - Mobile logs: `✅ FCM token registered with backend`
   - Backend logs: `✅ FCM token registered for user: user@example.com`

2. **Verify Firebase Admin initialization:**
   - Backend logs: `✅ Firebase Admin initialized`
   - If not, check `FIREBASE_SERVICE_ACCOUNT_PATH` in `.env`

3. **Check notification sending:**
   - Backend logs: `📤 Sent notification to user ...` or `📤 Broadcast notification`
   - If you see errors, verify service account has FCM permissions

4. **Android device issues:**
   - Ensure `google-services.json` is in correct location
   - Rebuild app after adding Firebase config
   - Check Firebase Console → Cloud Messaging for any errors

### Permission denied

- iOS: Re-request permission via Settings → Your App → Notifications
- Android: Check notification settings for your app

### Token refresh not working

- Restart the app; FCM token should auto-register on login
- Check mobile logs for `🔄 FCM Token refreshed`

---

## Production Checklist

- [ ] Service account JSON not in git (use `.gitignore`)
- [ ] Production Firebase project created
- [ ] `google-services.json` points to production project
- [ ] FCM API enabled in Firebase Console
- [ ] Test on multiple devices (Android/iOS)
- [ ] Test all notification types (posts, chat, alerts)
- [ ] Monitor Firebase Console for delivery stats
