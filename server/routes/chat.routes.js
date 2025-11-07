import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { getHistory, listRooms, deleteMessage } from '../controllers/chat.controller.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import fs from 'fs';
import path from 'path';
import multer from 'multer';

const router = express.Router();
router.get('/rooms', authMiddleware, asyncHandler(listRooms));
router.get('/history/:roomId?', authMiddleware, asyncHandler(getHistory));
router.delete('/message/:id', authMiddleware, asyncHandler(deleteMessage));

// Ensure upload directory exists
const uploadDir = path.resolve('uploads', 'chat');
try { fs.mkdirSync(uploadDir, { recursive: true }); } catch {}

const storage = multer.diskStorage({
	destination: function (_req, _file, cb) {
		cb(null, uploadDir);
	},
	filename: function (_req, file, cb) {
		const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
		cb(null, `${Date.now()}_${safeName}`);
	},
});
const fileFilter = function (_req, file, cb) {
	if (/^image\//.test(file.mimetype)) cb(null, true);
	else cb(new Error('Only image uploads are allowed'));
};
const upload = multer({ storage, fileFilter, limits: { fileSize: 5 * 1024 * 1024 } }); // 5MB

// Upload chat image
router.post('/upload', authMiddleware, upload.single('image'), asyncHandler(async (req, res) => {
	if (!req.file) return res.status(400).json({ message: 'No file uploaded' });
	const relativePath = `/uploads/chat/${req.file.filename}`;
	// Return both relative and absolute for convenience
	const base = `${req.protocol}://${req.get('host')}`;
	res.json({ url: `${base}${relativePath}`, path: relativePath });
}));

export default router;
