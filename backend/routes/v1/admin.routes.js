const express = require('express');
const router = express.Router();
const adminController = require('../../controllers/adminController');
const { authenticate, authorize } = require('../../middleware/auth');
const { verifyNGOValidation, paginationValidation, mongoIdValidation } = require('../../utils/validators');

// All admin routes require authentication and admin role
router.use(authenticate, authorize('admin'));

/**
 * @swagger
 * /api/admin/users:
 *   get:
 *     summary: Get all users (Admin only)
 *     tags: [Admin]
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
 *         name: role
 *         schema:
 *           type: string
 *           enum: [donor, ngo, admin]
 *       - in: query
 *         name: verified
 *         schema:
 *           type: boolean
 *       - in: query
 *         name: active
 *         schema:
 *           type: boolean
 *     responses:
 *       200:
 *         description: List of users
 *       403:
 *         description: Admin access required
 */
router.get('/users', paginationValidation, adminController.getAllUsers);

/**
 * @swagger
 * /api/admin/users/{userId}:
 *   delete:
 *     summary: Delete user (Admin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: User deleted successfully
 */
router.delete('/users/:userId', mongoIdValidation('userId'), adminController.deleteUser);

/**
 * @swagger
 * /api/admin/users/{userId}/toggle-status:
 *   put:
 *     summary: Activate/deactivate user (Admin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: User status updated
 */
router.put('/users/:userId/toggle-status', mongoIdValidation('userId'), adminController.toggleUserStatus);

/**
 * @swagger
 * /api/admin/ngos/pending:
 *   get:
 *     summary: Get pending NGO verifications (Admin only)
 *     tags: [Admin]
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
 *     responses:
 *       200:
 *         description: List of pending NGOs
 */
router.get('/ngos/pending', paginationValidation, adminController.getPendingNGOs);

/**
 * @swagger
 * /api/admin/ngos/{userId}/verify-gov:
 *   post:
 *     summary: Verify NGO against Government Darpan API (Admin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Government API check results
 */
router.post('/ngos/:userId/verify-gov', mongoIdValidation, adminController.checkGovVerification);

/**
 * @swagger
 * /api/admin/ngos/{userId}/verify:
 *   put:
 *     summary: Verify or reject NGO (Admin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
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
 *                 enum: [verified, rejected]
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: NGO verification status updated
 */
router.put('/ngos/:userId/verify', verifyNGOValidation, adminController.verifyNGO);

/**
 * @swagger
 * /api/admin/stats:
 *   get:
 *     summary: Get platform statistics (Admin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Platform statistics
 */
router.get('/stats', adminController.getPlatformStats);

/**
 * @swagger
 * /api/admin/volunteers/active:
 *   get:
 *     summary: Get all active volunteers and their locations (Admin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of active volunteers
 */
router.get('/volunteers/active', adminController.getActiveVolunteers);

// Development only - seed database
if (process.env.NODE_ENV === 'development') {
  /**
   * @swagger
   * /api/admin/seed:
   *   post:
   *     summary: Seed test data (Development only)
   *     tags: [Admin]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: Test data seeded successfully
   */
  router.post('/seed', adminController.seedDatabase);
}

module.exports = router;

