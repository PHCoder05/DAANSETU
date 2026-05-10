const { getDB } = require('../config/db');
const DeliveryTracking = require('../models/DeliveryTracking');
const DonationHistory = require('../models/DonationHistory');
const Notification = require('../models/Notification');
const { successResponse, errorResponse } = require('../utils/helpers');
const { logDonationAction } = require('../middleware/activityLogger');

/**
 * Get delivery tracking status for a donation
 */
const getTrackingStatus = async (req, res) => {
    try {
        const { donationId } = req.params;
        const db = getDB();

        const tracking = await DeliveryTracking.getTrackingWithDetails(db, donationId);

        if (!tracking) {
            return errorResponse(res, 404, 'Tracking not found for this donation');
        }

        // Security: Remove sensitive QR codes based on role
        // Volunteers shouldn't see any QR codes (they must scan them)
        // Donors should only see pickupQrCode
        // NGOs should only see deliveryQrCode
        
        const safeTracking = { ...tracking };
        const userId = req.user.userId;

        if (req.user.role === 'volunteer') {
            delete safeTracking.pickupQrCode;
            delete safeTracking.deliveryQrCode;
        } else if (req.user.role === 'donor' && tracking.donorId?.toString() === userId) {
            delete safeTracking.deliveryQrCode;
        } else if (req.user.role === 'ngo' && tracking.ngoId?.toString() === userId) {
            delete safeTracking.pickupQrCode;
        } else {
            // Default: Hide both if not directly involved
            delete safeTracking.pickupQrCode;
            delete safeTracking.deliveryQrCode;
        }

        return successResponse(res, 200, 'Tracking status retrieved', { tracking: safeTracking });
    } catch (error) {
        console.error('Get tracking status error:', error);
        return errorResponse(res, 500, 'Error fetching tracking status', error.message);
    }
};

/**
 * Initialize tracking when donation is claimed
 */
const initializeTracking = async (req, res) => {
    try {
        const { donationId } = req.params;
        const { scheduledPickupTime } = req.body;
        const db = getDB();

        // Get donation to verify claim
        const Donation = require('../models/Donation');
        const donation = await Donation.findById(db, donationId);

        if (!donation) {
            return errorResponse(res, 404, 'Donation not found');
        }

        if (donation.claimedBy?.toString() !== req.user.userId) {
            return errorResponse(res, 403, 'Only the participant who claimed this can initialize tracking');
        }

        // Create tracking record
        const tracking = await DeliveryTracking.create(db, {
            donationId,
            ngoId: req.user.userId,
            donorId: donation.donorId,
            pickupLocation: donation.pickupLocation,
            scheduledPickupTime,
            status: 'pickup_scheduled'
        });

        // Log activity
        await logDonationAction(req, 'tracking_initialized', donationId, { scheduledPickupTime });

        return successResponse(res, 201, 'Tracking initialized', { tracking });
    } catch (error) {
        console.error('Initialize tracking error:', error);
        return errorResponse(res, 500, 'Error initializing tracking', error.message);
    }
};

/**
 * Mark donation as picked up
 */
const markPickedUp = async (req, res) => {
    try {
        const { donationId } = req.params;
        const { photo, signature, location, qrCode } = req.body;
        const db = getDB();

        await DeliveryTracking.markPickedUp(db, donationId, { photo, signature, location, qrCode });

        // Update donation status
        const Donation = require('../models/Donation');
        await Donation.updateStatus(db, donationId, 'in-transit');

        // Log history
        await DonationHistory.logStatusChange(db, {
            donationId,
            previousStatus: 'claimed',
            newStatus: 'in-transit',
            changedBy: req.user.userId,
            changedByRole: req.user.role,
            note: `Picked up by ${req.user.role}`
        });

        // Notify donor
        const donation = await Donation.findById(db, donationId);
        await Notification.create(db, {
            userId: donation.donorId,
            type: 'donation',
            title: 'Donation Picked Up',
            message: `Your donation "${donation.title}" has been picked up!`,
            data: { donationId }
        });

        await logDonationAction(req, 'picked_up', donationId, { hasPhoto: !!photo });

        return successResponse(res, 200, 'Marked as picked up');
    } catch (error) {
        console.error('Mark picked up error:', error);
        return errorResponse(res, 500, error.message || 'Error marking as picked up');
    }
};

/**
 * Update location during transit
 */
const updateLocation = async (req, res) => {
    try {
        const { donationId } = req.params;
        const { lat, lng } = req.body;
        const db = getDB();

        await DeliveryTracking.updateLocation(db, donationId, { lat, lng });

        return successResponse(res, 200, 'Location updated');
    } catch (error) {
        console.error('Update location error:', error);
        return errorResponse(res, 500, 'Error updating location', error.message);
    }
};

/**
 * Mark donation as delivered
 */
const markDelivered = async (req, res) => {
    try {
        const { donationId } = req.params;
        const { photo, signature, location, qrCode } = req.body;
        const db = getDB();

        await DeliveryTracking.markDelivered(db, donationId, { photo, signature, location, qrCode });

        // Update donation status
        const Donation = require('../models/Donation');
        await Donation.updateStatus(db, donationId, 'delivered');

        // Log history
        await DonationHistory.logStatusChange(db, {
            donationId,
            previousStatus: 'in-transit',
            newStatus: 'delivered',
            changedBy: req.user.userId,
            changedByRole: req.user.role,
            note: 'Delivered successfully'
        });

        // Notify donor
        const donation = await Donation.findById(db, donationId);
        await Notification.create(db, {
            userId: donation.donorId,
            type: 'donation',
            title: 'Donation Delivered',
            message: `Your donation "${donation.title}" has been delivered! Please confirm.`,
            data: { donationId }
        });

        // Update Volunteer Stats (if role is volunteer)
        if (req.user.role === 'volunteer') {
            const User = require('../models/User');
            await db.collection('users').updateOne(
                { _id: new ObjectId(req.user.userId) },
                { 
                    $inc: { 
                        'volunteerStats.pickupsCompleted': 1,
                        'volunteerStats.totalPoints': 15
                    } 
                }
            );
        }

        await logDonationAction(req, 'delivered', donationId, { hasPhoto: !!photo });

        return successResponse(res, 200, 'Marked as delivered');
    } catch (error) {
        console.error('Mark delivered error:', error);
        return errorResponse(res, 500, error.message || 'Error marking as delivered');
    }
};

/**
 * Donor confirms delivery
 */
const confirmDelivery = async (req, res) => {
    try {
        const { donationId } = req.params;
        const db = getDB();

        await DeliveryTracking.confirmDelivery(db, donationId, req.user.userId);

        // Log history
        await DonationHistory.logStatusChange(db, {
            donationId,
            previousStatus: 'delivered',
            newStatus: 'confirmed',
            changedBy: req.user.userId,
            changedByRole: 'donor',
            note: 'Confirmed by donor'
        });

        await logDonationAction(req, 'confirmed', donationId, {});

        return successResponse(res, 200, 'Delivery confirmed');
    } catch (error) {
        console.error('Confirm delivery error:', error);
        return errorResponse(res, 500, error.message || 'Error confirming delivery');
    }
};

/**
 * Get active deliveries for NGO
 */
const getActiveDeliveries = async (req, res) => {
    try {
        const db = getDB();
        const deliveries = await DeliveryTracking.getActiveDeliveries(db, req.user.userId);

        return successResponse(res, 200, 'Active deliveries retrieved', { deliveries });
    } catch (error) {
        console.error('Get active deliveries error:', error);
        return errorResponse(res, 500, 'Error fetching deliveries', error.message);
    }
};

/**
 * Get location history for a delivery
 */
const getLocationHistory = async (req, res) => {
    try {
        const { donationId } = req.params;
        const db = getDB();

        const tracking = await DeliveryTracking.findByDonation(db, donationId);

        if (!tracking) {
            return errorResponse(res, 404, 'Tracking not found');
        }

        return successResponse(res, 200, 'Location history retrieved', {
            currentLocation: tracking.currentLocation,
            locationHistory: tracking.locationHistory,
            status: tracking.status
        });
    } catch (error) {
        console.error('Get location history error:', error);
        return errorResponse(res, 500, 'Error fetching location history', error.message);
    }
};

// SOS Alert
const reportSOS = async (req, res) => {
  try {
    const { donationId } = req.params;
    const { location, message } = req.body;
    const { userId } = req.user;
    const db = getDB();

    const tracking = await db.collection('delivery_tracking').findOne({ donationId: new ObjectId(donationId) });
    if (!tracking) return errorResponse(res, 404, 'Tracking not found');

    // Create an emergency audit log
    await db.collection('audit_logs').insertOne({
      action: 'SOS_ALERT',
      resource: 'delivery',
      resourceId: new ObjectId(donationId),
      userId: new ObjectId(userId),
      data: { location, message },
      severity: 'high',
      createdAt: new Date()
    });

    // Notify all admins
    const Notification = require('../models/Notification');
    const admins = await db.collection('users').find({ role: 'admin' }).toArray();
    
    for (const admin of admins) {
      await Notification.create(db, {
        userId: admin._id,
        title: '🚨 EMERGENCY: SOS Alert',
        message: `Volunteer ${req.user.name} reported an issue during delivery. Message: ${message || 'No details provided'}`,
        type: 'sos',
        relatedId: donationId,
        relatedType: 'donation',
        priority: 'high',
        createdAt: new Date()
      });
    }

    return successResponse(res, 200, 'SOS alert sent to all administrators');
  } catch (error) {
    return errorResponse(res, 500, 'Error reporting SOS', error.message);
  }
};

module.exports = {
    getTrackingStatus,
    initializeTracking,
    markPickedUp,
    updateLocation,
    markDelivered,
    confirmDelivery,
    getActiveDeliveries,
    getLocationHistory,
    reportSOS
};
