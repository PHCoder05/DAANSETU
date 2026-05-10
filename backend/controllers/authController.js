const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const crypto = require('crypto');
const User = require('../models/User');
const RefreshToken = require('../models/RefreshToken');
const EmailVerification = require('../models/EmailVerification');
const Volunteer = require('../models/Volunteer');
const config = require('../config/appConfig');
const { hashPassword, comparePassword, sanitizeUser, successResponse, errorResponse } = require('../utils/helpers');
const { generateToken, generateRefreshToken, verifyRefreshToken } = require('../middleware/auth');
const { sendEmail } = require('../utils/emailService');

// Check if email exists (for unified auth flow)
const checkEmail = async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return errorResponse(res, 400, 'Email is required');
    }

    const db = getDB();
    const normalizedEmail = email.toLowerCase().trim();

    console.log('checkEmail: Searching for:', normalizedEmail);

    // Check if user exists with this email
    const existingUser = await User.findByEmail(db, normalizedEmail);

    console.log('checkEmail: Result:', existingUser ? 'FOUND - ' + existingUser.role : 'NOT FOUND');

    return successResponse(res, 200, 'Email check completed', {
      exists: !!existingUser
    });
  } catch (error) {
    console.error('Check email error:', error);
    return errorResponse(res, 500, 'Error checking email', error.message);
  }
};

// Register new user
const register = async (req, res) => {
  try {
    const { email, password, name, role, phone, address, location, ngoDetails } = req.body;

    const db = getDB();

    // Check if user already exists
    const existingUser = await User.findByEmail(db, email);
    if (existingUser) {
      return errorResponse(res, 400, 'User with this email already exists');
    }

    // Hash password
    const hashedPassword = await hashPassword(password);

    // Prepare user data
    const userData = {
      email,
      password: hashedPassword,
      name,
      role,
      phone,
      address,
      location,
      verified: false,
      active: true
    };

    // Add NGO details if role is NGO
    if (role === 'ngo' && ngoDetails) {
      userData.ngoDetails = {
        registrationNumber: ngoDetails.registrationNumber || null,
        description: ngoDetails.description || null,
        website: ngoDetails.website || null,
        documents: ngoDetails.documents || [],
        verificationStatus: 'pending',
        categories: ngoDetails.categories || [],
        establishedYear: ngoDetails.establishedYear || null
      };
    }

    // Add Volunteer details if role is Volunteer
    if (role === 'volunteer') {
      userData.volunteerStats = {
        pickupsCompleted: 0,
        hoursContributed: 0,
        reliabilityScore: 100
      };
      userData.isAvailable = true;
    }

    // Create user
    const user = await User.create(db, userData);

    // Initialize volunteer profile if role is volunteer
    if (role === 'volunteer') {
      await Volunteer.create(db, {
        userId: user._id,
        name,
        email,
        phone,
        location,
        stats: {
          pickupsCompleted: 0,
          hoursContributed: 0,
          reliabilityScore: 100
        }
      });
    }

    // Generate tokens
    const accessToken = generateToken(user._id.toString(), user.email, user.role);
    const refreshToken = generateRefreshToken(user._id.toString(), user.email, user.role);

    // Store refresh token
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    await RefreshToken.create(db, {
      userId: user._id,
      token: refreshToken,
      expiresAt
    });

    return successResponse(res, 201, 'User registered successfully', {
      user: sanitizeUser(user, { userId: user._id.toString() }),
      accessToken,
      refreshToken,
      expiresIn: '15m'
    });
  } catch (error) {
    console.error('Register error:', error);
    return errorResponse(res, 500, 'Error registering user', error.message);
  }
};

// Login user
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const db = getDB();
    const { logLogin } = require('../middleware/activityLogger');
    const FraudAlert = require('../models/FraudAlert');

    // Find user by email
    const user = await User.findByEmail(db, email);
    if (!user) {
      return errorResponse(res, 401, 'Invalid email or password');
    }

    // Check if account is active
    if (!user.active) {
      await logLogin(req, user._id.toString(), false, 'account_deactivated');
      return errorResponse(res, 401, 'Your account has been deactivated');
    }

    // Verify password
    const isValidPassword = await comparePassword(password, user.password);
    if (!isValidPassword) {
      // Log failed attempt
      await logLogin(req, user._id.toString(), false, 'invalid_password');
      
      // Check for fraud
      const { getClientInfo } = require('../middleware/activityLogger');
      const { ip, userAgent } = getClientInfo(req);
      await FraudAlert.checkSuspiciousLogin(db, user._id.toString(), ip, userAgent);
      
      return errorResponse(res, 401, 'Invalid email or password');
    }

    // Log successful login
    await logLogin(req, user._id.toString(), true);

    // Generate tokens
    const accessToken = generateToken(user._id.toString(), user.email, user.role);
    const refreshToken = generateRefreshToken(user._id.toString(), user.email, user.role);

    // Store refresh token
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    await RefreshToken.create(db, {
      userId: user._id,
      token: refreshToken,
      expiresAt
    });

    return successResponse(res, 200, 'Login successful', {
      user: sanitizeUser(user, { userId: user._id.toString() }),
      accessToken,
      refreshToken,
      expiresIn: '15m'
    });
  } catch (error) {
    console.error('Login error:', error);
    return errorResponse(res, 500, 'Error logging in', error.message);
  }
};

// Get current user profile
const getProfile = async (req, res) => {
  try {
    const db = getDB();
    const user = await User.findById(db, req.user.userId);

    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    return successResponse(res, 200, 'Profile retrieved successfully', {
      user: sanitizeUser(user, req.user)
    });
  } catch (error) {
    console.error('Get profile error:', error);
    return errorResponse(res, 500, 'Error fetching profile', error.message);
  }
};

// Update user profile
const updateProfile = async (req, res) => {
  try {
    const { name, phone, address, location, profileImage } = req.body;

    const db = getDB();

    // Build update object
    const updateData = {};
    if (name) updateData.name = name;
    if (phone) updateData.phone = phone;
    if (address) updateData.address = address;
    if (location) updateData.location = location;
    if (profileImage) updateData.profileImage = profileImage;

    // Update user
    const updated = await User.update(db, req.user.userId, updateData);

    if (!updated) {
      return errorResponse(res, 404, 'User not found or no changes made');
    }

    // Get updated user
    const user = await User.findById(db, req.user.userId);

    return successResponse(res, 200, 'Profile updated successfully', {
      user: sanitizeUser(user, req.user)
    });
  } catch (error) {
    console.error('Update profile error:', error);
    return errorResponse(res, 500, 'Error updating profile', error.message);
  }
};

// Change password
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const db = getDB();
    const user = await User.findById(db, req.user.userId);

    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    // Verify current password
    const isValidPassword = await comparePassword(currentPassword, user.password);
    if (!isValidPassword) {
      return errorResponse(res, 401, 'Current password is incorrect');
    }

    // Hash new password
    const hashedPassword = await hashPassword(newPassword);

    // Update password
    await User.update(db, req.user.userId, { password: hashedPassword });

    return successResponse(res, 200, 'Password changed successfully');
  } catch (error) {
    console.error('Change password error:', error);
    return errorResponse(res, 500, 'Error changing password', error.message);
  }
};

// Update NGO details
const updateNGODetails = async (req, res) => {
  try {
    if (req.user.role !== 'ngo') {
      return errorResponse(res, 403, 'Only NGOs can update NGO details');
    }

    const { ngoDetails } = req.body;

    const db = getDB();
    const user = await User.findById(db, req.user.userId);

    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    // Merge with existing NGO details
    const updatedNGODetails = {
      ...user.ngoDetails,
      ...ngoDetails,
      // Reset verification status if critical details change
      verificationStatus: ngoDetails.registrationNumber !== user.ngoDetails?.registrationNumber
        ? 'pending'
        : user.ngoDetails?.verificationStatus
    };

    // Update user
    await User.update(db, req.user.userId, { ngoDetails: updatedNGODetails });

    // Get updated user
    const updatedUser = await User.findById(db, req.user.userId);

    return successResponse(res, 200, 'NGO details updated successfully', {
      user: sanitizeUser(updatedUser, req.user)
    });
  } catch (error) {
    console.error('Update NGO details error:', error);
    return errorResponse(res, 500, 'Error updating NGO details', error.message);
  }
};

// Refresh access token
const refreshAccessToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return errorResponse(res, 400, 'Refresh token is required');
    }

    const db = getDB();

    // Verify refresh token
    let decoded;
    try {
      decoded = verifyRefreshToken(refreshToken);
    } catch (error) {
      return errorResponse(res, 401, 'Invalid or expired refresh token');
    }

    // Check if refresh token exists and is not revoked
    const storedToken = await RefreshToken.findByToken(db, refreshToken);
    if (!storedToken) {
      return errorResponse(res, 401, 'Refresh token not found or has been revoked');
    }

    // Verify user still exists and is active
    const user = await User.findById(db, decoded.userId);
    if (!user || !user.active) {
      return errorResponse(res, 401, 'User not found or account deactivated');
    }

    // Generate new access token
    const accessToken = generateToken(user._id.toString(), user.email, user.role);

    // Optionally generate new refresh token (token rotation)
    const newRefreshToken = generateRefreshToken(user._id.toString(), user.email, user.role);

    // Revoke old refresh token and store new one
    await RefreshToken.revokeToken(db, refreshToken, newRefreshToken);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await RefreshToken.create(db, {
      userId: user._id,
      token: newRefreshToken,
      expiresAt
    });

    return successResponse(res, 200, 'Token refreshed successfully', {
      accessToken,
      refreshToken: newRefreshToken,
      expiresIn: '15m'
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    return errorResponse(res, 500, 'Error refreshing token', error.message);
  }
};

// Logout
const logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return successResponse(res, 200, 'Logged out successfully');
    }

    const db = getDB();

    // Revoke the refresh token
    await RefreshToken.revokeToken(db, refreshToken);

    return successResponse(res, 200, 'Logged out successfully');
  } catch (error) {
    console.error('Logout error:', error);
    return errorResponse(res, 500, 'Error logging out', error.message);
  }
};

// Logout from all devices
const logoutAll = async (req, res) => {
  try {
    const db = getDB();

    // Revoke all refresh tokens for the user
    const count = await RefreshToken.revokeAllUserTokens(db, req.user.userId);

    return successResponse(res, 200, `Logged out from ${count} device(s)`);
  } catch (error) {
    console.error('Logout all error:', error);
    return errorResponse(res, 500, 'Error logging out from all devices', error.message);
  }
};

// Generate JWT token for a user (Admin only or for testing)
const generateUserToken = async (req, res) => {
  try {
    const { userId, email } = req.body;

    if (!userId && !email) {
      return errorResponse(res, 400, 'Either userId or email is required');
    }

    const db = getDB();
    let user;

    // Find user by ID or email
    if (userId) {
      user = await User.findById(db, userId);
    } else {
      user = await User.findByEmail(db, email);
    }

    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    // Check if account is active
    if (!user.active) {
      return errorResponse(res, 400, 'User account is deactivated');
    }

    // Generate tokens
    const accessToken = generateToken(user._id.toString(), user.email, user.role);
    const refreshToken = generateRefreshToken(user._id.toString(), user.email, user.role);

    // Store refresh token
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    await RefreshToken.create(db, {
      userId: user._id,
      token: refreshToken,
      expiresAt
    });

    return successResponse(res, 200, 'JWT token generated successfully', {
      user: sanitizeUser(user, req.user),
      accessToken,
      refreshToken,
      expiresIn: '15m',
      tokenType: 'Bearer'
    });
  } catch (error) {
    console.error('Generate token error:', error);
    return errorResponse(res, 500, 'Error generating token', error.message);
  }
};



// Get leaderboard (Top donors)
const getLeaderboard = async (req, res) => {
  try {
    const db = getDB();

    // Find top 10 donors sorted by impactScore
    const topDonors = await db.collection('users')
      .find({ role: 'donor', active: true, impactScore: { $gt: 0 } })
      .sort({ impactScore: -1 })
      .limit(10)
      .project({
        name: 1,
        impactScore: 1,
        'donorStats.totalDonations': 1,
        profileImage: 1
      })
      .toArray();

    return successResponse(res, 200, 'Leaderboard retrieved successfully', { leaderboard: topDonors });
  } catch (error) {
    console.error('Leaderboard error:', error);
    return errorResponse(res, 500, 'Error fetching leaderboard', error.message);
  }
};

// Upload profile image
const uploadProfileImage = async (req, res) => {
  try {
    if (!req.file) {
      return errorResponse(res, 400, 'No image file uploaded');
    }

    const db = getDB();

    // Store relative path
    const imagePath = `/uploads/profiles/${req.file.filename}`;

    // Update user profile image
    const updated = await User.update(db, req.user.userId, { profileImage: imagePath });

    if (!updated) {
      return errorResponse(res, 404, 'User not found');
    }

    // Get updated user
    const user = await User.findById(db, req.user.userId);

    return successResponse(res, 200, 'Profile image uploaded successfully', {
      user: sanitizeUser(user, req.user),
      imagePath
    });
  } catch (error) {
    console.error('Upload profile image error:', error);
    return errorResponse(res, 500, 'Error uploading profile image', error.message);
  }
};


// Toggle Bookmark
const toggleBookmark = async (req, res) => {
  try {
    const { donationId } = req.body;
    const userId = req.user.userId;
    const db = getDB();

    if (!donationId) {
      return errorResponse(res, 400, 'Donation ID is required');
    }

    // Check if bookmarked
    const user = await User.findById(db, userId);

    // Ensure bookmarks array exists (for legacy records)
    const bookmarks = user.bookmarks || [];

    const index = bookmarks.indexOf(donationId);
    let isBookmarked = false;

    if (index === -1) {
      // Add
      await db.collection('users').updateOne(
        { _id: new ObjectId(userId) },
        { $push: { bookmarks: donationId } }
      );
      isBookmarked = true;
      return successResponse(res, 200, 'Donation bookmarked', { isBookmarked });
    } else {
      // Remove
      await db.collection('users').updateOne(
        { _id: new ObjectId(userId) },
        { $pull: { bookmarks: donationId } }
      );
      isBookmarked = false;
      return successResponse(res, 200, 'Bookmark removed', { isBookmarked });
    }
  } catch (error) {
    console.error('Toggle bookmark error:', error);
    return errorResponse(res, 500, 'Error toggling bookmark', error.message);
  }
};

// Send email verification
const sendVerificationEmail = async (req, res) => {
  try {
    const db = getDB();
    const user = await User.findById(db, req.user.userId);

    if (!user) {
      return errorResponse(res, 404, 'User not found');
    }

    if (user.emailVerified) {
      return successResponse(res, 200, 'Email already verified');
    }

    // Generate verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const hashedToken = crypto.createHash('sha256').update(verificationToken).digest('hex');

    // Store token (expires in 24 hours)
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    await EmailVerification.create(db, {
      userId: user._id,
      token: hashedToken,
      expiresAt
    });

    // Send email
    const verifyUrl = `${config.urls.frontend}/verify-email?token=${verificationToken}`;

    await sendEmail(user.email, 'Verify Your Email', `
      <h3>Welcome to ${config.app.name}!</h3>
      <p>Please click the link below to verify your email:</p>
      <a href="${verifyUrl}">Verify Email</a>
      <p>This link expires in 24 hours.</p>
    `);

    return successResponse(res, 200, 'Verification email sent');
  } catch (error) {
    console.error('Send verification email error:', error);
    return errorResponse(res, 500, 'Error sending verification email', error.message);
  }
};

// Verify email
const verifyEmail = async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return errorResponse(res, 400, 'Verification token is required');
    }

    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
    const db = getDB();

    // Find valid verification token
    const verification = await EmailVerification.findByToken(db, hashedToken);

    if (!verification) {
      return errorResponse(res, 400, 'Invalid or expired verification token');
    }

    // Update user's emailVerified status
    await User.update(db, verification.userId.toString(), { emailVerified: true });

    // Mark token as used
    await EmailVerification.markAsUsed(db, hashedToken);

    return successResponse(res, 200, 'Email verified successfully');
  } catch (error) {
    console.error('Verify email error:', error);
    return errorResponse(res, 500, 'Error verifying email', error.message);
  }
};

module.exports = {
  checkEmail,
  register,
  login,
  getProfile,
  updateProfile,
  uploadProfileImage,
  changePassword,
  updateNGODetails,
  refreshAccessToken,
  logout,
  logoutAll,
  generateUserToken,
  getLeaderboard,
  toggleBookmark,
  sendVerificationEmail,
  verifyEmail
};

