const { getDB } = require('../config/db');
const User = require('../models/User');
const { successResponse, errorResponse } = require('../utils/helpers');

/**
 * Get global leaderboard of donors ranked by impact score
 */
exports.getLeaderboard = async (req, res) => {
  try {
    const db = getDB();
    
    // Find top 20 donors by impact score
    const topDonors = await db.collection('users')
      .find({ role: 'donor', impactScore: { $gt: 0 } })
      .project({
        name: 1,
        profileImage: 1,
        impactScore: 1,
        badges: 1,
        'donorStats.completedDonations': 1
      })
      .sort({ impactScore: -1 })
      .limit(20)
      .toArray();

    return successResponse(res, 200, 'Leaderboard retrieved successfully', {
      leaderboard: topDonors
    });
  } catch (error) {
    console.error('Leaderboard error:', error);
    return errorResponse(res, 500, 'Failed to fetch leaderboard');
  }
};

/**
 * Get current user's badges and rank
 */
exports.getUserStats = async (req, res) => {
  try {
    const db = getDB();
    const userId = req.user.userId;

    const user = await db.collection('users').findOne({ _id: new (require('mongodb').ObjectId)(userId) });
    
    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    // Calculate rank
    const rank = await db.collection('users').countDocuments({
      role: 'donor',
      impactScore: { $gt: user.impactScore || 0 }
    }) + 1;

    return successResponse(res, 200, 'User stats retrieved', {
      impactScore: user.impactScore || 0,
      badges: user.badges || [],
      rank: rank,
      completedDonations: user.donorStats?.completedDonations || 0
    });
  } catch (error) {
    console.error('User stats error:', error);
    return errorResponse(res, 500, 'Failed to fetch user stats');
  }
};
