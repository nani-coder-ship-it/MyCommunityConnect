import admin from 'firebase-admin';
import fs from 'fs';

let firebaseInitialized = false;

/**
 * Initialize Firebase Admin SDK.
 * Requires either:
 * 1. FIREBASE_SERVICE_ACCOUNT_PATH env var pointing to your service account JSON, OR
 * 2. GOOGLE_APPLICATION_CREDENTIALS env var, OR
 * 3. Default credentials in cloud environment
 */
export function initializeFirebase() {
  if (firebaseInitialized) return;

  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    
    if (serviceAccountPath) {
      // Load service account from file
      const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin initialized with service account');
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      console.log('✅ Firebase Admin initialized with application default credentials');
    } else {
      console.warn('⚠️  Firebase Admin not initialized: no credentials provided.');
      console.warn('   Set FIREBASE_SERVICE_ACCOUNT_PATH or GOOGLE_APPLICATION_CREDENTIALS in .env');
      return;
    }
    
    firebaseInitialized = true;
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin:', error.message);
  }
}

/**
 * Send notification to a single user by their FCM token(s).
 */
export async function sendNotificationToUser(userId, notification, data = {}) {
  if (!firebaseInitialized) {
    console.warn('⚠️  Firebase not initialized; skipping notification');
    return { success: false, reason: 'Firebase not initialized' };
  }

  try {
    const { User } = await import('../models/User.js');
    const user = await User.findById(userId);
    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
      return { success: false, reason: 'No FCM tokens for user' };
    }

    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data,
      tokens: user.fcmTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`📤 Sent notification to user ${userId}: ${response.successCount} succeeded, ${response.failureCount} failed`);

    // Clean up invalid tokens
    const invalidTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success && (resp.error?.code === 'messaging/invalid-registration-token' || resp.error?.code === 'messaging/registration-token-not-registered')) {
        invalidTokens.push(user.fcmTokens[idx]);
      }
    });
    if (invalidTokens.length > 0) {
      user.fcmTokens = user.fcmTokens.filter(t => !invalidTokens.includes(t));
      await user.save();
      console.log(`🧹 Cleaned ${invalidTokens.length} invalid tokens for user ${userId}`);
    }

    return { success: true, successCount: response.successCount, failureCount: response.failureCount };
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Send notification to all users except the excluded user IDs.
 */
export async function sendNotificationToAll(notification, data = {}, excludeUserIds = []) {
  if (!firebaseInitialized) {
    console.warn('⚠️  Firebase not initialized; skipping notification');
    return { success: false, reason: 'Firebase not initialized' };
  }

  try {
    const { User } = await import('../models/User.js');
    const users = await User.find({
      _id: { $nin: excludeUserIds },
      fcmTokens: { $exists: true, $ne: [] },
    });

    if (users.length === 0) {
      console.log('⚠️  No users with FCM tokens found');
      return { success: true, message: 'No users with FCM tokens' };
    }

    const allTokens = users.flatMap(u => u.fcmTokens);
    if (allTokens.length === 0) {
      console.log('⚠️  No FCM tokens found');
      return { success: true, message: 'No FCM tokens found' };
    }

    console.log(`📤 Sending to ${allTokens.length} tokens from ${users.length} users`);

    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data,
      tokens: allTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`📤 Broadcast notification: ${response.successCount} succeeded, ${response.failureCount} failed`);

    return { success: true, successCount: response.successCount, failureCount: response.failureCount };
  } catch (error) {
    console.error('❌ Error broadcasting notification:', error);
    return { success: false, error: error.message };
  }
}

// Simple Socket events
export function initNotificationService(io) {
  return {
    emitToRoom: (room, event, payload) => io.to(room).emit(event, payload),
    emitToUser: (userId, event, payload) => io.to(`user:${userId}`).emit(event, payload),
  };
}
