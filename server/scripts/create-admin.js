import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { User } from '../models/User.js';

dotenv.config();

async function createAdmin() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/connectapp');
    console.log('✅ Connected to MongoDB');

    // Check for existing admin
    const existingAdmin = await User.findOne({ role: 'admin' });
    
    if (existingAdmin) {
      console.log('\n📋 Existing Admin Account Found:');
      console.log('Email:', existingAdmin.email);
      console.log('Name:', existingAdmin.name);
      console.log('Role:', existingAdmin.role);
      console.log('\nTo reset password, delete this user first or use password reset feature.');
      
      // List all users
      const allUsers = await User.find({}, 'email name role');
      console.log('\n📋 All Users:');
      allUsers.forEach((user, i) => {
        console.log(`${i + 1}. ${user.email} - ${user.name} - ${user.role}`);
      });
      
      mongoose.disconnect();
      return;
    }

    // Create new admin account
    console.log('\n🔨 Creating new admin account...');
    
    const adminData = {
      name: 'Admin User',
      email: 'admin@connectapp.com',
      password: 'admin123',
      roomNo: 'ADMIN',
      ownerName: 'Admin',
      phoneNo: '9999999999',
      role: 'admin'
    };

    const passwordHash = await User.hashPassword(adminData.password);
    
    const admin = await User.create({
      name: adminData.name,
      email: adminData.email,
      passwordHash,
      roomNo: adminData.roomNo,
      ownerName: adminData.ownerName,
      phoneNo: adminData.phoneNo,
      role: adminData.role,
    });

    console.log('\n✅ Admin account created successfully!');
    console.log('\n📝 Login Credentials:');
    console.log('Email:', adminData.email);
    console.log('Password:', adminData.password);
    console.log('\n⚠️  Please change the password after first login!');

    mongoose.disconnect();
  } catch (error) {
    console.error('❌ Error:', error.message);
    mongoose.disconnect();
    process.exit(1);
  }
}

createAdmin();
