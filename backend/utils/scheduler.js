/**
 * Scheduled Jobs / Tasks
 * Runs periodic tasks like donation expiry, cleanup, etc.
 */
const { getDB } = require('../config/db');
const logger = require('../utils/logger');
const Donation = require('../models/Donation');

/**
 * Expire donations that have passed their expiry date
 * Should be run periodically (e.g., every hour)
 */
const expireDonations = async () => {
    try {
        const db = getDB();
        const now = new Date();

        // Find and update expired donations
        const result = await db.collection('donations').updateMany(
            {
                expiryDate: { $lt: now },
                status: 'available',
                active: true
            },
            {
                $set: {
                    status: 'expired',
                    active: false,
                    updatedAt: now,
                    expiredAt: now
                }
            }
        );

        if (result.modifiedCount > 0) {
            logger.info(`🗑️ Expired ${result.modifiedCount} donations`);
        }

        return result.modifiedCount;
    } catch (error) {
        logger.error('Error expiring donations:', error);
        return 0;
    }
};

/**
 * Clean up old notifications (older than 30 days and read)
 */
const cleanupNotifications = async () => {
    try {
        const db = getDB();
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const result = await db.collection('notifications').deleteMany({
            read: true,
            createdAt: { $lt: thirtyDaysAgo }
        });

        if (result.deletedCount > 0) {
            logger.info(`🧹 Cleaned up ${result.deletedCount} old notifications`);
        }

        return result.deletedCount;
    } catch (error) {
        logger.error('Error cleaning up notifications:', error);
        return 0;
    }
};

/**
 * Clean up expired password reset tokens
 */
const cleanupExpiredTokens = async () => {
    try {
        const db = getDB();
        const now = new Date();

        const result = await db.collection('password_resets').deleteMany({
            expiresAt: { $lt: now }
        });

        if (result.deletedCount > 0) {
            logger.info(`🔑 Cleaned up ${result.deletedCount} expired password reset tokens`);
        }

        return result.deletedCount;
    } catch (error) {
        logger.error('Error cleaning up expired tokens:', error);
        return 0;
    }
};

/**
 * Run all scheduled tasks
 */
const runAllTasks = async () => {
    logger.info('⏰ Running scheduled tasks...');

    await expireDonations();
    await cleanupNotifications();
    await cleanupExpiredTokens();

    logger.info('✅ Scheduled tasks completed');
};

/**
 * Start the scheduler (runs every hour)
 */
let schedulerInterval = null;

const startScheduler = (intervalMs = 60 * 60 * 1000) => { // Default: 1 hour
    if (schedulerInterval) {
        clearInterval(schedulerInterval);
    }

    // Run once on startup (after 1 minute delay)
    setTimeout(runAllTasks, 60 * 1000);

    // Then run at interval
    schedulerInterval = setInterval(runAllTasks, intervalMs);

    logger.info(`📅 Scheduler started (interval: ${intervalMs / 1000}s)`);
};

const stopScheduler = () => {
    if (schedulerInterval) {
        clearInterval(schedulerInterval);
        schedulerInterval = null;
        logger.info('📅 Scheduler stopped');
    }
};

module.exports = {
    expireDonations,
    cleanupNotifications,
    cleanupExpiredTokens,
    runAllTasks,
    startScheduler,
    stopScheduler
};
