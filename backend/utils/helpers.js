const bcrypt = require('bcryptjs');

// Hash password
const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(password, salt);
};

// Compare password
const comparePassword = async (password, hashedPassword) => {
  return await bcrypt.compare(password, hashedPassword);
};

// Calculate distance between two coordinates (Haversine formula)
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Radius of the Earth in kilometers
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;

  return distance; // Returns distance in kilometers
};

const toRadians = (degrees) => {
  return degrees * (Math.PI / 180);
};

// Pagination helper
const getPagination = (page = 1, limit = 10) => {
  const pageNum = parseInt(page);
  const limitNum = parseInt(limit);

  const skip = (pageNum - 1) * limitNum;

  return {
    skip,
    limit: limitNum,
    page: pageNum
  };
};

// Build pagination response
const buildPaginationResponse = (data, total, page, limit) => {
  const totalPages = Math.ceil(total / limit);

  return {
    data,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    }
  };
};

// Sanitize user object (remove sensitive fields)
const sanitizeUser = (user) => {
  if (!user) return null;

  const { password, ...sanitized } = user;
  return sanitized;
};

// Generate random string
const generateRandomString = (length = 32) => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

// Format date
const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

// Check if date is expired
const isExpired = (date) => {
  if (!date) return false;
  return new Date(date) < new Date();
};

// Build filter query for donations
const buildDonationFilter = (queryParams, userId = null, role = null) => {
  const filter = { active: true };

  // Category filter
  if (queryParams.category) {
    filter.category = queryParams.category;
  }

  // Status filter with DATA ISOLATION for claimed donations
  if (queryParams.status) {
    filter.status = queryParams.status;

    // ══════════════════════════════════════════════════════════════
    // DATA ISOLATION: NGOs only see their OWN claimed/in-transit/delivered
    // Like Zomato - restaurants only see their own orders in each status
    // ══════════════════════════════════════════════════════════════
    if (['claimed', 'in-transit', 'delivered'].includes(queryParams.status)) {
      if (role === 'ngo' && userId) {
        // NGO viewing claimed status should only see their own claims
        filter.claimedBy = userId;
      } else if (role === 'donor' && userId) {
        // Donors viewing claimed status should see their own donations
        filter.donorId = userId;
      }
      // Admins see everything (no additional filter)
    }
  }

  // Priority filter
  if (queryParams.priority) {
    filter.priority = queryParams.priority;
  }

  // Donor filter - ONLY when explicitly requesting own donations
  // This allows donors to browse all available donations
  if (queryParams.myDonations === 'true' && role === 'donor' && userId) {
    filter.donorId = userId;
  }

  // NGO claimed filter - for viewing donations they've claimed
  if (queryParams.claimed === 'true' && role === 'ngo' && userId) {
    filter.claimedBy = userId;
  }

  // Search by title/description
  if (queryParams.search) {
    filter.$or = [
      { title: { $regex: queryParams.search, $options: 'i' } },
      { description: { $regex: queryParams.search, $options: 'i' } }
    ];
  }

  return filter;
};

// Success response helper
const successResponse = (res, statusCode, message, data = null) => {
  const response = {
    success: true,
    message
  };

  if (data !== null) {
    response.data = data;
  }

  return res.status(statusCode).json(response);
};

// Error response helper
const errorResponse = (res, statusCode, message, errors = null) => {
  const response = {
    success: false,
    message
  };

  if (errors) {
    response.errors = errors;
  }

  return res.status(statusCode).json(response);
};

// ══════════════════════════════════════════════════════════════════════
// DATA ISOLATION HELPERS - Use these to ensure proper access control
// ══════════════════════════════════════════════════════════════════════

/**
 * Check if user owns or has access to a resource
 * @param {Object} resource - The resource to check
 * @param {Object} user - The user object (from req.user)
 * @param {Object} options - Options for the check
 * @returns {Object} { allowed: boolean, reason: string }
 */
const checkOwnership = (resource, user, options = {}) => {
  const {
    ownerField = 'donorId',
    allowClaimer = true,
    publicStatuses = ['available']
  } = options;

  // Admin can access everything
  if (user?.role === 'admin') {
    return { allowed: true, reason: 'admin' };
  }

  // Public resources
  if (publicStatuses.includes(resource?.status)) {
    return { allowed: true, reason: 'public' };
  }

  // Not authenticated
  if (!user) {
    return { allowed: false, reason: 'unauthenticated' };
  }

  // Owner check
  const ownerId = resource?.[ownerField]?.toString();
  if (ownerId === user.userId) {
    return { allowed: true, reason: 'owner' };
  }

  // Claimer check (for NGOs)
  if (allowClaimer && resource?.claimedBy?.toString() === user.userId) {
    return { allowed: true, reason: 'claimer' };
  }

  return { allowed: false, reason: 'not_authorized' };
};

/**
 * Build a secure filter that automatically adds ownership constraints
 * Use this for list queries to ensure users only see their own data
 * @param {Object} baseFilter - Base query filter
 * @param {Object} user - User object (from req.user)
 * @param {Object} options - Filter options
 * @returns {Object} Secure filter with ownership constraints
 */
const buildSecureFilter = (baseFilter, user, options = {}) => {
  const { ObjectId } = require('mongodb');
  const filter = { ...baseFilter };

  // Add active flag by default
  if (options.checkActive !== false) {
    filter.active = true;
  }

  // If ownership is required, add user filter
  if (options.requireOwnership && user) {
    if (user.role === 'donor') {
      filter.donorId = new ObjectId(user.userId);
    } else if (user.role === 'ngo') {
      const ngoField = options.ngoField || 'claimedBy';
      filter[ngoField] = new ObjectId(user.userId);
    }
    // Admins: no additional filter (see all)
  }

  // For claimed/in-transit/delivered, filter by role
  if (['claimed', 'in-transit', 'delivered'].includes(baseFilter.status)) {
    if (user?.role === 'ngo') {
      filter.claimedBy = new ObjectId(user.userId);
    } else if (user?.role === 'donor') {
      filter.donorId = new ObjectId(user.userId);
    }
  }

  return filter;
};

module.exports = {
  hashPassword,
  comparePassword,
  calculateDistance,
  getPagination,
  buildPaginationResponse,
  sanitizeUser,
  generateRandomString,
  formatDate,
  isExpired,
  buildDonationFilter,
  successResponse,
  errorResponse,
  // New data isolation helpers
  checkOwnership,
  buildSecureFilter
};

