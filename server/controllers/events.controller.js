import { Event } from '../models/Event.js';
import { sendNotificationToAll } from '../services/notification.service.js';

export async function listEvents(req, res) {
  const items = await Event.find({}).sort({ eventDate: 1 });
  res.json(items);
}

export async function createEvent(req, res) {
  const { title, description, eventDate, image } = req.body;
  const item = await Event.create({ 
    userId: req.user._id, 
    title, 
    description, 
    eventDate,
    imageUrl: image || null
  });
  
  // Send notification to all users except the event creator
  console.log('🔔 Attempting to send notification for new event...');
  sendNotificationToAll(
    {
      title: 'New Community Event',
      body: `${title} - ${new Date(eventDate).toLocaleDateString()}`,
    },
    {
      type: 'new_event',
      eventId: item._id.toString(),
    },
    [req.user._id]
  )
    .then((result) => console.log('✅ Event notification result:', result))
    .catch((err) => console.error('❌ Failed to send event notification:', err));
  
  res.status(201).json(item);
}

export async function updateEvent(req, res) {
  const item = await Event.findById(req.params.id);
  if (!item) return res.status(404).json({ message: 'Not found' });
  const isOwner = item.userId.toString() === req.user._id.toString();
  if (!isOwner && req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  const { title, description, eventDate, image } = req.body;
  if (title !== undefined) item.title = title;
  if (description !== undefined) item.description = description;
  if (eventDate !== undefined) item.eventDate = eventDate;
  if (image !== undefined) item.imageUrl = image;
  await item.save();
  res.json(item);
}

export async function deleteEvent(req, res) {
  const item = await Event.findById(req.params.id);
  if (!item) return res.status(404).json({ message: 'Not found' });
  // Allow any authenticated user to delete events
  await item.deleteOne();
  res.json({ success: true });
}
