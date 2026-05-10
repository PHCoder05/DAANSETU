const express = require('express');
const router = express.Router();
const reviewController = require('../../controllers/reviewController');
const { authenticate } = require('../../middleware/auth');
const { mongoIdValidation } = require('../../utils/validators');
const { body } = require('express-validator');
const { validate } = require('../../utils/validators');

/**
 * @swagger
 * /api/reviews:
 *   post:
 *     summary: Create review for NGO (Donor only)
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ngoId
 *               - donationId
 *               - rating
 *             properties:
 *               ngoId:
 *                 type: string
 *               donationId:
 *                 type: string
 *               rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               comment:
 *                 type: string
 *     responses:
 *       201:
 *         description: Review created successfully
 *       400:
 *         description: Donation not delivered or already reviewed
 */
router.post('/',
  authenticate,
  [
    body('ngoId').isMongoId().withMessage('Valid NGO ID required'),
    body('donationId').isMongoId().withMessage('Valid donation ID required'),
    body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
    body('comment').optional().trim().isLength({ max: 1000 }).withMessage('Comment too long'),
    validate
  ],
  reviewController.createReview
);

/**
 * @swagger
 * /api/reviews/ngo/{ngoId}:
 *   get:
 *     summary: Get reviews for an NGO
 *     tags: [Reviews]
 *     parameters:
 *       - in: path
 *         name: ngoId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Reviews with average rating
 */
router.get('/ngo/:ngoId', mongoIdValidation('ngoId'), reviewController.getNGOReviews);

/**
 * @swagger
 * /api/reviews/{id}:
 *   put:
 *     summary: Update own review (Donor only)
 *     tags: [Reviews]
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
 *             properties:
 *               rating:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               comment:
 *                 type: string
 *     responses:
 *       200:
 *         description: Review updated successfully
 */
router.put('/:id',
  authenticate,
  mongoIdValidation('id'),
  [
    body('rating').optional().isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
    body('comment').optional().trim().isLength({ max: 1000 }).withMessage('Comment too long'),
    validate
  ],
  reviewController.updateReview
);

/**
 * @swagger
 * /api/reviews/{id}:
 *   delete:
 *     summary: Delete review
 *     tags: [Reviews]
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
 *         description: Review deleted successfully
 */
router.delete('/:id', authenticate, mongoIdValidation('id'), reviewController.deleteReview);

/**
 * @swagger
 * /api/reviews/{id}/respond:
 *   put:
 *     summary: NGO respond to review
 *     tags: [Reviews]
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
 *               - response
 *             properties:
 *               response:
 *                 type: string
 *     responses:
 *       200:
 *         description: Response added successfully
 */
router.put('/:id/respond',
  authenticate,
  mongoIdValidation('id'),
  [
    body('response').trim().isLength({ min: 1, max: 500 }).withMessage('Response required (max 500 chars)'),
    validate
  ],
  reviewController.respondToReview
);

/**
 * @swagger
 * /api/reviews/volunteer:
 *   post:
 *     summary: Create review for Volunteer (Donor or NGO)
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - volunteerId
 *               - donationId
 *               - rating
 *             properties:
 *               volunteerId:
 *                 type: string
 *               donationId:
 *                 type: string
 *               rating:
 *                 type: integer
 *               comment:
 *                 type: string
 *     responses:
 *       201:
 *         description: Review submitted
 */
router.post('/volunteer',
  authenticate,
  [
    body('volunteerId').isMongoId().withMessage('Valid Volunteer ID required'),
    body('donationId').isMongoId().withMessage('Valid Donation ID required'),
    body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be 1-5'),
    body('comment').optional().trim().isLength({ max: 500 }),
    validate
  ],
  reviewController.createVolunteerReview
);

/**
 * @swagger
 * /api/reviews/volunteer/{volunteerId}:
 *   get:
 *     summary: Get reviews for a volunteer
 *     tags: [Reviews]
 *     parameters:
 *       - in: path
 *         name: volunteerId
 *         required: true
 *         schema:
 *           type: string
 */
router.get('/volunteer/:volunteerId', mongoIdValidation('volunteerId'), reviewController.getVolunteerReviews);

module.exports = router;

