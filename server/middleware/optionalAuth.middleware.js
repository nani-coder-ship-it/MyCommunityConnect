import jwt from 'jsonwebtoken';
import { jwtConfig } from '../config/jwtConfig.js';
import { User } from '../models/User.js';

// Parses JWT if present; otherwise continues without error.
export async function optionalAuth(req, res, next) {
  try {
    const auth = req.headers.authorization || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
    if (!token) return next();
    const payload = jwt.verify(token, jwtConfig.secret);
    const user = await User.findById(payload.id).select('-passwordHash');
    if (user) req.user = user;
  } catch (err) {
    // ignore invalid token and proceed as unauthenticated
  }
  return next();
}
