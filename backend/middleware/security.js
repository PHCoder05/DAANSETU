/**
 * Security Middleware
 * Combines Helmet headers, rate limiting, and other security measures
 */
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// ═══════════════════════════════════════════════════════════════════
// HELMET - Security Headers
// ═══════════════════════════════════════════════════════════════════
const helmetMiddleware = helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
        },
    },
    crossOriginEmbedderPolicy: false, // Disable for mobile app compatibility
});

// ═══════════════════════════════════════════════════════════════════
// RATE LIMITING - Prevent abuse
// ═══════════════════════════════════════════════════════════════════

// General API rate limit
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: process.env.NODE_ENV === 'production' ? 100 : 1000, // 100 requests in prod, 1000 in dev
    message: {
        success: false,
        error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: 'Too many requests, please try again later',
        },
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// Strict rate limit for auth endpoints (login, register)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: process.env.NODE_ENV === 'production' ? 10 : 500, // 10 attempts in prod, 500 in dev
    message: {
        success: false,
        error: {
            code: 'AUTH_RATE_LIMIT_EXCEEDED',
            message: 'Too many authentication attempts, please try again later',
        },
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// Strict rate limit for password reset
const passwordResetLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5, // 5 attempts per hour
    message: {
        success: false,
        error: {
            code: 'PASSWORD_RESET_LIMIT_EXCEEDED',
            message: 'Too many password reset attempts, please try again later',
        },
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// ═══════════════════════════════════════════════════════════════════
// CUSTOM ERROR CLASSES
// ═══════════════════════════════════════════════════════════════════

class AppError extends Error {
    constructor(message, statusCode, code = 'INTERNAL_ERROR') {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.isOperational = true;
        Error.captureStackTrace(this, this.constructor);
    }
}

class NotFoundError extends AppError {
    constructor(resource = 'Resource') {
        super(`${resource} not found`, 404, 'NOT_FOUND');
    }
}

class ValidationError extends AppError {
    constructor(message = 'Validation failed', details = null) {
        super(message, 400, 'VALIDATION_ERROR');
        this.details = details;
    }
}

class UnauthorizedError extends AppError {
    constructor(message = 'Authentication required') {
        super(message, 401, 'UNAUTHORIZED');
    }
}

class ForbiddenError extends AppError {
    constructor(message = 'Access denied') {
        super(message, 403, 'FORBIDDEN');
    }
}

class ConflictError extends AppError {
    constructor(message = 'Resource already exists') {
        super(message, 409, 'CONFLICT');
    }
}

class RateLimitError extends AppError {
    constructor(message = 'Too many requests') {
        super(message, 429, 'RATE_LIMIT_EXCEEDED');
    }
}

module.exports = {
    // Middleware
    helmetMiddleware,
    generalLimiter,
    authLimiter,
    passwordResetLimiter,
    // Error classes
    AppError,
    NotFoundError,
    ValidationError,
    UnauthorizedError,
    ForbiddenError,
    ConflictError,
    RateLimitError,
};
