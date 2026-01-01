/**
 * Health Check Routes
 * Provides liveness and readiness endpoints for monitoring
 */
const express = require('express');
const router = express.Router();
const { getDB } = require('../../config/db');

/**
 * Basic liveness check
 * Returns 200 if the server is running
 */
router.get('/live', (req, res) => {
    res.json({
        success: true,
        status: 'alive',
        timestamp: new Date().toISOString()
    });
});

/**
 * Deep readiness check
 * Checks all dependencies (DB, etc.) before returning healthy
 */
router.get('/ready', async (req, res) => {
    const checks = {
        database: false,
        memory: false,
        uptime: process.uptime()
    };

    try {
        // Check database connection
        const db = getDB();
        if (db) {
            await db.command({ ping: 1 });
            checks.database = true;
        }
    } catch (error) {
        checks.database = false;
        checks.databaseError = error.message;
    }

    // Check memory usage
    const memUsage = process.memoryUsage();
    const memUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024);
    const memTotalMB = Math.round(memUsage.heapTotal / 1024 / 1024);
    checks.memory = {
        used: `${memUsedMB}MB`,
        total: `${memTotalMB}MB`,
        percentage: Math.round((memUsage.heapUsed / memUsage.heapTotal) * 100)
    };

    // Determine overall health
    const isHealthy = checks.database;

    res.status(isHealthy ? 200 : 503).json({
        success: isHealthy,
        status: isHealthy ? 'ready' : 'degraded',
        timestamp: new Date().toISOString(),
        checks,
        version: process.env.npm_package_version || '1.0.0',
        environment: process.env.NODE_ENV || 'development'
    });
});

/**
 * Combined health endpoint (backward compatible)
 */
router.get('/', async (req, res) => {
    try {
        const db = getDB();
        let dbStatus = 'disconnected';

        if (db) {
            await db.command({ ping: 1 });
            dbStatus = 'connected';
        }

        res.json({
            success: true,
            status: 'healthy',
            database: dbStatus,
            uptime: Math.round(process.uptime()),
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(503).json({
            success: false,
            status: 'unhealthy',
            database: 'error',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

module.exports = router;
