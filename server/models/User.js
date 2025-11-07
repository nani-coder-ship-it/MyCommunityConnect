import mongoose from 'mongoose';
import bcrypt from 'bcrypt';

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    passwordHash: { type: String, required: true },
    roomNo: { type: String },
    ownerName: { type: String },
    phoneNo: { type: String },
    role: { type: String, enum: ['resident', 'admin'], default: 'resident' },
    profilePicture: { type: String }, // Base64 image or URL
    fcmTokens: { type: [String], default: [] },
    lastSeen: { type: Date },
    resetCode: { type: String },
    resetCodeExpiry: { type: Date },
  },
  { timestamps: true }
);

UserSchema.methods.comparePassword = async function (password) {
  return bcrypt.compare(password, this.passwordHash);
};

UserSchema.statics.hashPassword = async function (password) {
  const saltRounds = 10;
  return bcrypt.hash(password, saltRounds);
};

export const User = mongoose.model('User', UserSchema);
