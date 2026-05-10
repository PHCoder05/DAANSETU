const express = require('express');
const router = express.Router();
const reportController = require('../../controllers/reportController');
const { authenticate, authorize } = require('../../middleware/auth');
const { mongoIdValidation, validate } = require('../../utils/validators');
const { body } = require('express-validator');

/**
 * @swagger
 * /api/v1/reports:
 *   post:
 *     summary: Submit a manual report
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 */
router.post(
  '/',
  authenticate,
  [
    body('targetId').isMongoId().withMessage('Valid target ID required'),
    body('targetType').isIn(['user', 'donation', 'request']).withMessage('Invalid target type'),
    body('reason').notEmpty().withMessage('Reason is required'),
    body('description').optional().trim(),
    validate
  ],
  reportController.submitReport
);

/**
 * @swagger
 * /api/v1/reports:
 *   get:
 *     summary: Get all reports (Admin only)
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 */
router.get(
  '/',
  authenticate,
  authorize('admin'),
  reportController.getAllReports
);

/**
 * @swagger
 * /api/v1/reports/{id}/resolve:
 *   put:
 *     summary: Resolve or dismiss a report (Admin only)
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 */
router.put(
  '/:id/resolve',
  authenticate,
  authorize('admin'),
  mongoIdValidation('id'),
  [
    body('status').isIn(['resolved', 'dismissed']).withMessage('Status must be resolved or dismissed'),
    body('resolution').notEmpty().withMessage('Resolution notes are required'),
    validate
  ],
  reportController.resolveReport
);

module.exports = router;
