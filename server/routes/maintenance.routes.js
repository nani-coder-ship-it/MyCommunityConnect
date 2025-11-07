import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { createMaintenance, listMyMaintenance, updateMaintenanceStatus, deleteMaintenance } from '../controllers/maintenance.controller.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = express.Router();
router.get('/', authMiddleware, asyncHandler(listMyMaintenance));
router.get('/me', authMiddleware, asyncHandler(listMyMaintenance));
router.post('/', authMiddleware, asyncHandler(createMaintenance));
router.put('/:id/status', authMiddleware, asyncHandler(updateMaintenanceStatus));
router.delete('/:id', authMiddleware, asyncHandler(deleteMaintenance));

export default router;
