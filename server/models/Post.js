import mongoose from 'mongoose';

const PostSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    userName: { type: String },
    message: { type: String, required: true },
    imageUrl: { type: String }, // Legacy: single image
    images: { type: [String], default: [] }, // New: multiple images
    likes: { type: [mongoose.Schema.Types.ObjectId], ref: 'User', default: [] },
    likesCount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

export const Post = mongoose.model('Post', PostSchema);
