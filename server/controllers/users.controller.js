import { User } from '../models/User.js';
import { sendNotificationToUser } from '../services/notification.service.js';

export async function listUsers(req, res) {
  const users = await User.find({}, '-passwordHash').sort({ createdAt: -1 });
  res.json(users);
}

export async function updateRole(req, res) {
  const { id } = req.params;
  const { role } = req.body;
  if (!['resident', 'admin'].includes(role)) return res.status(400).json({ message: 'Invalid role' });
  const user = await User.findByIdAndUpdate(id, { role }, { new: true }).select('-passwordHash');
  if (!user) return res.status(404).json({ message: 'User not found' });
  res.json(user);
}

export async function updateProfilePicture(req, res) {
  try {
    const { profilePicture } = req.body;
    
    if (!profilePicture) {
      return res.status(400).json({ message: 'Profile picture is required' });
    }

    // Validate base64 image format
    if (!profilePicture.startsWith('data:image/')) {
      return res.status(400).json({ message: 'Invalid image format. Must be base64 encoded image' });
    }

    // Update user's profile picture
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { profilePicture },
      { new: true }
    ).select('-passwordHash');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    console.log('✅ Profile picture updated for:', user.email);
    res.json({ message: 'Profile picture updated successfully', user });
  } catch (error) {
    console.error('❌ Profile picture update error:', error);
    res.status(500).json({ message: 'Failed to update profile picture' });
  }
}

export async function updateFcmToken(req, res) {
  try {
    const { token } = req.body;
    
    if (!token || typeof token !== 'string') {
      return res.status(400).json({ message: 'Valid FCM token is required' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Add token if not already present (supports multiple devices)
    if (!user.fcmTokens.includes(token)) {
      user.fcmTokens.push(token);
      await user.save();
      console.log(`✅ FCM token registered for user: ${user.email}`);
    }

    res.json({ message: 'FCM token registered successfully' });
  } catch (error) {
    console.error('❌ FCM token update error:', error);
    res.status(500).json({ message: 'Failed to update FCM token' });
  }
}

export async function sendTestNotification(req, res) {
  try {
    const result = await sendNotificationToUser(
      req.user._id,
      { title: 'Test Notification', body: 'This is a test push from the server' },
      { type: 'test' }
    );
    return res.json({ ok: true, result });
  } catch (e) {
    return res.status(500).json({ ok: false, error: e?.message || String(e) });
  }
}


