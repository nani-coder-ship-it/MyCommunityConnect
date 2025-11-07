import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { adminMiddleware } from '../middleware/admin.middleware.js';
import { listUsers, updateRole, updateProfilePicture, updateFcmToken, sendTestNotification } from '../controllers/users.controller.js';

const router = express.Router();
router.get('/', authMiddleware, adminMiddleware, listUsers);
router.put('/:id/role', authMiddleware, adminMiddleware, updateRole);
router.put('/profile-picture', authMiddleware, updateProfilePicture);
router.put('/fcm-token', authMiddleware, updateFcmToken);
router.post('/fcm-test', authMiddleware, sendTestNotification);

export default router;
