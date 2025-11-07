import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { optionalAuth } from '../middleware/optionalAuth.middleware.js';
import { createPost, deletePost, listPosts, updatePost, likePost, unlikePost } from '../controllers/posts.controller.js';
import { postCreateValidator } from '../utils/validators.js';

const router = express.Router();
router.get('/', optionalAuth, listPosts);
router.post('/', authMiddleware, postCreateValidator, createPost);
router.put('/:id', authMiddleware, updatePost);
router.delete('/:id', authMiddleware, deletePost);
router.post('/:id/like', authMiddleware, likePost);
router.delete('/:id/like', authMiddleware, unlikePost);

export default router;
