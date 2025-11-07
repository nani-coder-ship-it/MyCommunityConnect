import mongoose from 'mongoose';

const VisitorSchema = new mongoose.Schema(
  {
    residentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    visitorName: { type: String, required: true },
    contact: { type: String },
    visitStart: { type: Date, required: true },
    visitEnd: { type: Date },
    status: { type: String, enum: ['Pending', 'Approved', 'Arrived', 'Exited', 'Rejected'], default: 'Pending' },
  },
  { timestamps: true }
);

export const Visitor = mongoose.model('Visitor', VisitorSchema);
