import { validationResult } from 'express-validator';
import { Post } from '../models/Post.js';
import { User } from '../models/User.js';
import { sendNotificationToAll } from '../services/notification.service.js';

export async function listPosts(req, res) {
  const limit = Math.min(parseInt(req.query.limit) || 10, 50);
  const page = Math.max(parseInt(req.query.page) || 1, 1);
  const skip = (page - 1) * limit;
  const [items, total] = await Promise.all([
    Post.find({}).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Post.countDocuments({}),
  ]);
  
  // Populate user profile pictures
  const postsWithProfiles = await Promise.all(
    items.map(async (post) => {
      const user = await User.findById(post.userId).select('profilePicture');
      const hasUser = !!req.user;
      const userHasLiked = hasUser
        ? (post.likes || []).some((u) => u.toString() === req.user._id.toString())
        : false;
      return {
        ...post.toObject(),
        userProfilePicture: user?.profilePicture || null,
        userHasLiked,
      };
    })
  );
  
  res.json({ items: postsWithProfiles, total, page, limit });
}

export async function createPost(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  const { message, image, imageUrl, images } = req.body;
  
  // Support both single image (legacy) and multiple images
  const postImages = images && Array.isArray(images) && images.length > 0 
    ? images 
    : [];
  
  const post = await Post.create({
    userId: req.user._id,
    userName: req.user.name,
    message,
    imageUrl: image || imageUrl || null, // Legacy single image
    images: postImages, // New multiple images
  });
  
  // Send notification to all users except the post author
  console.log('🔔 Attempting to send notification for new post...');
  sendNotificationToAll(
    {
      title: 'New Community Post',
      body: `${req.user.name}: ${message.substring(0, 100)}${message.length > 100 ? '...' : ''}`,
    },
    {
      type: 'new_post',
      postId: post._id.toString(),
    },
    [req.user._id]
  )
    .then((result) => console.log('✅ Notification sent result:', result))
    .catch((err) => console.error('❌ Failed to send post notification:', err));
  
  res.status(201).json(post);
}

export async function updatePost(req, res) {
  const id = req.params.id;
  const post = await Post.findById(id);
  if (!post) return res.status(404).json({ message: 'Post not found' });
  const isOwner = post.userId.toString() === req.user._id.toString();
  if (!isOwner && req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  const { message, image, imageUrl } = req.body;
  if (message !== undefined) post.message = message;
  if (image !== undefined || imageUrl !== undefined) post.imageUrl = image || imageUrl;
  await post.save();
  res.json(post);
}

export async function deletePost(req, res) {
  const id = req.params.id;
  const post = await Post.findById(id);
  if (!post) return res.status(404).json({ message: 'Post not found' });
  const isOwner = post.userId.toString() === req.user._id.toString();
  if (!isOwner && req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  await post.deleteOne();
  res.json({ success: true });
}

export async function likePost(req, res) {
  const id = req.params.id;
  const post = await Post.findById(id);
  if (!post) return res.status(404).json({ message: 'Post not found' });
  const uid = req.user._id.toString();
  const already = (post.likes || []).some((u) => u.toString() === uid);
  if (!already) {
    post.likes.push(req.user._id);
    post.likesCount = (post.likesCount || 0) + 1;
    await post.save();
  }
  res.json({ likesCount: post.likesCount, userHasLiked: true });
}

export async function unlikePost(req, res) {
  const id = req.params.id;
  const post = await Post.findById(id);
  if (!post) return res.status(404).json({ message: 'Post not found' });
  const uid = req.user._id.toString();
  const before = post.likes.length;
  post.likes = (post.likes || []).filter((u) => u.toString() !== uid);
  if (post.likes.length !== before) {
    post.likesCount = Math.max(0, (post.likesCount || 0) - 1);
    await post.save();
  }
  res.json({ likesCount: post.likesCount, userHasLiked: false });
}
