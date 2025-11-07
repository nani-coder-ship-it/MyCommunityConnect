import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { Contact } from './models/Contact.js';

dotenv.config();

const emergencyContacts = [
  {
    name: 'Ambulance',
    phone: '108',
    category: 'Emergency',
    description: 'Medical emergency ambulance service',
    available24x7: true,
  },
  {
    name: 'Police',
    phone: '100',
    category: 'Emergency',
    description: 'Police emergency helpline',
    available24x7: true,
  },
  {
    name: 'Fire Service',
    phone: '101',
    category: 'Emergency',
    description: 'Fire and rescue emergency service',
    available24x7: true,
  },
  {
    name: 'Security Guard',
    phone: '+91-9876543210',
    category: 'Community',
    description: 'Community security office',
    available24x7: true,
  },
  {
    name: 'Society Manager',
    phone: '+91-9876543211',
    category: 'Community',
    description: 'Society management office',
    available24x7: false,
  },
  {
    name: 'Maintenance Help',
    phone: '+91-9876543212',
    category: 'Maintenance',
    description: 'For urgent maintenance issues',
    available24x7: false,
  },
];

async function seedContacts() {
  try {
    const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/connectapp';
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB');

    // Clear existing contacts
    await Contact.deleteMany({});
    console.log('Cleared existing contacts');

    // Insert emergency contacts
    await Contact.insertMany(emergencyContacts);
    console.log('✅ Emergency contacts seeded successfully!');

    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error('Error seeding contacts:', error);
    process.exit(1);
  }
}

seedContacts();
