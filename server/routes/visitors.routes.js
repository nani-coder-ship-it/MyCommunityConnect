import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { createVisitor, listMyVisitors, updateVisitorStatus, deleteVisitor } from '../controllers/visitors.controller.js';

const router = express.Router();
router.get('/me', authMiddleware, listMyVisitors);
router.post('/', authMiddleware, createVisitor);
router.put('/:id/status', authMiddleware, updateVisitorStatus);
router.delete('/:id', authMiddleware, deleteVisitor);

export default router;
