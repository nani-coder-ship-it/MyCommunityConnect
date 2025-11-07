import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { adminMiddleware } from '../middleware/admin.middleware.js';
import { createContact, deleteContact, listContacts, updateContact } from '../controllers/contacts.controller.js';

const router = express.Router();
router.get('/', listContacts);
router.post('/', authMiddleware, adminMiddleware, createContact);
router.put('/:id', authMiddleware, adminMiddleware, updateContact);
router.delete('/:id', authMiddleware, adminMiddleware, deleteContact);

export default router;
