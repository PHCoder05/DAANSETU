const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const Donation = require('../models/Donation');
const Request = require('../models/Request');
const Notification = require('../models/Notification');
const User = require('../models/User');
const ReceiptService = require('../services/receiptService');
const {
  getPagination,
  buildPaginationResponse,
  buildDonationFilter,
  sanitizeDonation,
  successResponse,
  errorResponse
} = require('../utils/helpers');

// Create a new donation
const createDonation = async (req, res) => {
  try {
    if (req.user.role !== 'donor') {
      return errorResponse(res, 403, 'Only donors can create donations');
    }

    const donationData = {
      ...req.body,
      donorId: req.user.userId
    };

    const db = getDB();
    const donation = await Donation.create(db, donationData);

    // Update donor stats
    await User.update(db, req.user.userId, {
      'donorStats.totalDonations': { $inc: 1 },
      'donorStats.activeDonations': { $inc: 1 }
    });

    return successResponse(res, 201, 'Donation created successfully', { 
      donation: sanitizeDonation(donation) 
    });
  } catch (error) {
    console.error('Create donation error:', error);
    return errorResponse(res, 500, 'Error creating donation', error.message);
  }
};

// Get all donations with filters
const getDonations = async (req, res) => {
  try {
    const { page = 1, limit = 10, category, status, priority, search, lat, lng, radius } = req.query;
    const { skip, limit: limitNum } = getPagination(page, limit);

    const db = getDB();

    // Build filter
    const filter = buildDonationFilter(req.query, req.user?.userId, req.user?.role);

    // Handle 'saved' filter
    if (req.query.saved === 'true' && req.user?.userId) {
      const user = await User.findById(db, req.user.userId);
      if (user && user.bookmarks && user.bookmarks.length > 0) {
        const bookmarkIds = user.bookmarks
          .filter(id => ObjectId.isValid(id))
          .map(id => new ObjectId(id));

        if (bookmarkIds.length > 0) {
          filter._id = { $in: bookmarkIds };
        } else {
          return successResponse(res, 200, 'No saved donations found', buildPaginationResponse([], 0, page, limitNum));
        }
      } else {
        return successResponse(res, 200, 'No saved donations found', buildPaginationResponse([], 0, page, limitNum));
      }
    }

    // Get donations with donor details
    const options = {
      skip,
      limit: limitNum,
      sort: { createdAt: -1 }
    };

    // Add geo search options if coordinates provided
    if (lat && lng) {
      options.near = {
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        radius: radius ? parseFloat(radius) * 1000 : 50000 // default 50km
      };
    }

    const donations = await Donation.findWithDonorDetails(db, filter, options);

    const total = await Donation.count(db, filter);

    return successResponse(
      res,
      200,
      'Donations retrieved successfully',
      buildPaginationResponse(donations.map(sanitizeDonation), total, page, limitNum)
    );
  } catch (error) {
    console.error('Get donations error:', error);
    return errorResponse(res, 500, 'Error fetching donations', error.message);
  }
};

// Get donation by ID
const getDonationById = async (req, res) => {
  try {
    const { id } = req.params;

    const db = getDB();
    const donations = await Donation.findWithDonorDetails(db, {
      _id: new ObjectId(id)
    });

    if (!donations || donations.length === 0 || !donations[0].active) {
      return errorResponse(res, 404, 'Donation not found');
    }

    const donation = donations[0];

    // Increment views
    await Donation.incrementViews(db, id);

    // ══════════════════════════════════════════════════════════════
    // DATA ISOLATION: Apply role-based visibility restrictions
    // Like Zomato - only show claim details to relevant participants
    // ══════════════════════════════════════════════════════════════
    let visibleDonation = { ...donation };

    if (req.user) {
      const isDonor = donation.donorId && donation.donorId.toString() === req.user.userId;
      const isClaimedNGO = donation.claimedBy && donation.claimedBy.toString() === req.user.userId;
      const isAdmin = req.user.role === 'admin';

      // If user is NOT the donor, the claiming NGO, or an admin - hide sensitive info
      if (!isDonor && !isClaimedNGO && !isAdmin) {
        // For claimed/in-transit/delivered donations, hide claimant details from others
        if (donation.status !== 'available') {
          visibleDonation = {
            ...visibleDonation,
            claimedBy: undefined,
            claimedByDetails: undefined,
            deliveryNotes: undefined,
            deliveryImages: undefined,
            deliveryDate: undefined,
            // Show that it's claimed but not by whom
            claimStatus: 'claimed_by_other'
          };
        }
      }
    } else {
      // Public/unauthenticated access - hide all claim-related info
      if (donation.status !== 'available') {
        visibleDonation = {
          ...visibleDonation,
          claimedBy: undefined,
          claimedByDetails: undefined,
          deliveryNotes: undefined,
          deliveryImages: undefined,
          deliveryDate: undefined
        };
      }
    }

    return successResponse(res, 200, 'Donation retrieved successfully', { 
      donation: sanitizeDonation(visibleDonation) 
    });
  } catch (error) {
    console.error('Get donation by ID error:', error);
    return errorResponse(res, 500, 'Error fetching donation', error.message);
  }
};

// Update donation
const updateDonation = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const db = getDB();

    // Check if donation exists and belongs to user
    const donation = await Donation.findById(db, id);
    if (!donation) {
      return errorResponse(res, 404, 'Donation not found');
    }

    if (donation.donorId.toString() !== req.user.userId && req.user.role !== 'admin') {
      return errorResponse(res, 403, 'You do not have permission to update this donation');
    }

    // Don't allow status changes through this endpoint
    delete updateData.status;
    delete updateData.claimedBy;
    delete updateData.donorId;

    const updated = await Donation.update(db, id, updateData);

    if (!updated) {
      return errorResponse(res, 404, 'Donation not found or no changes made');
    }

    const updatedDonation = await Donation.findById(db, id);

    return successResponse(res, 200, 'Donation updated successfully', { 
      donation: sanitizeDonation(updatedDonation) 
    });
  } catch (error) {
    console.error('Update donation error:', error);
    return errorResponse(res, 500, 'Error updating donation', error.message);
  }
};

// Delete donation
const deleteDonation = async (req, res) => {
  try {
    const { id } = req.params;

    const db = getDB();

    // Check if donation exists and belongs to user
    const donation = await Donation.findById(db, id);
    if (!donation) {
      return errorResponse(res, 404, 'Donation not found');
    }

    if (donation.donorId.toString() !== req.user.userId && req.user.role !== 'admin') {
      return errorResponse(res, 403, 'You do not have permission to delete this donation');
    }

    // Check if donation is claimed
    if (donation.status === 'claimed' || donation.status === 'in-transit') {
      return errorResponse(res, 400, 'Cannot delete a donation that is already claimed or in transit');
    }

    const deleted = await Donation.delete(db, id);

    if (!deleted) {
      return errorResponse(res, 404, 'Donation not found');
    }

    return successResponse(res, 200, 'Donation deleted successfully');
  } catch (error) {
    console.error('Delete donation error:', error);
    return errorResponse(res, 500, 'Error deleting donation', error.message);
  }
};

// Claim a donation (NGO only)
const claimDonation = async (req, res) => {
  try {
    if (req.user.role !== 'ngo' && req.user.role !== 'volunteer') {
      return errorResponse(res, 403, 'Only NGOs and Volunteers can claim donations');
    }

    const { id } = req.params;
    const db = getDB();

    // If NGO, check verification
    if (req.user.role === 'ngo') {
      const ngo = await User.findById(db, req.user.userId);
      if (!ngo.verified || ngo.ngoDetails?.verificationStatus !== 'verified') {
        return errorResponse(res, 403, 'Your NGO must be verified to claim donations');
      }
    }

    // Check if donation exists and is available
    const donation = await Donation.findById(db, id);
    if (!donation) {
      return errorResponse(res, 404, 'Donation not found');
    }

    if (donation.status !== 'available') {
      return errorResponse(res, 400, 'This donation is no longer available');
    }

    // Claim the donation
    const claimed = await Donation.claim(db, id, req.user.userId);

    if (!claimed) {
      return errorResponse(res, 400, 'Failed to claim donation');
    }

    // Fetch user details for notification
    const claimant = await User.findById(db, req.user.userId);
    
    // Create notification for donor
    await Notification.create(db, {
      userId: donation.donorId,
      title: 'Donation Claimed!',
      message: `Great news! Your donation "${donation.title}" has been claimed by ${claimant.name}.`,
      type: 'claim',
      relatedId: id,
      relatedType: 'donation',
      priority: 'high'
    });

    const updatedDonation = await Donation.findById(db, id);

    return successResponse(res, 200, 'Donation claimed successfully', { 
      donation: sanitizeDonation(updatedDonation) 
    });
  } catch (error) {
    console.error('Claim donation error:', error);
    return errorResponse(res, 500, 'Error claiming donation', error.message);
  }
};

// Update donation status
const updateDonationStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, deliveryNotes, deliveryImages } = req.body;

    const db = getDB();
    const donation = await Donation.findById(db, id);

    if (!donation) {
      return errorResponse(res, 404, 'Donation not found');
    }

    // Check permissions
    const isDonor = donation.donorId.toString() === req.user.userId;
    const isClaimedNGO = donation.claimedBy && donation.claimedBy.toString() === req.user.userId;
    const isAdmin = req.user.role === 'admin';

    if (!isDonor && !isClaimedNGO && !isAdmin) {
      return errorResponse(res, 403, 'You do not have permission to update this donation status');
    }

    // Validate status transitions
    const validTransitions = {
      'available': ['claimed', 'cancelled'],
      'claimed': ['in-transit', 'available', 'cancelled'],
      'in-transit': ['delivered', 'claimed'],
      'delivered': [],
      'cancelled': []
    };

    if (!validTransitions[donation.status]?.includes(status)) {
      return errorResponse(res, 400, `Cannot change status from ${donation.status} to ${status}`);
    }

    const additionalData = {};
    if (status === 'delivered') {
      additionalData.deliveryDate = new Date();
      if (deliveryNotes) additionalData.deliveryNotes = deliveryNotes;
      if (deliveryImages) additionalData.deliveryImages = deliveryImages;
    }

    const updated = await Donation.updateStatus(db, id, status, additionalData);

    if (!updated) {
      return errorResponse(res, 400, 'Failed to update donation status');
    }

    // Create notifications
    if (status === 'in-transit') {
      await Notification.create(db, {
        userId: donation.donorId,
        title: 'Donation In Transit',
        message: `Your donation "${donation.title}" is now in transit`,
        type: 'delivery',
        relatedId: id,
        relatedType: 'donation'
      });
    } else if (status === 'delivered') {
      await Notification.create(db, {
        userId: donation.donorId,
        title: 'Donation Delivered',
        message: `Your donation "${donation.title}" has been successfully delivered`,
        type: 'delivery',
        relatedId: id,
        relatedType: 'donation',
        priority: 'high'
      });

      // Update donor stats and impact score
      await User.update(db, donation.donorId.toString(), {
        $inc: {
          'donorStats.activeDonations': -1,
          'donorStats.completedDonations': 1,
          'impactScore': 10
        }
      });

      // BADGE LOGIC 🏆
      try {
        const donor = await User.findById(db, donation.donorId.toString());
        const completed = donor.donorStats.completedDonations;
        let newBadge = null;

        if (completed === 1) {
          newBadge = { id: 'first_step', name: 'First Step', icon: '🌟', description: 'Made your first donation!', awardedAt: new Date() };
        } else if (completed === 5) {
          newBadge = { id: 'helping_hand', name: 'Helping Hand', icon: '🤝', description: 'Completed 5 donations', awardedAt: new Date() };
        } else if (completed === 10) {
          newBadge = { id: 'community_hero', name: 'Community Hero', icon: '🦸‍♂️', description: 'Completed 10 donations', awardedAt: new Date() };
        } else if (completed === 25) {
          newBadge = { id: 'legend', name: 'Legend', icon: '🏆', description: 'Completed 25 donations', awardedAt: new Date() };
        }

        if (newBadge) {
          // Check if badge already exists (just in case)
          const hasBadge = donor.badges && donor.badges.some(b => b.id === newBadge.id);
          if (!hasBadge) {
            await db.collection('users').updateOne(
              { _id: new ObjectId(donation.donorId.toString()) },
              { $push: { badges: newBadge } }
            );

            // Notify user about new badge
            await Notification.create(db, {
              userId: donation.donorId,
              title: 'New Badge Unlocked! 🏆',
              message: `Congratulations! You've earned the "${newBadge.name}" badge.`,
              type: 'system',
              priority: 'high'
            });
          }
        }
      } catch (badgeError) {
        console.error('Error awarding badge:', badgeError);
        // Don't fail the request if badge logic fails
      }
    }

    const updatedDonation = await Donation.findById(db, id);

    return successResponse(res, 200, 'Donation status updated successfully', { 
      donation: sanitizeDonation(updatedDonation) 
    });
  } catch (error) {
    console.error('Update donation status error:', error);
    return errorResponse(res, 500, 'Error updating donation status', error.message);
  }
};

// Get nearby donations
const getNearbyDonations = async (req, res) => {
  try {
    const { lat, lng, maxDistance = 50 } = req.query;

    if (!lat || !lng) {
      return errorResponse(res, 400, 'Latitude and longitude are required');
    }

    const db = getDB();
    const donations = await Donation.findNearby(
      db,
      parseFloat(lat),
      parseFloat(lng),
      parseFloat(maxDistance) * 1000, // Convert to meters
      { limit: 20 }
    );

    return successResponse(res, 200, 'Nearby donations retrieved successfully', { donations });
  } catch (error) {
    console.error('Get nearby donations error:', error);
    return errorResponse(res, 500, 'Error fetching nearby donations', error.message);
  }
};

// Get donation statistics
const getDonationStats = async (req, res) => {
  try {
    const db = getDB();

    let filter = {};
    if (req.user.role === 'donor') {
      filter.donorId = new ObjectId(req.user.userId);
    } else if (req.user.role === 'ngo') {
      filter.claimedBy = new ObjectId(req.user.userId);
    }

    const stats = await db.collection('donations').aggregate([
      { $match: filter },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]).toArray();

    const categoryStats = await db.collection('donations').aggregate([
      { $match: filter },
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 }
        }
      }
    ]).toArray();

    return successResponse(res, 200, 'Statistics retrieved successfully', {
      statusStats: stats,
      categoryStats
    });
  } catch (error) {
    console.error('Get donation stats error:', error);
    return errorResponse(res, 500, 'Error fetching statistics', error.message);
  }
};

// Get donation timeline (history of status changes)
const getDonationTimeline = async (req, res) => {
  try {
    const { id } = req.params;
    const db = getDB();

    // Import DonationHistory (late import to avoid circular deps)
    const DonationHistory = require('../models/DonationHistory');

    // Check donation exists
    const donation = await Donation.findById(db, id);
    if (!donation) {
      return errorResponse(res, 404, 'Donation not found');
    }

    // ══════════════════════════════════════════════════════════════
    // DATA ISOLATION: Check if user has permission to see the timeline
    // ══════════════════════════════════════════════════════════════
    const isDonor = donation.donorId && donation.donorId.toString() === req.user.userId;
    const isClaimedNGO = donation.claimedBy && donation.claimedBy.toString() === req.user.userId;
    const isAdmin = req.user.role === 'admin';

    if (donation.status !== 'available' && !isDonor && !isClaimedNGO && !isAdmin) {
      return errorResponse(res, 403, 'You do not have permission to view the timeline for this donation');
    }

    // Get timeline
    const timeline = await DonationHistory.getTimeline(db, id);

    // If no history, create initial entry from donation data
    if (timeline.length === 0) {
      timeline.push({
        status: 'created',
        note: 'Donation created',
        createdAt: donation.createdAt,
        changedBy: { name: 'System', role: 'system' }
      });
    }

    return successResponse(res, 200, 'Timeline retrieved', { timeline, currentStatus: donation.status });
  } catch (error) {
    console.error('Get donation timeline error:', error);
    return errorResponse(res, 500, 'Error fetching timeline', error.message);
  }
};

// Get my donations (as donor or NGO)
const getMyDonations = async (req, res) => {
  try {
    const { role, type = 'all' } = req.query;
    const userId = req.user.userId;
    const db = getDB();

    let filter = {};

    if (role === 'donor' || req.user.role === 'donor') {
      // Donations I created
      filter.donorId = new ObjectId(userId);
    } else if (role === 'ngo' || req.user.role === 'ngo' || req.user.role === 'volunteer') {
      // Donations I claimed (as NGO or Volunteer)
      filter.claimedBy = new ObjectId(userId);
    }

    // Filter by type
    if (type === 'active') {
      filter.status = { $in: ['available', 'claimed', 'in-transit'] };
    } else if (type === 'completed') {
      filter.status = 'delivered';
    } else if (type === 'expired') {
      filter.status = 'expired';
    }

    const donations = await Donation.findWithDonorDetails(db, filter, {
      sort: { createdAt: -1 }
    });

    return successResponse(res, 200, 'Donations retrieved', { 
      donations: donations.map(sanitizeDonation) 
    });
  } catch (error) {
    console.error('Get my donations error:', error);
    return errorResponse(res, 500, 'Error fetching donations', error.message);
  }
};

// Get tax receipt PDF
const getDonationReceipt = async (req, res) => {
  try {
    const { id } = req.params;
    const db = getDB();

    const donation = await Donation.findById(db, id);
    if (!donation) {
      return errorResponse(res, 404, 'Donation not found');
    }

    // Authorization: Only donor or admin can download receipt
    if (donation.donorId.toString() !== req.user.userId && req.user.role !== 'admin') {
      return errorResponse(res, 403, 'You do not have permission to download this receipt');
    }

    const pdfBuffer = await ReceiptService.generateDonationReceipt(db, id);

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=receipt-${id}.pdf`);
    res.send(pdfBuffer);
  } catch (error) {
    console.error('Generate receipt error:', error);
    return errorResponse(res, 500, 'Error generating receipt', error.message);
  }
};

module.exports = {
  createDonation,
  getDonations,
  getDonationById,
  updateDonation,
  deleteDonation,
  claimDonation,
  updateDonationStatus,
  getNearbyDonations,
  getDonationStats,
  getDonationTimeline,
  getMyDonations,
  getDonationReceipt
};
