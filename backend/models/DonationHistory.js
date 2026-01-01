const { ObjectId } = require('mongodb');

/**
 * DonationHistory Model
 * Tracks all status changes for a donation (timeline)
 */
class DonationHistory {
    constructor(data) {
        this.donationId = new ObjectId(data.donationId);
        this.status = data.status;
        this.previousStatus = data.previousStatus || null;
        this.changedBy = data.changedBy ? new ObjectId(data.changedBy) : null;
        this.changedByRole = data.changedByRole || null; // 'donor', 'ngo', 'system'
        this.note = data.note || null;
        this.metadata = data.metadata || {}; // Extra data like delivery images, location
        this.createdAt = data.createdAt || new Date();
    }

    static collectionName = 'donation_history';

    /**
     * Create a new history entry
     */
    static async create(db, historyData) {
        const entry = new DonationHistory(historyData);
        const result = await db.collection(this.collectionName).insertOne(entry);
        return { ...entry, _id: result.insertedId };
    }

    /**
     * Get full timeline for a donation
     */
    static async getTimeline(db, donationId) {
        return await db.collection(this.collectionName)
            .aggregate([
                { $match: { donationId: new ObjectId(donationId) } },
                { $sort: { createdAt: 1 } },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'changedBy',
                        foreignField: '_id',
                        as: 'changedByUser'
                    }
                },
                { $unwind: { path: '$changedByUser', preserveNullAndEmptyArrays: true } },
                {
                    $project: {
                        status: 1,
                        previousStatus: 1,
                        note: 1,
                        metadata: 1,
                        createdAt: 1,
                        changedByRole: 1,
                        changedBy: {
                            _id: '$changedByUser._id',
                            name: '$changedByUser.name',
                            role: '$changedByUser.role'
                        }
                    }
                }
            ])
            .toArray();
    }

    /**
     * Get latest status change for a donation
     */
    static async getLatest(db, donationId) {
        return await db.collection(this.collectionName)
            .findOne(
                { donationId: new ObjectId(donationId) },
                { sort: { createdAt: -1 } }
            );
    }

    /**
     * Log a status change (helper for donation status updates)
     */
    static async logStatusChange(db, { donationId, previousStatus, newStatus, changedBy, changedByRole, note, metadata }) {
        return await this.create(db, {
            donationId,
            status: newStatus,
            previousStatus,
            changedBy,
            changedByRole,
            note,
            metadata
        });
    }
}

module.exports = DonationHistory;
