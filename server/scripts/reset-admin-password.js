import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { User } from '../models/User.js';
import readline from 'readline';

dotenv.config();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function resetAdminPassword() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/connectapp');
    console.log('✅ Connected to MongoDB\n');

    // List all admin users
    const admins = await User.find({ role: 'admin' }, 'email name');
    
    if (admins.length === 0) {
      console.log('❌ No admin accounts found!');
      mongoose.disconnect();
      rl.close();
      return;
    }

    console.log('📋 Admin Accounts:');
    admins.forEach((admin, i) => {
      console.log(`${i + 1}. ${admin.email} - ${admin.name}`);
    });

    console.log('\n');
    const choice = await question('Enter number to reset password (or 0 to exit): ');
    const index = parseInt(choice) - 1;

    if (index < 0 || index >= admins.length) {
      console.log('Exiting...');
      mongoose.disconnect();
      rl.close();
      return;
    }

    const selectedAdmin = admins[index];
    console.log(`\n✏️  Resetting password for: ${selectedAdmin.email}`);
    
    const newPassword = await question('Enter new password (min 6 characters): ');
    
    if (newPassword.length < 6) {
      console.log('❌ Password must be at least 6 characters!');
      mongoose.disconnect();
      rl.close();
      return;
    }

    const passwordHash = await User.hashPassword(newPassword);
    await User.findByIdAndUpdate(selectedAdmin._id, { passwordHash });

    console.log('\n✅ Password reset successfully!');
    console.log('\n📝 New Login Credentials:');
    console.log('Email:', selectedAdmin.email);
    console.log('Password:', newPassword);
    console.log('\n⚠️  Please keep these credentials secure!');

    mongoose.disconnect();
    rl.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
    mongoose.disconnect();
    rl.close();
    process.exit(1);
  }
}

resetAdminPassword();
