const express = require('express');
const router = express.Router();
const auditController = require('../../controllers/auditController');
const { authenticate } = require('../../middleware/auth');
const { mongoIdValidation } = require('../../utils/validators');

/**
 * @swagger
 * /api/v1/audit/my:
 *   get:
 *     summary: Get current user's activity log
 *     tags: [Audit]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Max results (default 50)
 *       - in: query
 *         name: action
 *         schema:
 *           type: string
 *         description: Filter by action type
 *       - in: query
 *         name: resource
 *         schema:
 *           type: string
 *         description: Filter by resource type
 *     responses:
 *       200:
 *         description: Activity log retrieved
 */
router.get('/my', authenticate, auditController.getMyActivity);

/**
 * @swagger
 * /api/v1/audit/summary:
 *   get:
 *     summary: Get activity summary for dashboard
 *     tags: [Audit]
 *     security:
 *       - bearerAuth: []
 */
router.get('/summary', authenticate, auditController.getActivitySummary);

/**
 * @swagger
 * /api/v1/audit/donation/{donationId}:
 *   get:
 *     summary: Get audit trail for a specific donation
 *     tags: [Audit]
 *     security:
 *       - bearerAuth: []
 */
router.get('/donation/:donationId', authenticate, mongoIdValidation('donationId'), auditController.getDonationAuditTrail);

/**
 * @swagger
 * /api/v1/audit/user/{userId}:
 *   get:
 *     summary: Admin - Get user's full activity history
 *     tags: [Audit]
 *     security:
 *       - bearerAuth: []
 */
router.get('/user/:userId', authenticate, mongoIdValidation('userId'), auditController.getUserActivity);

module.exports = router;
