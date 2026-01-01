/**
 * Response Sanitizer Utility
 * Automatically removes sensitive fields from API responses
 * Prevents accidental data leakage to unauthorized users
 */

/**
 * Sensitive fields configuration per resource type
 * These fields are hidden from non-owners
 */
const SENSITIVE_FIELDS = {
    donation: {
        // Fields hidden from non-owner/non-claimer
        private: ['deliveryNotes', 'deliveryImages', 'internalNotes'],
        // Fields hidden only when user is neither owner nor claimer
        claimDetails: ['claimedBy', 'claimedByDetails', 'claimedAt', 'deliveryDate']
    },
    user: {
        // Never expose these
        private: ['password', 'refreshToken', 'resetPasswordToken', 'resetPasswordExpires']
    },
    request: {
        private: ['internalNotes', 'adminComments']
    }
};

/**
 * Sanitize a single donation object
 * @param {Object} donation - The donation to sanitize
 * @param {Object} viewer - The user viewing (req.user)
 * @returns {Object} Sanitized donation
 */
const sanitizeDonation = (donation, viewer) => {
    if (!donation) return donation;

    // Create a copy to avoid mutating original
    const sanitized = { ...donation };

    // Determine viewer's relationship to donation
    const isOwner = donation.donorId?.toString() === viewer?.userId;
    const isClaimer = donation.claimedBy?.toString() === viewer?.userId;
    const isAdmin = viewer?.role === 'admin';
    const hasAccess = isOwner || isClaimer || isAdmin;

    // If donation is available, everyone can see basic info
    if (donation.status === 'available') {
        // Only hide truly private fields
        SENSITIVE_FIELDS.donation.private.forEach(field => {
            delete sanitized[field];
        });
        return sanitized;
    }

    // For claimed/in-transit/delivered donations
    if (!hasAccess) {
        // Hide claim-related details from non-participants
        SENSITIVE_FIELDS.donation.claimDetails.forEach(field => {
            delete sanitized[field];
        });
        SENSITIVE_FIELDS.donation.private.forEach(field => {
            delete sanitized[field];
        });

        // Add indicator that it's claimed but by someone else
        sanitized.claimStatus = 'claimed_by_other';
    }

    return sanitized;
};

/**
 * Sanitize a list of donations
 * @param {Array} donations - Array of donations
 * @param {Object} viewer - The user viewing
 * @returns {Array} Sanitized donations
 */
const sanitizeDonations = (donations, viewer) => {
    if (!Array.isArray(donations)) return donations;
    return donations.map(d => sanitizeDonation(d, viewer));
};

/**
 * Sanitize a user object (remove sensitive auth fields)
 * @param {Object} user - The user to sanitize
 * @returns {Object} Sanitized user
 */
const sanitizeUser = (user) => {
    if (!user) return user;

    const sanitized = { ...user };
    SENSITIVE_FIELDS.user.private.forEach(field => {
        delete sanitized[field];
    });

    return sanitized;
};

/**
 * Sanitize a request object
 * @param {Object} request - The request to sanitize
 * @param {Object} viewer - The user viewing
 * @returns {Object} Sanitized request
 */
const sanitizeRequest = (request, viewer) => {
    if (!request) return request;

    const sanitized = { ...request };
    const isOwner = request.ngoId?.toString() === viewer?.userId;
    const isDonor = request.donationId?.donorId?.toString() === viewer?.userId;
    const isAdmin = viewer?.role === 'admin';

    if (!isOwner && !isDonor && !isAdmin) {
        SENSITIVE_FIELDS.request.private.forEach(field => {
            delete sanitized[field];
        });
    }

    return sanitized;
};

/**
 * Generic sanitizer for any resource type
 * @param {Object|Array} data - Data to sanitize
 * @param {string} resourceType - Type of resource ('donation', 'user', 'request')
 * @param {Object} viewer - The user viewing
 * @returns {Object|Array} Sanitized data
 */
const sanitize = (data, resourceType, viewer) => {
    if (!data) return data;

    const sanitizers = {
        donation: sanitizeDonation,
        donations: (d, v) => sanitizeDonations(d, v),
        user: sanitizeUser,
        request: sanitizeRequest
    };

    const sanitizer = sanitizers[resourceType];
    if (!sanitizer) return data;

    if (Array.isArray(data)) {
        return data.map(item => sanitizer(item, viewer));
    }

    return sanitizer(data, viewer);
};

module.exports = {
    sanitize,
    sanitizeDonation,
    sanitizeDonations,
    sanitizeUser,
    sanitizeRequest,
    SENSITIVE_FIELDS
};
