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

        return successResponse(res, 200, 'Tracking status retrieved', { tracking });
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
            return errorResponse(res, 403, 'Only the claiming NGO can initialize tracking');
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
            changedByRole: 'ngo',
            note: 'Picked up by NGO'
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
            changedByRole: 'ngo',
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

module.exports = {
    getTrackingStatus,
    initializeTracking,
    markPickedUp,
    updateLocation,
    markDelivered,
    confirmDelivery,
    getActiveDeliveries,
    getLocationHistory
};
