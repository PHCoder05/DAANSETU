const { ObjectId } = require('mongodb');

/**
 * ActivityLog Model
 * Complete audit trail for all user actions - transparency & fraud prevention
 */
class ActivityLog {
    constructor(data) {
        this.userId = data.userId ? new ObjectId(data.userId) : null;
        this.action = data.action; // login, logout, create, claim, update, delete, view
        this.resource = data.resource; // donation, profile, message, verification
        this.resourceId = data.resourceId ? new ObjectId(data.resourceId) : null;
        this.details = data.details || {};
        this.ip = data.ip || null;
        this.userAgent = data.userAgent || null;
        this.location = data.location || null; // { city, country }
        this.success = data.success !== undefined ? data.success : true;
        this.createdAt = data.createdAt || new Date();
    }

    static collectionName = 'activity_logs';

    // ═══════════════════════════════════════════════════════════════════
    // Create Methods
    // ═══════════════════════════════════════════════════════════════════

    static async log(db, logData) {
        const entry = new ActivityLog(logData);
        const result = await db.collection(this.collectionName).insertOne(entry);
        return { ...entry, _id: result.insertedId };
    }

    // Convenience methods for common actions
    static async logLogin(db, userId, { ip, userAgent, success = true, reason = null }) {
        return this.log(db, {
            userId,
            action: 'login',
            resource: 'auth',
            details: { success, reason },
            ip,
            userAgent,
            success
        });
    }

    static async logLogout(db, userId, { ip, userAgent }) {
        return this.log(db, {
            userId,
            action: 'logout',
            resource: 'auth',
            ip,
            userAgent
        });
    }

    static async logDonationAction(db, userId, action, donationId, details, { ip, userAgent }) {
        return this.log(db, {
            userId,
            action,
            resource: 'donation',
            resourceId: donationId,
            details,
            ip,
            userAgent
        });
    }

    static async logProfileUpdate(db, userId, changes, { ip, userAgent }) {
        return this.log(db, {
            userId,
            action: 'update',
            resource: 'profile',
            details: { fieldsChanged: Object.keys(changes) },
            ip,
            userAgent
        });
    }

    // ═══════════════════════════════════════════════════════════════════
    // Query Methods
    // ═══════════════════════════════════════════════════════════════════

    /**
     * Get user's activity history
     */
    static async getUserActivity(db, userId, options = {}) {
        const { limit = 50, skip = 0, action, resource } = options;

        const filter = { userId: new ObjectId(userId) };
        if (action) filter.action = action;
        if (resource) filter.resource = resource;

        return await db.collection(this.collectionName)
            .find(filter)
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .toArray();
    }

    /**
     * Get activity for a specific resource (e.g., donation)
     */
    static async getResourceActivity(db, resource, resourceId, limit = 50) {
        return await db.collection(this.collectionName)
            .aggregate([
                {
                    $match: {
                        resource,
                        resourceId: new ObjectId(resourceId)
                    }
                },
                { $sort: { createdAt: -1 } },
                { $limit: limit },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'userId',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
                {
                    $project: {
                        action: 1,
                        details: 1,
                        createdAt: 1,
                        user: {
                            _id: '$user._id',
                            name: '$user.name',
                            role: '$user.role'
                        }
                    }
                }
            ])
            .toArray();
    }

    /**
     * Get failed login attempts for fraud detection
     */
    static async getFailedLogins(db, userId, since = null) {
        const filter = {
            userId: new ObjectId(userId),
            action: 'login',
            success: false
        };

        if (since) {
            filter.createdAt = { $gte: since };
        }

        return await db.collection(this.collectionName)
            .find(filter)
            .sort({ createdAt: -1 })
            .toArray();
    }

    /**
     * Get recent activity summary for dashboard
     */
    static async getActivitySummary(db, userId) {
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

        return await db.collection(this.collectionName)
            .aggregate([
                {
                    $match: {
                        userId: new ObjectId(userId),
                        createdAt: { $gte: sevenDaysAgo }
                    }
                },
                {
                    $group: {
                        _id: { action: '$action', resource: '$resource' },
                        count: { $sum: 1 },
                        lastAt: { $max: '$createdAt' }
                    }
                }
            ])
            .toArray();
    }
}

module.exports = ActivityLog;
