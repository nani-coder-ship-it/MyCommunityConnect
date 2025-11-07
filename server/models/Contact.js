import mongoose from 'mongoose';

const ContactSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    role: { type: String },
    phone: { type: String, required: true },
    category: { type: String },
    description: { type: String },
    available24x7: { type: Boolean, default: false },
    notes: { type: String },
  },
  { timestamps: true }
);

export const Contact = mongoose.model('Contact', ContactSchema);
