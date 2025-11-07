import { Contact } from '../models/Contact.js';

export async function listContacts(req, res) {
  const items = await Contact.find({}).sort({ createdAt: -1 });
  res.json(items);
}

export async function createContact(req, res) {
  const item = await Contact.create(req.body);
  res.status(201).json(item);
}

export async function updateContact(req, res) {
  const item = await Contact.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!item) return res.status(404).json({ message: 'Not found' });
  res.json(item);
}

export async function deleteContact(req, res) {
  const item = await Contact.findByIdAndDelete(req.params.id);
  if (!item) return res.status(404).json({ message: 'Not found' });
  res.json({ success: true });
}
