const express = require('express');
const router = express.Router();
const dashboardController = require('../../controllers/dashboardController');
const { authenticate } = require('../../middleware/auth');

// All dashboard routes require authentication
router.use(authenticate);

/**
 * @swagger
 * /api/dashboard:
 *   get:
 *     summary: Get user dashboard data (role-specific)
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard data retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 role:
 *                   type: string
 *                 stats:
 *                   type: object
 *                 recentDonations:
 *                   type: array
 */
router.get('/', dashboardController.getUserDashboard);

/**
 * @swagger
 * /api/dashboard/activity:
 *   get:
 *     summary: Get user activity history
 *     tags: [Dashboard]
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
 *         description: Activity history retrieved
 */
router.get('/activity', dashboardController.getUserActivity);

/**
 * @swagger
 * /api/dashboard/leaderboard:
 *   get:
 *     summary: Get platform leaderboard
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [donors, ngos]
 *         description: Leaderboard type (default donors)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Number of results (default 10)
 *     responses:
 *       200:
 *         description: Leaderboard data
 */
router.get('/leaderboard', dashboardController.getLeaderboard);

module.exports = router;

