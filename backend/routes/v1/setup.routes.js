const express = require('express');
const router = express.Router();
const setupController = require('../../controllers/setupController');
const { body } = require('express-validator');
const { validate } = require('../../utils/validators');

/**
 * @swagger
 * /api/setup/check:
 *   get:
 *     summary: Check if first-time setup is required
 *     tags: [Setup]
 *     responses:
 *       200:
 *         description: Setup status retrieved
 */
router.get('/check', setupController.checkSetup);

/**
 * @swagger
 * /api/setup/admin:
 *   post:
 *     summary: Create first admin account (one-time setup)
 *     tags: [Setup]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - name
 *               - setupKey
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 minLength: 6
 *               name:
 *                 type: string
 *               setupKey:
 *                 type: string
 *                 description: Setup key from environment variable
 *     responses:
 *       201:
 *         description: Admin account created successfully
 *       400:
 *         description: Admin already exists or validation error
 *       403:
 *         description: Invalid setup key
 */
router.post('/admin',
  [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('name').trim().isLength({ min: 2 }).withMessage('Name is required'),
    body('setupKey').notEmpty().withMessage('Setup key is required'),
    validate
  ],
  setupController.firstTimeSetup
);

module.exports = router;

