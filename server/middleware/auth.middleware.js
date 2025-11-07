import jwt from 'jsonwebtoken';
import { jwtConfig } from '../config/jwtConfig.js';
import { User } from '../models/User.js';

export async function authMiddleware(req, res, next) {
  try {
    const auth = req.headers.authorization || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
    if (!token) return res.status(401).json({ message: 'No token provided' });
    const payload = jwt.verify(token, jwtConfig.secret);
    const user = await User.findById(payload.id).select('-passwordHash');
    if (!user) return res.status(401).json({ message: 'Invalid token user' });
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
}
