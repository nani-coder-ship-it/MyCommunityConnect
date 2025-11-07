import jwt from 'jsonwebtoken';
import { validationResult } from 'express-validator';
import { User } from '../models/User.js';
import { jwtConfig } from '../config/jwtConfig.js';

function signToken(user) {
  return jwt.sign({ id: user._id, role: user.role }, jwtConfig.secret, {
    expiresIn: jwtConfig.expiresIn,
  });
}

export async function register(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { name, email, password, roomNo, ownerName, phoneNo, adminCode } = req.body;
  console.log('[REGISTER] Start registration for:', email);
  console.log('[REGISTER] Request body:', { name, email, roomNo, ownerName, phoneNo, adminCode });
  
  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    console.log('[REGISTER] Invalid email format:', email);
    return res.status(400).json({ message: 'Please enter a valid email address' });
  }

  // Validate phone number format (10 digits, Indian format)
  const phoneRegex = /^[6-9]\d{9}$/;
  if (!phoneRegex.test(phoneNo)) {
    console.log('[REGISTER] Invalid phone number:', phoneNo);
    return res.status(400).json({ message: 'Please enter a valid 10-digit phone number' });
  }

  const existing = await User.findOne({ email });
  if (existing) {
    console.log('[REGISTER] Email already registered:', email);
    return res.status(409).json({ message: 'Email already registered' });
  }

  // Check admin code - set role to admin if code matches
  const ADMIN_CODE = process.env.ADMIN_CODE || 'admin2025';
  const role = (adminCode && adminCode === ADMIN_CODE) ? 'admin' : 'resident';
  console.log('[REGISTER] Admin code check:', { adminCode, ADMIN_CODE, role });

  console.log('[REGISTER] Hashing password for:', email);
  const passwordHash = await User.hashPassword(password);
  console.log('[REGISTER] Password hashed for:', email);
  const user = await User.create({
    name,
    email,
    passwordHash,
    roomNo,
    ownerName,
    phoneNo,
    role,
  });
  console.log('[REGISTER] User created:', email);
  const token = signToken(user);
  console.log('[REGISTER] Registration complete for:', email);
  return res
    .status(201)
    .json({ token, user: { ...user.toObject(), passwordHash: undefined } });
}

export async function login(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(401).json({ message: 'Invalid credentials' });
  const ok = await user.comparePassword(password);
  if (!ok) return res.status(401).json({ message: 'Invalid credentials' });
  console.log('[LOGIN] User logged in:', { email, role: user.role });
  const token = signToken(user);
  return res.json({ token, user: { ...user.toObject(), passwordHash: undefined } });
}

export async function me(req, res) {
  return res.json({ user: req.user });
}

export async function requestPasswordReset(req, res) {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: 'Email is required' });

  const user = await User.findOne({ email });
  if (!user) {
    return res.json({ message: 'If the email exists, a reset code has been sent' });
  }

  const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
  const resetCodeExpiry = new Date(Date.now() + 10 * 60 * 1000);

  user.resetCode = resetCode;
  user.resetCodeExpiry = resetCodeExpiry;
  await user.save();

  return res.json({ message: 'Reset code generated', resetCode });
}

export async function resetPassword(req, res) {
  const { email, resetCode, newPassword } = req.body;
  if (!email || !resetCode || !newPassword) {
    return res
      .status(400)
      .json({ message: 'Email, reset code, and new password are required' });
  }

  const user = await User.findOne({
    email,
    resetCode,
    resetCodeExpiry: { $gt: new Date() },
  });

  if (!user) {
    return res.status(400).json({ message: 'Invalid or expired reset code' });
  }

  user.passwordHash = await User.hashPassword(newPassword);
  user.resetCode = undefined;
  user.resetCodeExpiry = undefined;
  await user.save();

  return res.json({ message: 'Password reset successful' });
}
