import express from 'express';
import { register, login, me, requestPasswordReset, resetPassword } from '../controllers/auth.controller.v2.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { loginValidator, registerValidator } from '../utils/validators.js';

const router = express.Router();
router.post('/register', registerValidator, register);
router.post('/login', loginValidator, login);
router.get('/me', authMiddleware, me);
router.post('/forgot-password', requestPasswordReset);
router.post('/reset-password', resetPassword);

export default router;
