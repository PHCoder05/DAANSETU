const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const User = require('../models/User');
const Donation = require('../models/Donation');
const Notification = require('../models/Notification');
const {
  getPagination,
  buildPaginationResponse,
  sanitizeUser,
  successResponse,
  errorResponse
} = require('../utils/helpers');

// Get all users
const getAllUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, role, verified, active } = req.query;
    const { skip, limit: limitNum } = getPagination(page, limit);

    const db = getDB();

    // Build filter
    const filter = {};
    if (role) filter.role = role;
    if (verified !== undefined) filter.verified = verified === 'true';
    if (active !== undefined) filter.active = active === 'true';

    const users = await User.findAll(db, filter, {
      skip,
      limit: limitNum,
      sort: { createdAt: -1 }
    });

    const sanitizedUsers = users.map(sanitizeUser);
    const total = await User.count(db, filter);

    return successResponse(
      res,
      200,
      'Users retrieved successfully',
      buildPaginationResponse(sanitizedUsers, total, page, limitNum)
    );
  } catch (error) {
    console.error('Get all users error:', error);
    return errorResponse(res, 500, 'Error fetching users', error.message);
  }
};

// Get pending NGO verifications
const getPendingNGOs = async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const { skip, limit: limitNum } = getPagination(page, limit);

    const db = getDB();

    const filter = {
      role: 'ngo',
      'ngoDetails.verificationStatus': 'pending'
    };

    const ngos = await User.findAll(db, filter, {
      skip,
      limit: limitNum,
      sort: { createdAt: 1 } // Oldest first
    });

    const sanitizedNGOs = ngos.map(sanitizeUser);
    const total = await User.count(db, filter);

    return successResponse(
      res,
      200,
      'Pending NGO verifications retrieved successfully',
      buildPaginationResponse(sanitizedNGOs, total, page, limitNum)
    );
  } catch (error) {
    console.error('Get pending NGOs error:', error);
    return errorResponse(res, 500, 'Error fetching pending NGOs', error.message);
  }
};

// Verify or reject NGO
const verifyNGO = async (req, res) => {
  try {
    const { userId } = req.params;
    const { status, reason } = req.body;

    const db = getDB();

    const user = await User.findById(db, userId);
    if (!user || user.role !== 'ngo') {
      return errorResponse(res, 404, 'NGO not found');
    }

    if (user.ngoDetails?.verificationStatus !== 'pending') {
      return errorResponse(res, 400, 'This NGO verification is not pending');
    }

    // Update NGO verification status
    const updateData = {
      'ngoDetails.verificationStatus': status,
      verified: status === 'verified'
    };

    if (reason) {
      updateData['ngoDetails.verificationReason'] = reason;
    }

    await User.update(db, userId, updateData);

    // Create notification
    await Notification.create(db, {
      userId: new ObjectId(userId),
      title: status === 'verified' ? 'NGO Verified' : 'NGO Verification Rejected',
      message: status === 'verified'
        ? 'Congratulations! Your NGO has been verified. You can now claim donations.'
        : `Your NGO verification was rejected. ${reason || 'Please contact support for more information.'}`,
      type: 'verification',
      priority: 'high'
    });

    const updatedUser = await User.findById(db, userId);

    return successResponse(res, 200, `NGO ${status} successfully`, {
      user: sanitizeUser(updatedUser)
    });
  } catch (error) {
    console.error('Verify NGO error:', error);
    return errorResponse(res, 500, 'Error verifying NGO', error.message);
  }
};

// Toggle user active status
const toggleUserStatus = async (req, res) => {
  try {
    const { userId } = req.params;

    const db = getDB();

    const user = await User.findById(db, userId);
    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    if (user.role === 'admin') {
      return errorResponse(res, 403, 'Cannot deactivate admin users');
    }

    const newStatus = !user.active;
    await User.update(db, userId, { active: newStatus });

    // Create notification
    await Notification.create(db, {
      userId: new ObjectId(userId),
      title: newStatus ? 'Account Activated' : 'Account Deactivated',
      message: newStatus
        ? 'Your account has been activated. You can now access all features.'
        : 'Your account has been deactivated. Please contact support for assistance.',
      type: 'system',
      priority: 'high'
    });

    return successResponse(res, 200, `User ${newStatus ? 'activated' : 'deactivated'} successfully`);
  } catch (error) {
    console.error('Toggle user status error:', error);
    return errorResponse(res, 500, 'Error updating user status', error.message);
  }
};

// Delete user
const deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const db = getDB();

    const user = await User.findById(db, userId);
    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    if (user.role === 'admin') {
      return errorResponse(res, 403, 'Cannot delete admin users');
    }

    // Delete user's donations if donor
    if (user.role === 'donor') {
      await db.collection('donations').deleteMany({
        donorId: new ObjectId(userId)
      });
    }

    // Delete user's requests if NGO
    if (user.role === 'ngo') {
      await db.collection('requests').deleteMany({
        ngoId: new ObjectId(userId)
      });
    }

    // Delete user's notifications
    await db.collection('notifications').deleteMany({
      userId: new ObjectId(userId)
    });

    // Delete user
    await User.delete(db, userId);

    return successResponse(res, 200, 'User deleted successfully');
  } catch (error) {
    console.error('Delete user error:', error);
    return errorResponse(res, 500, 'Error deleting user', error.message);
  }
};

// Get platform statistics
const getPlatformStats = async (req, res) => {
  try {
    const db = getDB();

    // User statistics
    const totalUsers = await User.count(db);
    const totalDonors = await User.count(db, { role: 'donor' });
    const totalNGOs = await User.count(db, { role: 'ngo' });
    const verifiedNGOs = await User.count(db, { role: 'ngo', verified: true });
    const pendingNGOs = await User.count(db, { role: 'ngo', 'ngoDetails.verificationStatus': 'pending' });

    // Donation statistics
    const totalDonations = await Donation.count(db);
    const availableDonations = await Donation.count(db, { status: 'available' });
    const claimedDonations = await Donation.count(db, { status: 'claimed' });
    const deliveredDonations = await Donation.count(db, { status: 'delivered' });

    // Category breakdown
    const categoryStats = await db.collection('donations').aggregate([
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 }
        }
      }
    ]).toArray();

    // Recent activity
    const recentDonations = await Donation.findAll(db, {}, {
      limit: 5,
      sort: { createdAt: -1 }
    });

    const recentUsers = await User.findAll(db, {}, {
      limit: 5,
      sort: { createdAt: -1 }
    });

    return successResponse(res, 200, 'Platform statistics retrieved successfully', {
      users: {
        total: totalUsers,
        donors: totalDonors,
        ngos: totalNGOs,
        verifiedNGOs,
        pendingNGOs
      },
      donations: {
        total: totalDonations,
        available: availableDonations,
        claimed: claimedDonations,
        delivered: deliveredDonations,
        byCategory: categoryStats
      },
      recentActivity: {
        donations: recentDonations,
        users: recentUsers.map(sanitizeUser)
      }
    });
  } catch (error) {
    console.error('Get platform stats error:', error);
    return errorResponse(res, 500, 'Error fetching platform statistics', error.message);
  }
};

// Seed test data
const seedDatabase = async (req, res) => {
  try {
    const db = getDB();
    const bcrypt = require('bcryptjs');

    // Create test donor
    const donorPassword = await bcrypt.hash('password123', 10);
    const donor = await User.create(db, {
      email: 'donor@test.com',
      password: donorPassword,
      name: 'Test Donor',
      role: 'donor',
      phone: '+1234567890',
      verified: true,
      active: true,
      location: { lat: 40.7128, lng: -74.0060, address: 'New York, NY' }
    });

    // Create test NGO
    const ngoPassword = await bcrypt.hash('password123', 10);
    const ngo = await User.create(db, {
      email: 'ngo@test.com',
      password: ngoPassword,
      name: 'Test NGO',
      role: 'ngo',
      phone: '+1234567891',
      verified: true,
      active: true,
      location: { lat: 40.7580, lng: -73.9855, address: 'New York, NY' },
      ngoDetails: {
        registrationNumber: 'NGO12345',
        description: 'A test NGO dedicated to helping communities',
        verificationStatus: 'verified',
        categories: ['food', 'clothes'],
        establishedYear: 2020
      }
    });

    // Create test donations
    const donations = [
      {
        donorId: donor._id,
        title: 'Fresh Vegetables',
        description: 'Fresh vegetables from local farm',
        category: 'food',
        quantity: 50,
        unit: 'kg',
        condition: 'new',
        pickupLocation: { lat: 40.7128, lng: -74.0060, address: 'New York, NY' },
        status: 'available',
        priority: 'high'
      },
      {
        donorId: donor._id,
        title: 'Winter Clothes',
        description: 'Warm winter jackets and blankets',
        category: 'clothes',
        quantity: 100,
        unit: 'pieces',
        condition: 'good',
        pickupLocation: { lat: 40.7128, lng: -74.0060, address: 'New York, NY' },
        status: 'available',
        priority: 'normal'
      },
      {
        donorId: donor._id,
        title: 'Educational Books',
        description: 'Collection of textbooks and story books',
        category: 'books',
        quantity: 200,
        unit: 'pieces',
        condition: 'good',
        pickupLocation: { lat: 40.7128, lng: -74.0060, address: 'New York, NY' },
        status: 'available',
        priority: 'normal'
      }
    ];

    for (const donationData of donations) {
      await Donation.create(db, donationData);
    }

    return successResponse(res, 200, 'Test data seeded successfully', {
      donor: { email: 'donor@test.com', password: 'password123' },
      ngo: { email: 'ngo@test.com', password: 'password123' }
    });
  } catch (error) {
    console.error('Seed database error:', error);
    return errorResponse(res, 500, 'Error seeding database', error.message);
  }
};

module.exports = {
  getAllUsers,
  getPendingNGOs,
  verifyNGO,
  toggleUserStatus,
  deleteUser,
  getPlatformStats,
  seedDatabase
};

