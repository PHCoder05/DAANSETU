const express = require('express');
const router = express.Router();
const deliveryController = require('../../controllers/deliveryController');
const { authenticate } = require('../../middleware/auth');
const { mongoIdValidation } = require('../../utils/validators');

/**
 * @swagger
 * /api/v1/delivery/{donationId}:
 *   get:
 *     summary: Get tracking status for a donation
 *     tags: [Delivery]
 *     security:
 *       - bearerAuth: []
 */
router.get('/:donationId', authenticate, mongoIdValidation('donationId'), deliveryController.getTrackingStatus);

/**
 * @swagger
 * /api/v1/delivery/{donationId}/initialize:
 *   post:
 *     summary: Initialize tracking (NGO only)
 *     tags: [Delivery]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:donationId/initialize', authenticate, mongoIdValidation('donationId'), deliveryController.initializeTracking);

/**
 * @swagger
 * /api/v1/delivery/{donationId}/pickup:
 *   post:
 *     summary: Mark donation as picked up with QR, photo, signature
 *     tags: [Delivery]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:donationId/pickup', authenticate, mongoIdValidation('donationId'), deliveryController.markPickedUp);

/**
 * @swagger
 * /api/v1/delivery/{donationId}/location:
 *   post:
 *     summary: Update GPS location during transit
 *     tags: [Delivery]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:donationId/location', authenticate, mongoIdValidation('donationId'), deliveryController.updateLocation);

/**
 * @swagger
 * /api/v1/delivery/{donationId}/deliver:
 *   post:
 *     summary: Mark donation as delivered with QR, photo, signature
 *     tags: [Delivery]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:donationId/deliver', authenticate, mongoIdValidation('donationId'), deliveryController.markDelivered);

/**
 * @swagger
 * /api/v1/delivery/{donationId}/confirm:
 *   post:
 *     summary: Donor confirms delivery
 *     tags: [Delivery]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:donationId/confirm', authenticate, mongoIdValidation('donationId'), deliveryController.confirmDelivery);

/**
 * @swagger
 * /api/v1/delivery/active:
 *   get:
 *     summary: Get NGO's active deliveries
 *     tags: [Delivery]
 *     security:
 *       - bearerAuth: []
 */
router.get('/active/list', authenticate, deliveryController.getActiveDeliveries);

/**
 * @swagger
 * /api/v1/delivery/{donationId}/history:
 *   get:
 *     summary: Get location history for a delivery
 *     tags: [Delivery]
 *     security:
 *       - bearerAuth: []
 */
router.get('/:donationId/history', authenticate, mongoIdValidation('donationId'), deliveryController.getLocationHistory);

module.exports = router;
