import mongoose from 'mongoose';

const MessageSchema = new mongoose.Schema(
  {
    roomId: { type: String, required: true },
    senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    senderName: { type: String },
    text: { type: String },
    imageUrl: { type: String },
    readBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

export const Message = mongoose.model('Message', MessageSchema);
