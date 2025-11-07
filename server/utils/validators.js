import { body } from 'express-validator';

export const registerValidator = [
  body('name').isString().isLength({ min: 2 }),
  body('email').isEmail(),
  body('password').isLength({ min: 6 }),
  body('roomNo').optional().isString(),
  body('ownerName').optional().isString(),
  body('phoneNo').optional().isString(),
];

export const loginValidator = [
  body('email').isEmail(),
  body('password').isString().isLength({ min: 6 }),
];

export const postCreateValidator = [
  body('message').isString().isLength({ min: 1 }),
  body('image').optional().isString(),
];
