const express = require('express');
const router = express.Router();
const donationController = require('../../controllers/donationController');
const { authenticate, optionalAuth } = require('../../middleware/auth');
const {
  createDonationValidation,
  updateDonationValidation,
  mongoIdValidation,
  paginationValidation
} = require('../../utils/validators');
const { body } = require('express-validator');
const { validate } = require('../../utils/validators');

/**
 * @swagger
 * /api/donations:
 *   get:
 *     summary: Get all donations
 *     tags: [Donations]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Items per page
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *           enum: [food, clothes, books, medical, electronics, furniture, other]
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [available, claimed, in-transit, delivered, cancelled]
 *     responses:
 *       200:
 *         description: List of donations
 */
router.get('/', optionalAuth, paginationValidation, donationController.getDonations);

/**
 * @swagger
 * /api/donations/nearby:
 *   get:
 *     summary: Find nearby donations
 *     tags: [Donations]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: lng
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: maxDistance
 *         schema:
 *           type: number
 *         description: Maximum distance in km (default 50)
 *     responses:
 *       200:
 *         description: List of nearby donations
 */
router.get('/nearby', optionalAuth, donationController.getNearbyDonations);

/**
 * @swagger
 * /api/donations/stats/summary:
 *   get:
 *     summary: Get donation statistics
 *     tags: [Donations]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistics retrieved successfully
 */
router.get('/stats/summary', authenticate, donationController.getDonationStats);

/**
 * @swagger
 * /api/donations/my:
 *   get:
 *     summary: Get my donations (as donor or NGO)
 *     tags: [Donations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [all, active, completed, expired]
 *         description: Filter by status type
 *       - in: query
 *         name: role
 *         schema:
 *           type: string
 *           enum: [donor, ngo]
 *         description: Override role for filter
 *     responses:
 *       200:
 *         description: List of user's donations
 */
router.get('/my', authenticate, donationController.getMyDonations);

/**
 * @swagger
 * /api/donations/{id}:
 *   get:
 *     summary: Get donation by ID
 *     tags: [Donations]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Donation details
 *       404:
 *         description: Donation not found
 */
router.get('/:id', optionalAuth, mongoIdValidation('id'), donationController.getDonationById);

// Protected routes
/**
 * @swagger
 * /api/donations:
 *   post:
 *     summary: Create a new donation (Donor only)
 *     tags: [Donations]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - description
 *               - category
 *               - pickupLocation
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               category:
 *                 type: string
 *                 enum: [food, clothes, books, medical, electronics, furniture, other]
 *               quantity:
 *                 type: number
 *               unit:
 *                 type: string
 *               pickupLocation:
 *                 type: object
 *                 properties:
 *                   lat:
 *                     type: number
 *                   lng:
 *                     type: number
 *                   address:
 *                     type: string
 *     responses:
 *       201:
 *         description: Donation created successfully
 *       403:
 *         description: Only donors can create donations
 */
router.post('/', authenticate, createDonationValidation, donationController.createDonation);

/**
 * @swagger
 * /api/donations/{id}:
 *   put:
 *     summary: Update donation
 *     tags: [Donations]
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
 *     responses:
 *       200:
 *         description: Donation updated successfully
 */
router.put('/:id', authenticate, mongoIdValidation('id'), updateDonationValidation, donationController.updateDonation);

/**
 * @swagger
 * /api/donations/{id}:
 *   delete:
 *     summary: Delete donation
 *     tags: [Donations]
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
 *         description: Donation deleted successfully
 */
router.delete('/:id', authenticate, mongoIdValidation('id'), donationController.deleteDonation);

/**
 * @swagger
 * /api/donations/{id}/claim:
 *   post:
 *     summary: Claim a donation (Verified NGO only)
 *     tags: [Donations]
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
 *         description: Donation claimed successfully
 *       403:
 *         description: NGO must be verified
 */
router.post('/:id/claim', authenticate, mongoIdValidation('id'), donationController.claimDonation);

/**
 * @swagger
 * /api/donations/{id}/status:
 *   put:
 *     summary: Update donation status
 *     tags: [Donations]
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
 *                 enum: [available, claimed, in-transit, delivered, cancelled]
 *     responses:
 *       200:
 *         description: Status updated successfully
 */
router.put(
  '/:id/status',
  authenticate,
  mongoIdValidation('id'),
  [
    body('status')
      .isIn(['available', 'claimed', 'in-transit', 'delivered', 'cancelled'])
      .withMessage('Invalid status'),
    validate
  ],
  donationController.updateDonationStatus
);


/**
 * @swagger
 * /api/donations/{id}/timeline:
 *   get:
 *     summary: Get donation timeline (status history)
 *     tags: [Donations]
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
 *         description: Timeline retrieved
 */
router.get('/:id/timeline', authenticate, mongoIdValidation('id'), donationController.getDonationTimeline);

/**
 * @swagger
 * /api/donations/{id}/receipt:
 *   get:
 *     summary: Download tax receipt PDF
 *     tags: [Donations]
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
 *         description: PDF content
 *       403:
 *         description: Only donor or admin can download receipt
 */
router.get('/:id/receipt', authenticate, mongoIdValidation('id'), donationController.getDonationReceipt);

module.exports = router;
