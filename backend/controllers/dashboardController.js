const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const { successResponse, errorResponse } = require('../utils/helpers');

// Get user dashboard data
const getUserDashboard = async (req, res) => {
  try {
    const { userId, role } = req.user;
    const db = getDB();

    let dashboardData = {};

    if (role === 'donor') {
      // Donor dashboard
      const donations = await db.collection('donations').aggregate([
        { $match: { donorId: new ObjectId(userId) } },
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 }
          }
        }
      ]).toArray();

      const recentDonations = await db.collection('donations')
        .find({ donorId: new ObjectId(userId) })
        .sort({ createdAt: -1 })
        .limit(5)
        .toArray();

      const pendingRequests = await db.collection('requests').aggregate([
        {
          $lookup: {
            from: 'donations',
            localField: 'donationId',
            foreignField: '_id',
            as: 'donation'
          }
        },
        { $unwind: '$donation' },
        {
          $match: {
            'donation.donorId': new ObjectId(userId),
            status: 'pending'
          }
        }
      ]).toArray();

      dashboardData = {
        role: 'donor',
        stats: {
          donations: donations.reduce((acc, curr) => {
            acc[curr._id] = curr.count;
            return acc;
          }, {}),
          totalDonations: donations.reduce((sum, curr) => sum + curr.count, 0),
          pendingRequests: pendingRequests.length
        },
        recentDonations,
        pendingRequests: pendingRequests.slice(0, 5)
      };

    } else if (role === 'ngo') {
      // NGO dashboard
      const claimedDonations = await db.collection('donations')
        .find({ claimedBy: new ObjectId(userId) })
        .sort({ createdAt: -1 })
        .limit(10)
        .toArray();

      const requestStats = await db.collection('requests').aggregate([
        { $match: { ngoId: new ObjectId(userId) } },
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 }
          }
        }
      ]).toArray();

      const availableDonations = await db.collection('donations')
        .find({ status: 'available', active: true })
        .sort({ createdAt: -1 })
        .limit(10)
        .toArray();

      dashboardData = {
        role: 'ngo',
        stats: {
          claimed: claimedDonations.length,
          requests: requestStats.reduce((acc, curr) => {
            acc[curr._id] = curr.count;
            return acc;
          }, {}),
          totalRequests: requestStats.reduce((sum, curr) => sum + curr.count, 0)
        },
        claimedDonations: claimedDonations.slice(0, 5),
        availableDonations: availableDonations.slice(0, 5)
      };

    } else if (role === 'admin') {
      // Admin dashboard
      const userStats = await db.collection('users').aggregate([
        {
          $group: {
            _id: '$role',
            count: { $sum: 1 }
          }
        }
      ]).toArray();

      const donationStats = await db.collection('donations').aggregate([
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 }
          }
        }
      ]).toArray();

      const pendingNGOs = await db.collection('users').countDocuments({
        role: 'ngo',
        'ngoDetails.verificationStatus': 'pending'
      });

      const recentUsers = await db.collection('users')
        .find()
        .sort({ createdAt: -1 })
        .limit(5)
        .toArray();

      dashboardData = {
        role: 'admin',
        stats: {
          users: userStats.reduce((acc, curr) => {
            acc[curr._id] = curr.count;
            return acc;
          }, {}),
          donations: donationStats.reduce((acc, curr) => {
            acc[curr._id] = curr.count;
            return acc;
          }, {}),
          pendingNGOs
        },
        recentUsers: recentUsers.map(u => ({ ...u, password: undefined }))
      };
    }

    return successResponse(res, 200, 'Dashboard data retrieved successfully', dashboardData);
  } catch (error) {
    console.error('Get dashboard error:', error);
    return errorResponse(res, 500, 'Error fetching dashboard data', error.message);
  }
};

// Get user activity history
const getUserActivity = async (req, res) => {
  try {
    const { userId } = req.user;
    const { page = 1, limit = 20 } = req.query;
    const db = getDB();

    // This would ideally come from an activity log collection
    // For now, we'll aggregate from existing data
    
    const activities = [];

    // Get donations
    const donations = await db.collection('donations')
      .find({ donorId: new ObjectId(userId) })
      .sort({ createdAt: -1 })
      .limit(10)
      .toArray();

    donations.forEach(d => {
      activities.push({
        type: 'donation_created',
        timestamp: d.createdAt,
        description: `Created donation: ${d.title}`,
        data: { donationId: d._id, title: d.title }
      });
    });

    // Get requests
    const requests = await db.collection('requests')
      .find({ ngoId: new ObjectId(userId) })
      .sort({ createdAt: -1 })
      .limit(10)
      .toArray();

    requests.forEach(r => {
      activities.push({
        type: 'request_created',
        timestamp: r.createdAt,
        description: 'Created donation request',
        data: { requestId: r._id }
      });
    });

    // Sort by timestamp
    activities.sort((a, b) => b.timestamp - a.timestamp);

    return successResponse(res, 200, 'Activity history retrieved', {
      activities: activities.slice(0, parseInt(limit)),
      total: activities.length
    });
  } catch (error) {
    console.error('Get activity error:', error);
    return errorResponse(res, 500, 'Error fetching activity', error.message);
  }
};

// Get leaderboard
const getLeaderboard = async (req, res) => {
  try {
    const { type = 'donors', limit = 10 } = req.query;
    const db = getDB();

    let leaderboard = [];

    if (type === 'donors') {
      // Top donors by donation count
      leaderboard = await db.collection('donations').aggregate([
        { $match: { status: { $in: ['delivered', 'in-transit', 'claimed'] } } },
        {
          $group: {
            _id: '$donorId',
            donationCount: { $sum: 1 },
            totalQuantity: { $sum: '$quantity' }
          }
        },
        { $sort: { donationCount: -1 } },
        { $limit: parseInt(limit) },
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: '_id',
            as: 'user'
          }
        },
        { $unwind: '$user' },
        {
          $project: {
            name: '$user.name',
            email: '$user.email',
            donationCount: 1,
            totalQuantity: 1
          }
        }
      ]).toArray();

    } else if (type === 'ngos') {
      // Top NGOs by claimed donations
      leaderboard = await db.collection('donations').aggregate([
        { $match: { status: { $in: ['delivered', 'in-transit'] }, claimedBy: { $exists: true } } },
        {
          $group: {
            _id: '$claimedBy',
            claimedCount: { $sum: 1 },
            deliveredCount: {
              $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] }
            }
          }
        },
        { $sort: { deliveredCount: -1 } },
        { $limit: parseInt(limit) },
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: '_id',
            as: 'user'
          }
        },
        { $unwind: '$user' },
        {
          $project: {
            name: '$user.name',
            claimedCount: 1,
            deliveredCount: 1
          }
        }
      ]).toArray();
    }

    return successResponse(res, 200, 'Leaderboard retrieved successfully', {
      type,
      leaderboard
    });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    return errorResponse(res, 500, 'Error fetching leaderboard', error.message);
  }
};

module.exports = {
  getUserDashboard,
  getUserActivity,
  getLeaderboard
};

