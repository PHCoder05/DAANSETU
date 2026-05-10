const { ObjectId } = require('mongodb');
const { calculateDistance } = require('../utils/helpers');


/**
 * DeliveryTracking Model
 * Real-time transport tracking with GPS, photos, and verification
 */
class DeliveryTracking {
    constructor(data) {
        this.donationId = new ObjectId(data.donationId);
        this.ngoId = new ObjectId(data.ngoId);
        this.donorId = data.donorId ? new ObjectId(data.donorId) : null;

        // Status
        this.status = data.status || 'pending'; // pending, pickup_scheduled, picked_up, in_transit, delivered, confirmed

        // Scheduling
        this.scheduledPickupTime = data.scheduledPickupTime || null;
        this.actualPickupTime = data.actualPickupTime || null;
        this.deliveryTime = data.deliveryTime || null;
        this.confirmedAt = data.confirmedAt || null;

        // Location tracking
        this.pickupLocation = data.pickupLocation || null; // { lat, lng, address }
        this.deliveryLocation = data.deliveryLocation || null;
        this.currentLocation = data.currentLocation || null; // { lat, lng, timestamp }
        this.locationHistory = data.locationHistory || []; // Array of location updates

        // Verification
        this.pickupPhoto = data.pickupPhoto || null;
        this.pickupSignature = data.pickupSignature || null;
        this.deliveryPhoto = data.deliveryPhoto || null;
        this.deliverySignature = data.deliverySignature || null;

        // QR Code verification
        this.pickupQrCode = data.pickupQrCode || null;
        this.pickupQrScannedAt = data.pickupQrScannedAt || null;
        this.deliveryQrCode = data.deliveryQrCode || null;
        this.deliveryQrScannedAt = data.deliveryQrScannedAt || null;

        // Notes and metadata
        this.notes = data.notes || [];
        this.estimatedDeliveryTime = data.estimatedDeliveryTime || null;
        this.distance = data.distance || null; // in km

        // Timestamps
        this.createdAt = data.createdAt || new Date();
        this.updatedAt = data.updatedAt || new Date();
    }

    static collectionName = 'delivery_tracking';

    // ═══════════════════════════════════════════════════════════════════
    // CRUD Operations
    // ═══════════════════════════════════════════════════════════════════

    static async create(db, trackingData) {
        const tracking = new DeliveryTracking(trackingData);

        // Generate QR codes
        tracking.pickupQrCode = this.generateQrCode(tracking.donationId, 'pickup');
        tracking.deliveryQrCode = this.generateQrCode(tracking.donationId, 'delivery');

        const result = await db.collection(this.collectionName).insertOne(tracking);
        return { ...tracking, _id: result.insertedId };
    }

    static async findByDonation(db, donationId) {
        return await db.collection(this.collectionName).findOne({
            donationId: new ObjectId(donationId)
        });
    }

    static async update(db, donationId, updateData) {
        updateData.updatedAt = new Date();
        return await db.collection(this.collectionName).updateOne(
            { donationId: new ObjectId(donationId) },
            { $set: updateData }
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    // Status Updates
    // ═══════════════════════════════════════════════════════════════════

    static async schedulePickup(db, donationId, scheduledTime) {
        return this.update(db, donationId, {
            status: 'pickup_scheduled',
            scheduledPickupTime: new Date(scheduledTime)
        });
    }

    static async markPickedUp(db, donationId, { photo, signature, location, qrCode }) {
        const tracking = await this.findByDonation(db, donationId);

        // Verify QR code
        if (tracking?.pickupQrCode !== qrCode) {
            throw new Error('Invalid pickup QR code');
        }

        // Location Verification
        if (location && tracking.pickupLocation) {
            const distance = calculateDistance(
                location.lat, 
                location.lng, 
                tracking.pickupLocation.lat, 
                tracking.pickupLocation.lng
            );

            if (distance > 0.5) { // 500 meters threshold
                const FraudAlert = require('./FraudAlert');
                await FraudAlert.createLocationMismatch(db, tracking.ngoId, donationId, {
                    action: 'pickup',
                    distance,
                    expectedLocation: tracking.pickupLocation,
                    actualLocation: location
                });
            }
        }

        return this.update(db, donationId, {
            status: 'picked_up',
            actualPickupTime: new Date(),
            pickupPhoto: photo,
            pickupSignature: signature,
            currentLocation: { ...location, timestamp: new Date() },
            pickupQrScannedAt: new Date()
        });
    }

    static async updateLocation(db, donationId, location) {
        const locationUpdate = { ...location, timestamp: new Date() };

        await db.collection(this.collectionName).updateOne(
            { donationId: new ObjectId(donationId) },
            {
                $set: {
                    status: 'in_transit',
                    currentLocation: locationUpdate,
                    updatedAt: new Date()
                },
                $push: {
                    locationHistory: locationUpdate
                }
            }
        );
    }

    static async markDelivered(db, donationId, { photo, signature, location, qrCode }) {
        const tracking = await this.findByDonation(db, donationId);

        // Verify QR code
        if (tracking?.deliveryQrCode !== qrCode) {
            throw new Error('Invalid delivery QR code');
        }

        // Location Verification
        if (location && tracking.deliveryLocation) {
            const distance = calculateDistance(
                location.lat, 
                location.lng, 
                tracking.deliveryLocation.lat, 
                tracking.deliveryLocation.lng
            );

            if (distance > 0.5) { // 500 meters threshold
                const FraudAlert = require('./FraudAlert');
                await FraudAlert.createLocationMismatch(db, tracking.ngoId, donationId, {
                    action: 'delivery',
                    distance,
                    expectedLocation: tracking.deliveryLocation,
                    actualLocation: location
                });
            }
        }

        return this.update(db, donationId, {
            status: 'delivered',
            deliveryTime: new Date(),
            deliveryPhoto: photo,
            deliverySignature: signature,
            currentLocation: { ...location, timestamp: new Date() },
            deliveryQrScannedAt: new Date()
        });
    }

    static async confirmDelivery(db, donationId, donorId) {
        const tracking = await this.findByDonation(db, donationId);

        // Only donor can confirm
        if (tracking?.donorId?.toString() !== donorId) {
            throw new Error('Only the donor can confirm delivery');
        }

        return this.update(db, donationId, {
            status: 'confirmed',
            confirmedAt: new Date()
        });
    }

    // ═══════════════════════════════════════════════════════════════════
    // Query Methods
    // ═══════════════════════════════════════════════════════════════════

    static async getActiveDeliveries(db, ngoId) {
        return await db.collection(this.collectionName)
            .find({
                ngoId: new ObjectId(ngoId),
                status: { $in: ['pickup_scheduled', 'picked_up', 'in_transit'] }
            })
            .sort({ createdAt: -1 })
            .toArray();
    }

    static async getTrackingWithDetails(db, donationId) {
        const result = await db.collection(this.collectionName)
            .aggregate([
                { $match: { donationId: new ObjectId(donationId) } },
                {
                    $lookup: {
                        from: 'donations',
                        localField: 'donationId',
                        foreignField: '_id',
                        as: 'donation'
                    }
                },
                { $unwind: '$donation' },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'ngoId',
                        foreignField: '_id',
                        as: 'ngo'
                    }
                },
                { $unwind: '$ngo' }
            ])
            .toArray();

        return result[0] || null;
    }

    // ═══════════════════════════════════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════════════════════════════════

    static generateQrCode(donationId, type) {
        const crypto = require('crypto');
        const data = `${donationId}-${type}-${Date.now()}`;
        return crypto.createHash('sha256').update(data).digest('hex').substring(0, 16);
    }

    static async addNote(db, donationId, note, userId) {
        return await db.collection(this.collectionName).updateOne(
            { donationId: new ObjectId(donationId) },
            {
                $push: {
                    notes: {
                        text: note,
                        userId: new ObjectId(userId),
                        createdAt: new Date()
                    }
                },
                $set: { updatedAt: new Date() }
            }
        );
    }
}

module.exports = DeliveryTracking;
