const express = require('express');
const router = express.Router();
const gamificationController = require('../../controllers/gamificationController');
const { authenticate } = require('../../middleware/auth');

// GET /api/v1/gamification/leaderboard - Get top donors
router.get('/leaderboard', authenticate, gamificationController.getLeaderboard);

// GET /api/v1/gamification/stats - Get personal badges and rank
router.get('/stats', authenticate, gamificationController.getUserStats);

module.exports = router;
