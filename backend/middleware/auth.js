const jwt = require('jsonwebtoken');
const { getDB } = require('../config/db');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

if (!JWT_SECRET || !JWT_REFRESH_SECRET) {
  throw new Error('FATAL: JWT_SECRET and JWT_REFRESH_SECRET must be defined in environment variables.');
}
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '15m'; // Short-lived access token
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d'; // Long-lived refresh token

// Generate JWT access token
const generateToken = (userId, email, role) => {
  return jwt.sign(
    { userId, email, role, type: 'access' },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
};

// Generate JWT refresh token
const generateRefreshToken = (userId, email, role) => {
  return jwt.sign(
    { userId, email, role, type: 'refresh' },
    JWT_REFRESH_SECRET,
    { expiresIn: JWT_REFRESH_EXPIRES_IN }
  );
};

// Verify refresh token
const verifyRefreshToken = (token) => {
  try {
    const decoded = jwt.verify(token, JWT_REFRESH_SECRET);
    if (decoded.type !== 'refresh') {
      throw new Error('Invalid token type');
    }
    return decoded;
  } catch (error) {
    throw error;
  }
};

// Verify token and attach user to request
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    try {
      // Verify token
      const decoded = jwt.verify(token, JWT_SECRET);

      // Get user from database
      const db = getDB();
      const user = await User.findById(db, decoded.userId);

      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid token. User not found.'
        });
      }

      if (!user.active) {
        return res.status(401).json({
          success: false,
          message: 'Account is deactivated.'
        });
      }

      // Attach user to request
      req.user = {
        userId: user._id.toString(),
        email: user.email,
        role: user.role,
        name: user.name,
        verified: user.verified
      };

      next();
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token has expired.'
        });
      }

      return res.status(401).json({
        success: false,
        message: 'Invalid token.'
      });
    }
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during authentication.'
    });
  }
};

// Role-based authorization middleware
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role(s): ${roles.join(', ')}`
      });
    }

    next();
  };
};

// Verify NGO status
const verifyNGO = async (req, res, next) => {
  try {
    if (req.user.role !== 'ngo') {
      return res.status(403).json({
        success: false,
        message: 'This action is only available to NGOs.'
      });
    }

    const db = getDB();
    const user = await User.findById(db, req.user.userId);

    if (!user.ngoDetails || user.ngoDetails.verificationStatus !== 'verified') {
      return res.status(403).json({
        success: false,
        message: 'Your NGO account must be verified to perform this action.'
      });
    }

    next();
  } catch (error) {
    console.error('NGO verification error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during NGO verification.'
    });
  }
};

// Optional authentication - doesn't fail if no token
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.substring(7);

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      const db = getDB();
      const user = await User.findById(db, decoded.userId);

      if (user && user.active) {
        req.user = {
          userId: user._id.toString(),
          email: user.email,
          role: user.role,
          name: user.name,
          verified: user.verified
        };
      }
    } catch (error) {
      // Silently fail for optional auth
    }

    next();
  } catch (error) {
    console.error('Optional auth error:', error);
    next();
  }
};

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyRefreshToken,
  authenticate,
  authorize,
  verifyNGO,
  optionalAuth,
  JWT_SECRET,
  JWT_REFRESH_SECRET
};

