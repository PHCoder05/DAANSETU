const { getDB } = require('../config/db');
const ActivityLog = require('../models/ActivityLog');
const { successResponse, errorResponse } = require('../utils/helpers');

/**
 * Get current user's activity log
 */
const getMyActivity = async (req, res) => {
    try {
        const { limit = 50, skip = 0, action, resource } = req.query;
        const db = getDB();

        const activities = await ActivityLog.getUserActivity(db, req.user.userId, {
            limit: parseInt(limit),
            skip: parseInt(skip),
            action,
            resource
        });

        return successResponse(res, 200, 'Activity log retrieved', { activities });
    } catch (error) {
        console.error('Get my activity error:', error);
        return errorResponse(res, 500, 'Error fetching activity log', error.message);
    }
};

/**
 * Get activity summary for dashboard
 */
const getActivitySummary = async (req, res) => {
    try {
        const db = getDB();
        const summary = await ActivityLog.getActivitySummary(db, req.user.userId);

        return successResponse(res, 200, 'Activity summary retrieved', { summary });
    } catch (error) {
        console.error('Get activity summary error:', error);
        return errorResponse(res, 500, 'Error fetching activity summary', error.message);
    }
};

/**
 * Get activity for a specific donation (audit trail)
 */
const getDonationAuditTrail = async (req, res) => {
    try {
        const { donationId } = req.params;
        const db = getDB();

        const activities = await ActivityLog.getResourceActivity(db, 'donation', donationId);

        return successResponse(res, 200, 'Audit trail retrieved', { activities });
    } catch (error) {
        console.error('Get donation audit trail error:', error);
        return errorResponse(res, 500, 'Error fetching audit trail', error.message);
    }
};

/**
 * Admin: Get user's full activity history
 */
const getUserActivity = async (req, res) => {
    try {
        const { userId } = req.params;
        const { limit = 100, skip = 0 } = req.query;
        const db = getDB();

        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const activities = await ActivityLog.getUserActivity(db, userId, {
            limit: parseInt(limit),
            skip: parseInt(skip)
        });

        return successResponse(res, 200, 'User activity retrieved', { activities });
    } catch (error) {
        console.error('Get user activity error:', error);
        return errorResponse(res, 500, 'Error fetching user activity', error.message);
    }
};

module.exports = {
    getMyActivity,
    getActivitySummary,
    getDonationAuditTrail,
    getUserActivity
};
