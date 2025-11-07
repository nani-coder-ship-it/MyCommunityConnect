import { MaintenanceRequest } from '../models/MaintenanceRequest.js';

export async function listMyMaintenance(req, res) {
  const items = await MaintenanceRequest.find({ userId: req.user._id }).sort({ createdAt: -1 });
  res.json({ items });
}

export async function createMaintenance(req, res) {
  const { issueType, description, priority } = req.body;
  const item = await MaintenanceRequest.create({ 
    userId: req.user._id, 
    issueType: issueType || 'General', 
    description, 
    priority: priority || 'medium' 
  });
  res.status(201).json(item);
}

export async function updateMaintenanceStatus(req, res) {
  const { id } = req.params;
  const { status } = req.body;
  const item = await MaintenanceRequest.findById(id);
  if (!item) return res.status(404).json({ message: 'Not found' });
  const isOwner = item.userId.toString() === req.user._id.toString();
  if (!isOwner && req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  item.status = status;
  await item.save();
  res.json(item);
}

export async function deleteMaintenance(req, res) {
  const item = await MaintenanceRequest.findById(req.params.id);
  if (!item) return res.status(404).json({ message: 'Not found' });
  // Allow any authenticated user to delete
  await item.deleteOne();
  res.json({ success: true });
}
