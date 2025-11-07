import { Message } from '../models/Message.js';
import { User } from '../models/User.js';

export async function listRooms(req, res) {
  // Minimal static room list; could be extended by community id
  res.json([{ id: 'community', name: 'Community' }]);
}

export async function getHistory(req, res) {
  const roomId = req.params.roomId || 'community';
  console.log('[CHAT] Getting history for room:', roomId);
  const messages = await Message.find({ roomId }).sort({ createdAt: -1 }).limit(50);
  console.log('[CHAT] Found messages:', messages.length);
  
  // Populate sender profile pictures
  const messagesWithProfiles = await Promise.all(
    messages.map(async (msg) => {
      const user = await User.findById(msg.senderId || msg.userId).select('profilePicture');
      return {
        ...msg.toObject(),
        senderId: (msg.senderId || msg.userId)?.toString(), // Convert ObjectId to string
        senderProfilePicture: user?.profilePicture || null,
        readBy: (msg.readBy || []).map(r => r.toString()),
      };
    })
  );
  
  res.json(messagesWithProfiles.reverse());
}

export async function deleteMessage(req, res) {
  const msg = await Message.findById(req.params.id);
  if (!msg) return res.status(404).json({ message: 'Not found' });
  
  // Allow deletion: owner of message OR admin role
  const ownerId = msg.senderId || msg.userId;
  const currentUserId = req.user._id || req.user.id;
  const isOwner = ownerId && (ownerId.toString() === currentUserId.toString());
  const isAdmin = req.user.role === 'admin';
  
  if (!isOwner && !isAdmin) {
    return res.status(403).json({ 
      message: 'You can only delete your own messages',
      debug: {
        yourId: currentUserId.toString(),
        messageOwnerId: ownerId?.toString()
      }
    });
  }
  
  await msg.deleteOne();
  res.json({ success: true });
}
