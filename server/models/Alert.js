import mongoose from 'mongoose';

const AlertSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    userName: { type: String },
    alertType: { type: String, required: true },
    details: { type: String },
    location: { type: String },
    timestamp: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

export const Alert = mongoose.model('Alert', AlertSchema);
