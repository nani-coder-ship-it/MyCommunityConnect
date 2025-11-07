import { Visitor } from '../models/Visitor.js';

export async function listMyVisitors(req, res) {
  const visitors = await Visitor.find({ residentId: req.user._id }).sort({ createdAt: -1 });
  res.json(visitors);
}

export async function createVisitor(req, res) {
  const { visitorName, contact, visitStart } = req.body;
  const v = await Visitor.create({ residentId: req.user._id, visitorName, contact, visitStart });
  res.status(201).json(v);
}

export async function updateVisitorStatus(req, res) {
  const { id } = req.params;
  const { status } = req.body;
  const v = await Visitor.findById(id);
  if (!v) return res.status(404).json({ message: 'Not found' });
  const isOwner = v.residentId.toString() === req.user._id.toString();
  if (!isOwner && req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  v.status = status;
  if (status === 'Exited' && !v.visitEnd) v.visitEnd = new Date();
  await v.save();
  res.json(v);
}

export async function deleteVisitor(req, res) {
  const { id } = req.params;
  const v = await Visitor.findById(id);
  if (!v) return res.status(404).json({ message: 'Not found' });
  const isOwner = v.residentId.toString() === req.user._id.toString();
  if (!isOwner && req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  await Visitor.findByIdAndDelete(id);
  res.json({ message: 'Visitor deleted' });
}
