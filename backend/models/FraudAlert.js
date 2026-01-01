const { ObjectId } = require('mongodb');

/**
 * FraudAlert Model
 * Detect and track suspicious activities
 */
class FraudAlert {
    constructor(data) {
        this.userId = data.userId ? new ObjectId(data.userId) : null;
        this.type = data.type; // suspicious_login, location_mismatch, rapid_claims, duplicate_donation, unusual_activity
        this.severity = data.severity || 'medium'; // low, medium, high, critical

        this.details = data.details || {};
        this.resourceType = data.resourceType || null; // donation, user, delivery
        this.resourceId = data.resourceId ? new ObjectId(data.resourceId) : null;

        // Resolution
        this.status = data.status || 'open'; // open, investigating, resolved, false_positive
        this.resolvedBy = data.resolvedBy ? new ObjectId(data.resolvedBy) : null;
        this.resolvedAt = data.resolvedAt || null;
        this.resolution = data.resolution || null;

        // Auto-action taken
        this.actionTaken = data.actionTaken || null; // account_locked, donation_flagged, none

        this.createdAt = data.createdAt || new Date();
        this.updatedAt = data.updatedAt || new Date();
    }

    static collectionName = 'fraud_alerts';

    // ═══════════════════════════════════════════════════════════════════
    // Create Alerts
    // ═══════════════════════════════════════════════════════════════════

    static async create(db, alertData) {
        const alert = new FraudAlert(alertData);
        const result = await db.collection(this.collectionName).insertOne(alert);
        return { ...alert, _id: result.insertedId };
    }

    static async createSuspiciousLogin(db, userId, details) {
        return this.create(db, {
            userId,
            type: 'suspicious_login',
            severity: details.failedAttempts > 5 ? 'high' : 'medium',
            details,
            actionTaken: details.failedAttempts > 10 ? 'account_locked' : 'none'
        });
    }

    static async createLocationMismatch(db, userId, donationId, details) {
        return this.create(db, {
            userId,
            type: 'location_mismatch',
            severity: 'high',
            resourceType: 'donation',
            resourceId: donationId,
            details
        });
    }

    static async createRapidClaims(db, ngoId, details) {
        return this.create(db, {
            userId: ngoId,
            type: 'rapid_claims',
            severity: 'medium',
            details
        });
    }

    // ═══════════════════════════════════════════════════════════════════
    // Detection Methods
    // ═══════════════════════════════════════════════════════════════════

    static async checkSuspiciousLogin(db, userId, ip, userAgent) {
        const ActivityLog = require('./ActivityLog');
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

        // Check failed logins in last hour
        const failedLogins = await ActivityLog.getFailedLogins(db, userId, oneHourAgo);

        if (failedLogins.length >= 5) {
            // Check if alert already exists
            const existingAlert = await db.collection(this.collectionName).findOne({
                userId: new ObjectId(userId),
                type: 'suspicious_login',
                status: 'open',
                createdAt: { $gte: oneHourAgo }
            });

            if (!existingAlert) {
                return this.createSuspiciousLogin(db, userId, {
                    failedAttempts: failedLogins.length,
                    lastAttemptIp: ip,
                    ips: [...new Set(failedLogins.map(l => l.ip))]
                });
            }
        }
        return null;
    }

    static async checkRapidClaims(db, ngoId) {
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

        // Count claims in last hour
        const claimCount = await db.collection('donations').countDocuments({
            claimedBy: new ObjectId(ngoId),
            claimedAt: { $gte: oneHourAgo }
        });

        if (claimCount > 10) {
            const existingAlert = await db.collection(this.collectionName).findOne({
                userId: new ObjectId(ngoId),
                type: 'rapid_claims',
                status: 'open',
                createdAt: { $gte: oneHourAgo }
            });

            if (!existingAlert) {
                return this.createRapidClaims(db, ngoId, {
                    claimCount,
                    timeWindow: '1 hour'
                });
            }
        }
        return null;
    }

    // ═══════════════════════════════════════════════════════════════════
    // Query & Resolution
    // ═══════════════════════════════════════════════════════════════════

    static async getOpenAlerts(db, severity = null) {
        const filter = { status: 'open' };
        if (severity) filter.severity = severity;

        return await db.collection(this.collectionName)
            .aggregate([
                { $match: filter },
                { $sort: { severity: -1, createdAt: -1 } },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'userId',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } }
            ])
            .toArray();
    }

    static async resolve(db, id, adminId, resolution, isFalsePositive = false) {
        return await db.collection(this.collectionName).updateOne(
            { _id: new ObjectId(id) },
            {
                $set: {
                    status: isFalsePositive ? 'false_positive' : 'resolved',
                    resolvedBy: new ObjectId(adminId),
                    resolvedAt: new Date(),
                    resolution,
                    updatedAt: new Date()
                }
            }
        );
    }

    static async getUserAlerts(db, userId) {
        return await db.collection(this.collectionName)
            .find({ userId: new ObjectId(userId) })
            .sort({ createdAt: -1 })
            .toArray();
    }
}

module.exports = FraudAlert;
