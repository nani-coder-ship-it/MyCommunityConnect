import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { createAlert, listAlerts } from '../controllers/alerts.controller.js';

const router = express.Router();
router.get('/', authMiddleware, listAlerts);
router.post('/', authMiddleware, createAlert);

export default router;
