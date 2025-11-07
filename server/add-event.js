import mongoose from 'mongoose';
import { User } from './models/User.js';
import { Event } from './models/Event.js';

async function addEvent() {
  try {
    await mongoose.connect('mongodb://localhost:27017/community-connect');
    console.log('Connected to MongoDB');

    // Find a user
    const user = await User.findOne({ email: 'test@test.com' });
    if (!user) {
      console.log('❌ No user found. Run seed.js first');
      process.exit(1);
    }

    // Create test event
    const eventDate = new Date();
    eventDate.setDate(eventDate.getDate() + 7);
    
    await Event.create({
      userId: user._id,
      title: 'Community Meeting',
      description: 'Monthly community meeting to discuss upcoming activities',
      eventDate: eventDate,
    });

    console.log('✅ Created test event');

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

addEvent();
