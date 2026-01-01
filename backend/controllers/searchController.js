const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const Donation = require('../models/Donation');
const User = require('../models/User');
const { getPagination, buildPaginationResponse, successResponse, errorResponse } = require('../utils/helpers');

// Advanced search for donations
const searchDonations = async (req, res) => {
  try {
    const { 
      q,                    // search query
      category, 
      status, 
      priority,
      minQuantity,
      maxQuantity,
      location,             // location search
      radius = 50,          // radius in km
      page = 1, 
      limit = 10 
    } = req.query;

    const { skip, limit: limitNum } = getPagination(page, limit);
    const db = getDB();

    // Build search filter
    const filter = { active: true };

    // Text search
    if (q) {
      filter.$or = [
        { title: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { tags: { $in: [new RegExp(q, 'i')] } }
      ];
    }

    // Category filter
    if (category) {
      filter.category = category;
    }

    // Status filter
    if (status) {
      filter.status = status;
    }

    // Priority filter
    if (priority) {
      filter.priority = priority;
    }

    // Quantity range
    if (minQuantity || maxQuantity) {
      filter.quantity = {};
      if (minQuantity) filter.quantity.$gte = parseInt(minQuantity);
      if (maxQuantity) filter.quantity.$lte = parseInt(maxQuantity);
    }

    // Location-based search
    if (location) {
      const [lat, lng] = location.split(',').map(parseFloat);
      // Note: For production, implement proper geospatial queries
      filter['pickupLocation.lat'] = { $exists: true };
      filter['pickupLocation.lng'] = { $exists: true };
    }

    const donations = await Donation.findWithDonorDetails(db, filter, {
      skip,
      limit: limitNum,
      sort: { createdAt: -1 }
    });

    const total = await Donation.count(db, filter);

    return successResponse(
      res,
      200,
      'Search results retrieved successfully',
      buildPaginationResponse(donations, total, page, limitNum)
    );
  } catch (error) {
    console.error('Search donations error:', error);
    return errorResponse(res, 500, 'Error searching donations', error.message);
  }
};

// Search NGOs
const searchNGOs = async (req, res) => {
  try {
    const { q, category, page = 1, limit = 10 } = req.query;
    const { skip, limit: limitNum } = getPagination(page, limit);

    const db = getDB();

    const filter = {
      role: 'ngo',
      active: true,
      verified: true,
      'ngoDetails.verificationStatus': 'verified'
    };

    if (q) {
      filter.$or = [
        { name: { $regex: q, $options: 'i' } },
        { 'ngoDetails.description': { $regex: q, $options: 'i' } }
      ];
    }

    if (category) {
      filter['ngoDetails.categories'] = category;
    }

    const ngos = await User.findAll(db, filter, {
      skip,
      limit: limitNum,
      sort: { 'ngoDetails.establishedYear': -1 }
    });

    const total = await User.count(db, filter);

    return successResponse(
      res,
      200,
      'NGO search results',
      buildPaginationResponse(ngos, total, page, limitNum)
    );
  } catch (error) {
    console.error('Search NGOs error:', error);
    return errorResponse(res, 500, 'Error searching NGOs', error.message);
  }
};

// Get all available categories with counts
const getCategories = async (req, res) => {
  try {
    const db = getDB();

    const categories = await db.collection('donations').aggregate([
      { $match: { active: true, status: 'available' } },
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 },
          totalQuantity: { $sum: '$quantity' }
        }
      },
      { $sort: { count: -1 } }
    ]).toArray();

    const formattedCategories = categories.map(cat => ({
      name: cat._id,
      count: cat.count,
      totalQuantity: cat.totalQuantity
    }));

    return successResponse(res, 200, 'Categories retrieved successfully', {
      categories: formattedCategories,
      total: categories.length
    });
  } catch (error) {
    console.error('Get categories error:', error);
    return errorResponse(res, 500, 'Error fetching categories', error.message);
  }
};

module.exports = {
  searchDonations,
  searchNGOs,
  getCategories
};

