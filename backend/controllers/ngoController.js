const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const User = require('../models/User');
const Request = require('../models/Request');
const Notification = require('../models/Notification');
const {
  getPagination,
  buildPaginationResponse,
  sanitizeUser,
  successResponse,
  errorResponse
} = require('../utils/helpers');

// Get all verified NGOs
const getNGOs = async (req, res) => {
  try {
    const { page = 1, limit = 10, search, category } = req.query;
    const { skip, limit: limitNum } = getPagination(page, limit);

    const db = getDB();

    // Build filter
    const filter = {
      role: 'ngo',
      active: true,
      verified: true,
      'ngoDetails.verificationStatus': 'verified'
    };

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { 'ngoDetails.description': { $regex: search, $options: 'i' } }
      ];
    }

    if (category) {
      filter['ngoDetails.categories'] = category;
    }

    const ngos = await User.findAll(db, filter, {
      skip,
      limit: limitNum,
      sort: { createdAt: -1 }
    });

    // Sanitize user data
    const sanitizedNGOs = ngos.map(sanitizeUser);

    const total = await User.count(db, filter);

    return successResponse(
      res,
      200,
      'NGOs retrieved successfully',
      buildPaginationResponse(sanitizedNGOs, total, page, limitNum)
    );
  } catch (error) {
    console.error('Get NGOs error:', error);
    return errorResponse(res, 500, 'Error fetching NGOs', error.message);
  }
};

// Get NGO by ID
const getNGOById = async (req, res) => {
  try {
    const { id } = req.params;

    const db = getDB();
    const ngo = await User.findById(db, id);

    if (!ngo || ngo.role !== 'ngo') {
      return errorResponse(res, 404, 'NGO not found');
    }

    return successResponse(res, 200, 'NGO retrieved successfully', {
      ngo: sanitizeUser(ngo)
    });
  } catch (error) {
    console.error('Get NGO by ID error:', error);
    return errorResponse(res, 500, 'Error fetching NGO', error.message);
  }
};

// Create a request for donation
const createRequest = async (req, res) => {
  try {
    if (req.user.role !== 'ngo') {
      return errorResponse(res, 403, 'Only NGOs can create requests');
    }

    const { donationId, message, needByDate, beneficiariesCount, priority } = req.body;

    const db = getDB();

    // Check if NGO is verified
    const ngo = await User.findById(db, req.user.userId);
    if (!ngo.verified || ngo.ngoDetails?.verificationStatus !== 'verified') {
      return errorResponse(res, 403, 'Your NGO must be verified to create requests');
    }

    // Check if donation exists
    const donation = await db.collection('donations').findOne({
      _id: new ObjectId(donationId)
    });

    if (!donation) {
      return errorResponse(res, 404, 'Donation not found');
    }

    if (donation.status !== 'available') {
      return errorResponse(res, 400, 'This donation is not available');
    }

    // Check if request already exists
    const existingRequest = await db.collection('requests').findOne({
      ngoId: new ObjectId(req.user.userId),
      donationId: new ObjectId(donationId),
      status: 'pending'
    });

    if (existingRequest) {
      return errorResponse(res, 400, 'You have already requested this donation');
    }

    const requestData = {
      ngoId: req.user.userId,
      donationId,
      message,
      needByDate,
      beneficiariesCount,
      priority: priority || 'normal'
    };

    const request = await Request.create(db, requestData);

    // Create notification for donor
    await Notification.create(db, {
      userId: donation.donorId,
      title: 'New Donation Request',
      message: `${ngo.name} has requested your donation "${donation.title}"`,
      type: 'request',
      relatedId: request._id,
      relatedType: 'request',
      priority: 'normal'
    });

    return successResponse(res, 201, 'Request created successfully', { request });
  } catch (error) {
    console.error('Create request error:', error);
    return errorResponse(res, 500, 'Error creating request', error.message);
  }
};

// Get all requests
const getRequests = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const { skip, limit: limitNum } = getPagination(page, limit);

    const db = getDB();

    // Build filter based on user role
    let filter = {};

    if (req.user.role === 'ngo') {
      filter.ngoId = new ObjectId(req.user.userId);
    } else if (req.user.role === 'donor') {
      // For donors, show requests for their donations
      const donations = await db.collection('donations').find({
        donorId: new ObjectId(req.user.userId)
      }).toArray();

      const donationIds = donations.map(d => d._id);
      filter.donationId = { $in: donationIds };
    }

    if (status) {
      filter.status = status;
    }

    const requests = await Request.findWithDetails(db, filter, {
      skip,
      limit: limitNum,
      sort: { createdAt: -1 }
    });

    const total = await Request.count(db, filter);

    return successResponse(
      res,
      200,
      'Requests retrieved successfully',
      buildPaginationResponse(requests, total, page, limitNum)
    );
  } catch (error) {
    console.error('Get requests error:', error);
    return errorResponse(res, 500, 'Error fetching requests', error.message);
  }
};

// Update request status (for donors)
const updateRequestStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, response } = req.body;

    const db = getDB();

    const requestDoc = await Request.findById(db, id);
    if (!requestDoc) {
      return errorResponse(res, 404, 'Request not found');
    }

    // Check if user is the donor of the related donation
    const donation = await db.collection('donations').findOne({
      _id: requestDoc.donationId
    });

    if (!donation) {
      return errorResponse(res, 404, 'Related donation not found');
    }

    if (donation.donorId.toString() !== req.user.userId && req.user.role !== 'admin') {
      return errorResponse(res, 403, 'You do not have permission to update this request');
    }

    // Update request
    const updated = await Request.updateStatus(db, id, status, response);

    if (!updated) {
      return errorResponse(res, 400, 'Failed to update request');
    }

    // If approved, claim the donation
    if (status === 'approved') {
      await db.collection('donations').updateOne(
        { _id: donation._id },
        {
          $set: {
            status: 'claimed',
            claimedBy: requestDoc.ngoId,
            claimedAt: new Date(),
            updatedAt: new Date()
          }
        }
      );

      // Reject other pending requests for this donation
      await db.collection('requests').updateMany(
        {
          donationId: donation._id,
          _id: { $ne: new ObjectId(id) },
          status: 'pending'
        },
        {
          $set: {
            status: 'rejected',
            response: 'Donation was approved for another NGO',
            respondedAt: new Date(),
            updatedAt: new Date()
          }
        }
      );
    }

    // Create notification for NGO
    const ngo = await User.findById(db, requestDoc.ngoId.toString());
    await Notification.create(db, {
      userId: requestDoc.ngoId,
      title: `Request ${status.charAt(0).toUpperCase() + status.slice(1)}`,
      message: `Your request for "${donation.title}" has been ${status}`,
      type: 'request',
      relatedId: id,
      relatedType: 'request',
      priority: status === 'approved' ? 'high' : 'normal'
    });

    const updatedRequest = await Request.findById(db, id);

    return successResponse(res, 200, 'Request status updated successfully', { request: updatedRequest });
  } catch (error) {
    console.error('Update request status error:', error);
    return errorResponse(res, 500, 'Error updating request status', error.message);
  }
};

// Cancel request (NGO can cancel their own request)
const cancelRequest = async (req, res) => {
  try {
    const { id } = req.params;

    const db = getDB();

    const requestDoc = await Request.findById(db, id);
    if (!requestDoc) {
      return errorResponse(res, 404, 'Request not found');
    }

    if (requestDoc.ngoId.toString() !== req.user.userId && req.user.role !== 'admin') {
      return errorResponse(res, 403, 'You do not have permission to cancel this request');
    }

    if (requestDoc.status !== 'pending') {
      return errorResponse(res, 400, 'Only pending requests can be cancelled');
    }

    const updated = await Request.updateStatus(db, id, 'cancelled');

    if (!updated) {
      return errorResponse(res, 400, 'Failed to cancel request');
    }

    return successResponse(res, 200, 'Request cancelled successfully');
  } catch (error) {
    console.error('Cancel request error:', error);
    return errorResponse(res, 500, 'Error cancelling request', error.message);
  }
};

module.exports = {
  getNGOs,
  getNGOById,
  createRequest,
  getRequests,
  updateRequestStatus,
  cancelRequest
};

