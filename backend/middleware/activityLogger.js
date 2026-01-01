const { getDB } = require('../config/db');
const ActivityLog = require('../models/ActivityLog');

/**
 * Activity Logging Middleware
 * Automatically logs user actions for audit trail
 */

// Helper to extract client info
const getClientInfo = (req) => ({
    ip: req.ip || req.headers['x-forwarded-for'] || req.connection?.remoteAddress,
    userAgent: req.headers['user-agent']
});

/**
 * Log successful login
 */
const logLogin = async (req, userId, success = true, reason = null) => {
    try {
        const db = getDB();
        const { ip, userAgent } = getClientInfo(req);
        await ActivityLog.logLogin(db, userId, { ip, userAgent, success, reason });
    } catch (e) {
        console.error('Failed to log login:', e);
    }
};

/**
 * Log logout
 */
const logLogout = async (req, userId) => {
    try {
        const db = getDB();
        const { ip, userAgent } = getClientInfo(req);
        await ActivityLog.logLogout(db, userId, { ip, userAgent });
    } catch (e) {
        console.error('Failed to log logout:', e);
    }
};

/**
 * Log donation actions (create, update, delete, claim, status change)
 */
const logDonationAction = async (req, action, donationId, details = {}) => {
    try {
        if (!req.user?.userId) return;
        const db = getDB();
        const { ip, userAgent } = getClientInfo(req);
        await ActivityLog.logDonationAction(db, req.user.userId, action, donationId, details, { ip, userAgent });
    } catch (e) {
        console.error('Failed to log donation action:', e);
    }
};

/**
 * Log profile update
 */
const logProfileUpdate = async (req, changes) => {
    try {
        if (!req.user?.userId) return;
        const db = getDB();
        const { ip, userAgent } = getClientInfo(req);
        await ActivityLog.logProfileUpdate(db, req.user.userId, changes, { ip, userAgent });
    } catch (e) {
        console.error('Failed to log profile update:', e);
    }
};

/**
 * Generic activity log
 */
const logActivity = async (req, action, resource, resourceId = null, details = {}) => {
    try {
        const db = getDB();
        const { ip, userAgent } = getClientInfo(req);
        await ActivityLog.log(db, {
            userId: req.user?.userId,
            action,
            resource,
            resourceId,
            details,
            ip,
            userAgent
        });
    } catch (e) {
        console.error('Failed to log activity:', e);
    }
};

/**
 * Middleware to auto-log certain requests (optional)
 * Attach to routes that need automatic logging
 */
const autoLogMiddleware = (resource) => {
    return async (req, res, next) => {
        // Store original json method
        const originalJson = res.json;

        // Override json to log after response
        res.json = function (data) {
            // Log based on method
            if (res.statusCode >= 200 && res.statusCode < 300) {
                const action = {
                    'POST': 'create',
                    'PUT': 'update',
                    'PATCH': 'update',
                    'DELETE': 'delete',
                    'GET': 'view'
                }[req.method] || 'unknown';

                const resourceId = req.params.id || data?.data?._id || data?.data?.id;

                if (action !== 'view') { // Don't log every view
                    logActivity(req, action, resource, resourceId, {
                        method: req.method,
                        path: req.path
                    });
                }
            }

            return originalJson.call(this, data);
        };

        next();
    };
};

module.exports = {
    logLogin,
    logLogout,
    logDonationAction,
    logProfileUpdate,
    logActivity,
    autoLogMiddleware,
    getClientInfo
};
