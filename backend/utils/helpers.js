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
const sanitizeUser = (user, requester = null) => {
  if (!user) return null;

  const isOwner = requester && requester.userId === user._id?.toString();
  const isAdmin = requester && requester.role === 'admin';

  // Fields that are ALWAYS public
  const sanitized = {
    _id: user._id,
    id: user._id?.toString(),
    name: user.name,
    role: user.role,
    profileImage: user.profileImage,
    verified: user.verified,
    createdAt: user.createdAt
  };

  // Role-specific public fields
  if (user.role === 'ngo') {
    sanitized.ngoDetails = {
      description: user.ngoDetails?.description,
      website: user.ngoDetails?.website,
      categories: user.ngoDetails?.categories,
      establishedYear: user.ngoDetails?.establishedYear,
      verificationStatus: user.ngoDetails?.verificationStatus
    };
    
    if (isOwner || isAdmin) {
      sanitized.email = user.email;
      sanitized.phone = user.phone;
      sanitized.address = user.address;
      sanitized.location = user.location;
      sanitized.ngoDetails.registrationNumber = user.ngoDetails?.registrationNumber;
      sanitized.ngoDetails.documents = user.ngoDetails?.documents;
    }
  } else if (user.role === 'donor') {
    sanitized.donorStats = user.donorStats;
    sanitized.impactScore = user.impactScore;
    sanitized.badges = user.badges;

    if (isOwner || isAdmin) {
      sanitized.email = user.email;
      sanitized.phone = user.phone;
      sanitized.address = user.address;
      sanitized.location = user.location;
      sanitized.bookmarks = user.bookmarks;
    }
  }

  return sanitized;
};

// Sanitize donation object
const sanitizeDonation = (donation) => {
  if (!donation) return null;
  
  const sanitized = {
    ...donation,
    id: donation._id?.toString(),
    donorId: donation.donorId?.toString(),
    claimedBy: donation.claimedBy?.toString()
  };
  
  if (sanitized.donor && sanitized.donor._id) {
    sanitized.donor.id = sanitized.donor._id.toString();
  }
  
  if (sanitized.ngo && sanitized.ngo._id) {
    sanitized.ngo.id = sanitized.ngo._id.toString();
  }
  
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

  // Status filter with DATA ISOLATION
  if (queryParams.status) {
    // If requesting a restricted status, verify permission
    if (['claimed', 'in-transit', 'delivered', 'cancelled'].includes(queryParams.status)) {
      if (role === 'admin') {
        filter.status = queryParams.status;
      } else if (role === 'ngo' && userId) {
        filter.status = queryParams.status;
        filter.claimedBy = userId;
      } else if (role === 'donor' && userId) {
        filter.status = queryParams.status;
        filter.donorId = userId;
      } else {
        // Public or mismatched user: Force back to 'available' for privacy
        filter.status = 'available';
      }
    } else {
      filter.status = queryParams.status;
    }
  } else {
    // DEFAULT: Only show available donations for browsing
    // Unless explicitly looking at "my" donations via other flags
    if (queryParams.myDonations !== 'true' && queryParams.claimed !== 'true') {
      filter.status = 'available';
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

  // Search by title/description (Ensure it's a string)
  if (queryParams.search && typeof queryParams.search === 'string') {
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

/**
 * Sanitizes a request object for frontend use
 * @param {Object} request - The request object to sanitize
 * @returns {Object} Sanitized request
 */
const sanitizeRequest = (request) => {
  if (!request) return null;
  const sanitized = { ...request };
  
  if (sanitized._id) sanitized.id = sanitized._id.toString();
  if (sanitized.ngoId) sanitized.ngoId = sanitized.ngoId.toString();
  if (sanitized.donationId) sanitized.donationId = sanitized.donationId.toString();
  
  // Sanitize nested objects if they exist
  if (sanitized.ngo) sanitized.ngo = sanitizeUser(sanitized.ngo);
  if (sanitized.donation) sanitized.donation = sanitizeDonation(sanitized.donation);
  
  return sanitized;
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
  sanitizeDonation,
  sanitizeRequest,
  successResponse,
  errorResponse,
  // New data isolation helpers
  checkOwnership,
  buildSecureFilter
};
