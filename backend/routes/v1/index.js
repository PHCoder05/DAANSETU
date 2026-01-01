/**
 * API v1 Routes Aggregator
 * All v1 routes are registered here
 * 
 * Standard: /api/v1/{resource}
 */
const express = require('express');
const router = express.Router();
const { authLimiter, passwordResetLimiter } = require('../../middleware/security');

// ═══════════════════════════════════════════════════════════════════
// IMPORT ALL V1 ROUTE MODULES
// ═══════════════════════════════════════════════════════════════════

const authRoutes = require('./auth.routes');
const donationsRoutes = require('./donations.routes');
const ngosRoutes = require('./ngos.routes');
const notificationsRoutes = require('./notifications.routes');
const adminRoutes = require('./admin.routes');
const searchRoutes = require('./search.routes');
const dashboardRoutes = require('./dashboard.routes');
const passwordResetRoutes = require('./password-reset.routes');
const reviewsRoutes = require('./reviews.routes');
const chatRoutes = require('./chat.routes');
const setupRoutes = require('./setup.routes');
const deliveryRoutes = require('./delivery.routes');
const auditRoutes = require('./audit.routes');
const verificationRoutes = require('./verification.routes');

// ═══════════════════════════════════════════════════════════════════
// REGISTER ROUTES
// Standard REST naming: plural nouns, lowercase, hyphen-separated
// ═══════════════════════════════════════════════════════════════════

// Authentication & User Management (with stricter rate limits)
router.use('/auth', authLimiter, authRoutes);
router.use('/password-reset', passwordResetLimiter, passwordResetRoutes);

// Core Resources
router.use('/donations', donationsRoutes);
router.use('/ngos', ngosRoutes);
router.use('/requests', ngosRoutes);  // NGO requests are part of ngos module

// Supporting Features
router.use('/notifications', notificationsRoutes);
router.use('/reviews', reviewsRoutes);
router.use('/search', searchRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/chat', chatRoutes);

// Transparency & Tracking Features
router.use('/delivery', deliveryRoutes);
router.use('/audit', auditRoutes);
router.use('/verification', verificationRoutes);

// Admin & Setup
router.use('/admin', adminRoutes);
router.use('/setup', setupRoutes);

// Health Checks (also available at /health directly)
const healthRoutes = require('./health.routes');
router.use('/health', healthRoutes);

// ═══════════════════════════════════════════════════════════════════
// API VERSION INFO ENDPOINT
// ═══════════════════════════════════════════════════════════════════
const config = require('../../config/appConfig');

router.get('/', (req, res) => {
    res.json({
        success: true,
        message: `${config.app.name} API ${config.api.version}`,
        version: config.app.version,
        endpoints: {
            auth: `/api/${config.api.version}/auth`,
            donations: `/api/${config.api.version}/donations`,
            ngos: `/api/${config.api.version}/ngos`,
            notifications: `/api/${config.api.version}/notifications`,
            dashboard: `/api/${config.api.version}/dashboard`,
            admin: `/api/${config.api.version}/admin`
        }
    });
});

module.exports = router;
