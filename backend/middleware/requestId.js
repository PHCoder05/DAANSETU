/**
 * Request ID Middleware
 * Generates unique request IDs for tracing and debugging
 * Every request gets a unique ID that's included in logs and responses
 */
const { v4: uuidv4 } = require('uuid');

/**
 * Request ID Middleware
 * Adds a unique X-Request-ID header to every request and response
 */
const requestId = (req, res, next) => {
    // Use existing X-Request-ID if provided (for distributed tracing)
    // Otherwise generate a new one
    const id = req.headers['x-request-id'] || uuidv4();

    // Attach to request for use in logging
    req.requestId = id;

    // Add to response headers for client debugging
    res.setHeader('X-Request-ID', id);

    next();
};

module.exports = { requestId };
