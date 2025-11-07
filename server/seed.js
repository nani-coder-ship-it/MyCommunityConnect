import mongoose from 'mongoose';
import { User } from './models/User.js';
import { Post } from './models/Post.js';
import { Contact } from './models/Contact.js';
import { Event } from './models/Event.js';

async function seed() {
  try {
    await mongoose.connect('mongodb://localhost:27017/community-connect');
    console.log('Connected to MongoDB');

    // Create test users (only if they don't exist)
    const testUser = await User.findOne({ email: 'test@test.com' });
    if (!testUser) {
      const passwordHash = await User.hashPassword('password123');
      const user1 = await User.create({
        name: 'Test User',
        email: 'test@test.com',
        passwordHash,
        roomNo: 'A101',
        ownerName: 'Owner One',
        phoneNo: '1234567890',
        role: 'resident',
      });
      console.log('✅ Created test user:', user1.email);

      // Create some test posts
      await Post.create({
        userId: user1._id,
        userName: user1.name,
        message: 'Welcome to our community! This is a test post.',
      });

      await Post.create({
        userId: user1._id,
        userName: user1.name,
        message: 'Looking forward to meeting everyone in the community!',
      });

      console.log('✅ Created test posts');

      // Create test contacts
      await Contact.create({
        category: 'Security',
        name: 'Main Gate Security',
        phoneNo: '555-0101',
        details: 'Available 24/7',
      });

      await Contact.create({
        category: 'Maintenance',
        name: 'Plumber Service',
        phoneNo: '555-0102',
        details: 'Available Mon-Sat 9AM-6PM',
      });

      await Contact.create({
        category: 'Emergency',
        name: 'Ambulance',
        phoneNo: '108',
        details: 'Emergency medical services',
      });

      console.log('✅ Created emergency contacts');

      // Create test event
      const eventDate = new Date();
      eventDate.setDate(eventDate.getDate() + 7);
      
      await Event.create({
        userId: user1._id,
        title: 'Community Meeting',
        description: 'Monthly community meeting to discuss upcoming activities',
        eventDate: eventDate,
      });

      console.log('✅ Created test event');
    } else {
      console.log('ℹ️ Test data already exists');
    }

    console.log('\n📊 Current database stats:');
    console.log(`Users: ${await User.countDocuments()}`);
    console.log(`Posts: ${await Post.countDocuments()}`);
    console.log(`Contacts: ${await Contact.countDocuments()}`);
    console.log(`Events: ${await Event.countDocuments()}`);

    await mongoose.connection.close();
    console.log('\n✅ Seeding complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
}

seed();
