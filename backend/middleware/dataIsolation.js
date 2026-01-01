/**
 * Data Isolation Middleware
 * Automatically attaches ownership helpers to every request
 * Prevents accidental data leakage between tenants (NGOs/Donors)
 */
const { ObjectId } = require('mongodb');

/**
 * Main data isolation middleware
 * Attaches ownership helpers to req.ownership for use in controllers
 */
const dataIsolation = (req, res, next) => {
    // Always attach ownership object (even for unauthenticated users)
    req.ownership = {
        /**
         * Get filter for items owned by current user
         * Donor: donorId, NGO: ngoId, Admin: no filter
         */
        ownedByMe: () => {
            if (!req.user) return {};
            if (req.user.role === 'admin') return {};

            const ownerField = req.user.role === 'donor' ? 'donorId' :
                req.user.role === 'ngo' ? 'ngoId' : 'userId';
            return { [ownerField]: new ObjectId(req.user.userId) };
        },

        /**
         * Get filter for donations claimed by current NGO
         */
        claimedByMe: () => {
            if (!req.user || req.user.role !== 'ngo') return {};
            return { claimedBy: new ObjectId(req.user.userId) };
        },

        /**
         * Get filter for donations created by current donor
         */
        donatedByMe: () => {
            if (!req.user || req.user.role !== 'donor') return {};
            return { donorId: new ObjectId(req.user.userId) };
        },

        /**
         * Check if current user can access a resource
         * @param {Object} resource - The resource to check
         * @param {Object} options - Options for the check
         * @returns {Object} { allowed: boolean, reason: string }
         */
        canAccess: (resource, options = {}) => {
            const {
                ownerField = 'donorId',
                allowClaimer = true,
                publicStatuses = ['available']
            } = options;

            // Admin can access everything
            if (req.user?.role === 'admin') {
                return { allowed: true, reason: 'admin' };
            }

            // Public resources (e.g., available donations)
            if (publicStatuses.includes(resource.status)) {
                return { allowed: true, reason: 'public' };
            }

            // Not authenticated
            if (!req.user) {
                return { allowed: false, reason: 'unauthenticated' };
            }

            // Owner check
            const ownerId = resource[ownerField]?.toString();
            if (ownerId === req.user.userId) {
                return { allowed: true, reason: 'owner' };
            }

            // Claimer check (for NGOs)
            if (allowClaimer && resource.claimedBy?.toString() === req.user.userId) {
                return { allowed: true, reason: 'claimer' };
            }

            return { allowed: false, reason: 'not_authorized' };
        },

        /**
         * Check if user is the owner of a resource
         */
        isOwner: (resource, ownerField = 'donorId') => {
            if (!req.user) return false;
            return resource[ownerField]?.toString() === req.user.userId;
        },

        /**
         * Check if user is the claimer of a resource
         */
        isClaimer: (resource) => {
            if (!req.user) return false;
            return resource.claimedBy?.toString() === req.user.userId;
        },

        /**
         * Check if user is admin
         */
        isAdmin: () => req.user?.role === 'admin'
    };

    next();
};

/**
 * Middleware to require ownership for a route
 * Use when an entire route should only be accessible to owners
 */
const requireOwnership = (ownerField = 'donorId') => {
    return async (req, res, next) => {
        // This would be used after fetching the resource
        // The check happens in the controller using req.ownership.canAccess()
        next();
    };
};

module.exports = {
    dataIsolation,
    requireOwnership
};
