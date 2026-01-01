const express = require('express');
const router = express.Router();
const passwordResetController = require('../../controllers/passwordResetController');
const { body, query } = require('express-validator');
const { validate } = require('../../utils/validators');

/**
 * @swagger
 * /api/password-reset/request:
 *   post:
 *     summary: Request password reset
 *     tags: [Password Reset]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: Reset link sent (if email exists)
 */
router.post('/request',
  [
    body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
    validate
  ],
  passwordResetController.requestPasswordReset
);

/**
 * @swagger
 * /api/password-reset/verify:
 *   get:
 *     summary: Verify reset token validity
 *     tags: [Password Reset]
 *     parameters:
 *       - in: query
 *         name: token
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Token is valid
 *       400:
 *         description: Token is invalid or expired
 */
router.get('/verify',
  [
    query('token').notEmpty().withMessage('Token is required'),
    validate
  ],
  passwordResetController.verifyResetToken
);

/**
 * @swagger
 * /api/password-reset/reset:
 *   post:
 *     summary: Reset password with token
 *     tags: [Password Reset]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - token
 *               - newPassword
 *             properties:
 *               token:
 *                 type: string
 *               newPassword:
 *                 type: string
 *                 minLength: 6
 *     responses:
 *       200:
 *         description: Password reset successfully
 *       400:
 *         description: Invalid or expired token
 */
router.post('/reset',
  [
    body('token').notEmpty().withMessage('Token is required'),
    body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    validate
  ],
  passwordResetController.resetPassword
);

module.exports = router;

