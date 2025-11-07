import { Alert } from '../models/Alert.js';

export async function createAlert(req, res) {
  const { alertType, details, location } = req.body;
  const alert = await Alert.create({
    userId: req.user._id,
    userName: req.user.name,
    alertType,
    details,
    location,
  });
  // Broadcast via Socket.IO
  const io = req.app.get('io');
  io.to('residents').emit('alert:new', alert);
  res.status(201).json(alert);
}

export async function listAlerts(req, res) {
  const query = req.user.role === 'admin' ? {} : { userId: req.user._id };
  const alerts = await Alert.find(query).sort({ createdAt: -1 });
  res.json(alerts);
}
