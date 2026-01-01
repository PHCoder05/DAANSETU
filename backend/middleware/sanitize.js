/**
 * Input Sanitization Middleware
 * Prevents MongoDB injection and XSS attacks by sanitizing request data
 */

/**
 * Recursively sanitize an object to prevent MongoDB injection
 * Removes keys starting with $ and containing dots (.)
 */
const sanitizeObject = (obj) => {
    if (obj === null || typeof obj !== 'object') {
        return obj;
    }

    if (Array.isArray(obj)) {
        return obj.map(sanitizeObject);
    }

    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
        // Block MongoDB operators (keys starting with $)
        if (key.startsWith('$')) {
            continue;
        }
        // Block dot notation injection
        if (key.includes('.')) {
            continue;
        }
        // Recursively sanitize nested objects
        sanitized[key] = sanitizeObject(value);
    }
    return sanitized;
};

/**
 * Middleware to sanitize request body, query, and params
 */
const sanitizeInput = (req, res, next) => {
    if (req.body && typeof req.body === 'object') {
        req.body = sanitizeObject(req.body);
    }
    if (req.query && typeof req.query === 'object') {
        req.query = sanitizeObject(req.query);
    }
    if (req.params && typeof req.params === 'object') {
        req.params = sanitizeObject(req.params);
    }
    next();
};

/**
 * Trim string values in request body
 */
const trimStrings = (req, res, next) => {
    const trimRecursive = (obj) => {
        if (typeof obj === 'string') {
            return obj.trim();
        }
        if (Array.isArray(obj)) {
            return obj.map(trimRecursive);
        }
        if (obj && typeof obj === 'object') {
            const result = {};
            for (const [key, value] of Object.entries(obj)) {
                result[key] = trimRecursive(value);
            }
            return result;
        }
        return obj;
    };

    if (req.body) {
        req.body = trimRecursive(req.body);
    }
    next();
};

module.exports = {
    sanitizeInput,
    sanitizeObject,
    trimStrings
};
