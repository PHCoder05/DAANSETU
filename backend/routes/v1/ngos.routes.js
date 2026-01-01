const express = require('express');
const router = express.Router();
const ngoController = require('../../controllers/ngoController');
const { authenticate, optionalAuth } = require('../../middleware/auth');
const {
  createRequestValidation,
  mongoIdValidation,
  paginationValidation
} = require('../../utils/validators');
const { body } = require('express-validator');
const { validate } = require('../../utils/validators');

/**
 * @swagger
 * /api/ngos:
 *   get:
 *     summary: Get all verified NGOs
 *     tags: [NGOs]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of verified NGOs
 */
router.get('/', optionalAuth, paginationValidation, ngoController.getNGOs);

/**
 * @swagger
 * /api/ngos/{id}:
 *   get:
 *     summary: Get NGO by ID
 *     tags: [NGOs]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: NGO details
 *       404:
 *         description: NGO not found
 */
router.get('/:id', optionalAuth, mongoIdValidation('id'), ngoController.getNGOById);

/**
 * @swagger
 * /api/ngos/requests:
 *   post:
 *     summary: Create a donation request (Verified NGO only)
 *     tags: [NGOs]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - donationId
 *             properties:
 *               donationId:
 *                 type: string
 *               message:
 *                 type: string
 *               beneficiariesCount:
 *                 type: integer
 *               priority:
 *                 type: string
 *                 enum: [low, normal, high, urgent]
 *     responses:
 *       201:
 *         description: Request created successfully
 *       403:
 *         description: NGO must be verified
 */
router.post('/requests', authenticate, createRequestValidation, ngoController.createRequest);

/**
 * @swagger
 * /api/ngos/requests/list:
 *   get:
 *     summary: Get donation requests
 *     tags: [NGOs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, approved, rejected, cancelled]
 *     responses:
 *       200:
 *         description: List of requests
 */
router.get('/requests/list', authenticate, paginationValidation, ngoController.getRequests);

/**
 * @swagger
 * /api/ngos/requests/{id}/status:
 *   put:
 *     summary: Approve or reject a request (Donor only)
 *     tags: [NGOs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [approved, rejected]
 *               response:
 *                 type: string
 *     responses:
 *       200:
 *         description: Request status updated
 */
router.put(
  '/requests/:id/status',
  authenticate,
  mongoIdValidation('id'),
  [
    body('status')
      .isIn(['approved', 'rejected'])
      .withMessage('Status must be either approved or rejected'),
    validate
  ],
  ngoController.updateRequestStatus
);

/**
 * @swagger
 * /api/ngos/requests/{id}/cancel:
 *   put:
 *     summary: Cancel own request (NGO only)
 *     tags: [NGOs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Request cancelled successfully
 */
router.put('/requests/:id/cancel', authenticate, mongoIdValidation('id'), ngoController.cancelRequest);

module.exports = router;

