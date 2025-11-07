import mongoose from 'mongoose';

const MaintenanceRequestSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    issueType: { type: String, required: true },
    description: { type: String, required: true },
    priority: { type: String, enum: ['low', 'medium', 'high', 'urgent'], default: 'medium' },
    status: { type: String, enum: ['Open', 'In-Progress', 'Resolved', 'Rejected'], default: 'Open' },
    assignedTo: { type: String },
  },
  { timestamps: true }
);

export const MaintenanceRequest = mongoose.model('MaintenanceRequest', MaintenanceRequestSchema);
