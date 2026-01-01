const { getDB } = require('../config/db');
const User = require('../models/User');
const { hashPassword, sanitizeUser, successResponse, errorResponse } = require('../utils/helpers');
const { generateToken, generateRefreshToken } = require('../middleware/auth');
const RefreshToken = require('../models/RefreshToken');

// First-time admin setup
const firstTimeSetup = async (req, res) => {
  try {
    const { email, password, name, setupKey } = req.body;
    
    // Validate setup key (you should use a secure key from environment)
    const SETUP_KEY = process.env.ADMIN_SETUP_KEY || 'change-this-setup-key-in-production';
    
    if (setupKey !== SETUP_KEY) {
      return errorResponse(res, 403, 'Invalid setup key');
    }

    const db = getDB();
    
    // Check if any admin already exists
    const existingAdmin = await db.collection('users').findOne({ role: 'admin' });
    if (existingAdmin) {
      return errorResponse(res, 400, 'Admin account already exists. Use regular login.');
    }
    
    // Check if email already exists
    const existingUser = await User.findByEmail(db, email);
    if (existingUser) {
      return errorResponse(res, 400, 'User with this email already exists');
    }
    
    // Hash password
    const hashedPassword = await hashPassword(password);
    
    // Create admin user
    const userData = {
      email,
      password: hashedPassword,
      name,
      role: 'admin',
      verified: true,
      active: true
    };
    
    const user = await User.create(db, userData);
    
    // Generate tokens
    const accessToken = generateToken(user._id.toString(), user.email, user.role);
    const refreshToken = generateRefreshToken(user._id.toString(), user.email, user.role);
    
    // Store refresh token
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);
    
    await RefreshToken.create(db, {
      userId: user._id,
      token: refreshToken,
      expiresAt
    });
    
    return successResponse(res, 201, 'Admin account created successfully', {
      user: sanitizeUser(user),
      accessToken,
      refreshToken,
      expiresIn: '15m'
    });
  } catch (error) {
    console.error('First-time setup error:', error);
    return errorResponse(res, 500, 'Error creating admin account', error.message);
  }
};

// Check if setup is needed
const checkSetup = async (req, res) => {
  try {
    const db = getDB();
    
    // Check if any admin exists
    const adminExists = await db.collection('users').findOne({ role: 'admin' });
    
    return successResponse(res, 200, 'Setup status retrieved', {
      setupRequired: !adminExists,
      message: adminExists 
        ? 'Admin account exists. Use regular login.' 
        : 'First-time setup required. Create an admin account.'
    });
  } catch (error) {
    console.error('Check setup error:', error);
    return errorResponse(res, 500, 'Error checking setup status', error.message);
  }
};

module.exports = {
  firstTimeSetup,
  checkSetup
};

