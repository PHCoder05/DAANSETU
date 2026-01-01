const logger = require('../utils/logger');

// Request logging middleware
const requestLogger = (req, res, next) => {
  const startTime = Date.now();

  // Log request
  logger.info('🔵 Incoming Request', {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip || req.connection.remoteAddress,
    userAgent: req.get('user-agent'),
    body: req.method !== 'GET' ? sanitizeBody(req.body) : undefined
  });

  // Capture response
  const originalSend = res.send;
  res.send = function(data) {
    const responseTime = Date.now() - startTime;
    
    // Log response
    const level = res.statusCode >= 400 ? 'error' : 'info';
    const emoji = res.statusCode >= 400 ? '🔴' : '🟢';
    
    logger[level](`${emoji} Response Sent`, {
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      responseTime: `${responseTime}ms`
    });

    originalSend.call(this, data);
  };

  next();
};

// Sanitize request body (remove sensitive data from logs)
const sanitizeBody = (body) => {
  if (!body || typeof body !== 'object') return body;

  const sanitized = { ...body };
  const sensitiveFields = ['password', 'token', 'refreshToken', 'accessToken', 'secret'];

  sensitiveFields.forEach(field => {
    if (sanitized[field]) {
      sanitized[field] = '***REDACTED***';
    }
  });

  return sanitized;
};

module.exports = requestLogger;

