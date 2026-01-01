/**
 * Standard API Error Codes
 * Use these codes for consistent error responses across the API
 */

const ErrorCodes = {
    // Authentication Errors (401)
    UNAUTHORIZED: {
        code: 'UNAUTHORIZED',
        status: 401,
        message: 'Authentication required'
    },
    TOKEN_EXPIRED: {
        code: 'TOKEN_EXPIRED',
        status: 401,
        message: 'Token has expired'
    },
    INVALID_TOKEN: {
        code: 'INVALID_TOKEN',
        status: 401,
        message: 'Invalid authentication token'
    },

    // Authorization Errors (403)
    FORBIDDEN: {
        code: 'FORBIDDEN',
        status: 403,
        message: 'Access denied'
    },
    INSUFFICIENT_PERMISSIONS: {
        code: 'INSUFFICIENT_PERMISSIONS',
        status: 403,
        message: 'You do not have permission to perform this action'
    },
    NOT_OWNER: {
        code: 'NOT_OWNER',
        status: 403,
        message: 'You can only access your own resources'
    },

    // Resource Errors (404)
    NOT_FOUND: {
        code: 'NOT_FOUND',
        status: 404,
        message: 'Resource not found'
    },
    USER_NOT_FOUND: {
        code: 'USER_NOT_FOUND',
        status: 404,
        message: 'User not found'
    },
    DONATION_NOT_FOUND: {
        code: 'DONATION_NOT_FOUND',
        status: 404,
        message: 'Donation not found'
    },

    // Validation Errors (400)
    VALIDATION_ERROR: {
        code: 'VALIDATION_ERROR',
        status: 400,
        message: 'Validation failed'
    },
    INVALID_INPUT: {
        code: 'INVALID_INPUT',
        status: 400,
        message: 'Invalid input provided'
    },
    MISSING_REQUIRED_FIELD: {
        code: 'MISSING_REQUIRED_FIELD',
        status: 400,
        message: 'Required field is missing'
    },

    // Conflict Errors (409)
    CONFLICT: {
        code: 'CONFLICT',
        status: 409,
        message: 'Resource already exists'
    },
    ALREADY_CLAIMED: {
        code: 'ALREADY_CLAIMED',
        status: 409,
        message: 'Donation has already been claimed'
    },
    DUPLICATE_EMAIL: {
        code: 'DUPLICATE_EMAIL',
        status: 409,
        message: 'Email already registered'
    },

    // Rate Limiting (429)
    RATE_LIMIT_EXCEEDED: {
        code: 'RATE_LIMIT_EXCEEDED',
        status: 429,
        message: 'Too many requests, please try again later'
    },

    // Server Errors (500)
    INTERNAL_ERROR: {
        code: 'INTERNAL_ERROR',
        status: 500,
        message: 'Internal server error'
    },
    DATABASE_ERROR: {
        code: 'DATABASE_ERROR',
        status: 500,
        message: 'Database operation failed'
    }
};

/**
 * Create a standardized error response
 * @param {Object} errorCode - Error code from ErrorCodes
 * @param {string} customMessage - Optional custom message
 * @param {Object} details - Optional error details
 */
const createError = (errorCode, customMessage = null, details = null) => {
    return {
        success: false,
        error: {
            code: errorCode.code,
            message: customMessage || errorCode.message,
            ...(details && { details })
        }
    };
};

/**
 * Send standardized error response
 */
const sendError = (res, errorCode, customMessage = null, details = null) => {
    return res.status(errorCode.status).json(createError(errorCode, customMessage, details));
};

/**
 * Create a standardized success response
 */
const createSuccess = (message, data = null, meta = null) => {
    const response = {
        success: true,
        message,
        ...(data && { data }),
        meta: {
            version: 'v1',
            timestamp: new Date().toISOString(),
            ...(meta && meta)
        }
    };
    return response;
};

/**
 * Send standardized success response
 */
const sendSuccess = (res, statusCode, message, data = null, meta = null) => {
    return res.status(statusCode).json(createSuccess(message, data, meta));
};

module.exports = {
    ErrorCodes,
    createError,
    sendError,
    createSuccess,
    sendSuccess
};
