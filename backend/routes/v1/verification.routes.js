const express = require('express');
const router = express.Router();
const verificationController = require('../../controllers/verificationController');
const { authenticate } = require('../../middleware/auth');
const { mongoIdValidation } = require('../../utils/validators');
const { body } = require('express-validator');
const { validate } = require('../../utils/validators');
const upload = require('../../middleware/upload');

/**
 * @swagger
 * /api/v1/verification/request:
 *   post:
 *     summary: Request verification (auto-verifies NGO via govt APIs)
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post(
    '/request',
    authenticate,
    [
        body('type').isIn(['email', 'phone', 'id_proof', 'ngo_registration', 'ngo_certificate']).withMessage('Invalid verification type'),
        validate
    ],
    verificationController.requestVerification
);

/**
 * @swagger
 * /api/v1/verification/documents:
 *   post:
 *     summary: Upload verification documents
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post(
    '/documents',
    authenticate,
    upload.single('document'),
    verificationController.uploadVerificationDocument
);

/**
 * @swagger
 * /api/v1/verification/ngo/auto-verify:
 *   post:
 *     summary: Auto-verify NGO using government databases (Darpan, 80G, MCA)
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post('/ngo/auto-verify', authenticate, verificationController.autoVerifyNgo);

/**
 * @swagger
 * /api/v1/verification/ngo/darpan:
 *   post:
 *     summary: Verify NGO using Darpan ID only
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post('/ngo/darpan', authenticate, verificationController.verifyDarpanId);

/**
 * @swagger
 * /api/v1/verification/ngo/80g:
 *   post:
 *     summary: Verify 80G certificate using PAN
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post('/ngo/80g', authenticate, verificationController.verify80G);

/**
 * @swagger
 * /api/v1/verification/steps:
 *   get:
 *     summary: Get verification steps progress (for NGO to track their verification)
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *         description: "Verification type (default: ngo_registration)"
 */
router.get('/steps', authenticate, verificationController.getVerificationSteps);

/**
 * @swagger
 * /api/v1/verification/status:
 *   get:
 *     summary: Get my verification status
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.get('/status', authenticate, verificationController.getMyVerificationStatus);

/**
 * @swagger
 * /api/v1/verification/pending:
 *   get:
 *     summary: Admin - Get pending verifications
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.get('/pending', authenticate, verificationController.getPendingVerifications);

/**
 * @swagger
 * /api/v1/verification/{id}/approve:
 *   post:
 *     summary: Admin - Approve verification
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:id/approve', authenticate, mongoIdValidation('id'), verificationController.approveVerification);

/**
 * @swagger
 * /api/v1/verification/{id}/reject:
 *   post:
 *     summary: Admin - Reject verification
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post(
    '/:id/reject',
    authenticate,
    mongoIdValidation('id'),
    [body('reason').notEmpty().withMessage('Rejection reason required'), validate],
    verificationController.rejectVerification
);

// ═══════════════════════════════════════════════════════════════════
// Admin Override & Bypass Routes
// ═══════════════════════════════════════════════════════════════════

/**
 * @swagger
 * /api/v1/verification/{id}/bypass:
 *   post:
 *     summary: Admin - Bypass government API verification and approve directly
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post(
    '/:id/bypass',
    authenticate,
    mongoIdValidation('id'),
    [body('reason').isLength({ min: 10 }).withMessage('Bypass reason required (min 10 chars)'), validate],
    verificationController.adminBypassVerification
);

/**
 * @swagger
 * /api/v1/verification/{id}/rerun-api:
 *   post:
 *     summary: Admin - Force re-run government API verification
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:id/rerun-api', authenticate, mongoIdValidation('id'), verificationController.adminRerunApiVerification);

// ═══════════════════════════════════════════════════════════════════
// NGO Support Contact Routes
// ═══════════════════════════════════════════════════════════════════

/**
 * @swagger
 * /api/v1/verification/support/request:
 *   post:
 *     summary: NGO - Request support / contact admin for verification issues
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post(
    '/support/request',
    authenticate,
    [
        body('issue').notEmpty().withMessage('Issue type required'),
        body('message').notEmpty().withMessage('Message required'),
        validate
    ],
    verificationController.requestSupport
);

/**
 * @swagger
 * /api/v1/verification/support/my:
 *   get:
 *     summary: NGO - Get my support requests
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.get('/support/my', authenticate, verificationController.getMySupportRequests);

/**
 * @swagger
 * /api/v1/verification/support/all:
 *   get:
 *     summary: Admin - Get all support requests
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.get('/support/all', authenticate, verificationController.getAllSupportRequests);

/**
 * @swagger
 * /api/v1/verification/support/{id}/respond:
 *   post:
 *     summary: Admin - Respond to support request
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post('/support/:id/respond', authenticate, mongoIdValidation('id'), verificationController.respondToSupport);

// ═══════════════════════════════════════════════════════════════════
// Fraud Alert Routes (Admin only)
// ═══════════════════════════════════════════════════════════════════

/**
 * @swagger
 * /api/v1/verification/fraud-alerts:
 *   get:
 *     summary: Admin - Get fraud alerts
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.get('/fraud-alerts', authenticate, verificationController.getFraudAlerts);

/**
 * @swagger
 * /api/v1/verification/fraud-alerts/{id}/resolve:
 *   post:
 *     summary: Admin - Resolve fraud alert
 *     tags: [Verification]
 *     security:
 *       - bearerAuth: []
 */
router.post('/fraud-alerts/:id/resolve', authenticate, mongoIdValidation('id'), verificationController.resolveFraudAlert);

module.exports = router;

