import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { createEvent, deleteEvent, listEvents, updateEvent } from '../controllers/events.controller.js';

const router = express.Router();
router.get('/', listEvents);
router.post('/', authMiddleware, createEvent);
router.put('/:id', authMiddleware, updateEvent);
router.delete('/:id', authMiddleware, deleteEvent);

export default router;
