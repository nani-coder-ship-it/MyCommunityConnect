import mongoose from 'mongoose';

const EventSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true },
    description: { type: String },
    eventDate: { type: Date, required: true },
    imageUrl: { type: String },
  },
  { timestamps: true }
);

export const Event = mongoose.model('Event', EventSchema);
