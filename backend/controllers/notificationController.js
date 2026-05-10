const { getDB } = require('../config/db');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { successResponse, errorResponse, getPagination, buildPaginationResponse } = require('../utils/helpers');

// Get user notifications
const getNotifications = async (req, res) => {
  try {
    const { page, limit, unreadOnly } = req.query;
    const { skip, limit: limitNum, page: pageNum } = getPagination(page, limit);
    
    const db = getDB();
    const filter = { userId: req.user.userId };
    
    if (unreadOnly === 'true') {
      filter.read = false;
    }
    
    const notifications = await Notification.findAll(db, filter, { skip, limit: limitNum });
    const total = await Notification.count(db, filter);
    
    const response = buildPaginationResponse(notifications, total, pageNum, limitNum);
    return successResponse(res, 200, 'Notifications retrieved successfully', response);
  } catch (error) {
    return errorResponse(res, 500, 'Error retrieving notifications', error.message);
  }
};

// Get unread notification count
const getUnreadCount = async (req, res) => {
  try {
    const db = getDB();
    const count = await Notification.countUnread(db, req.user.userId);
    return successResponse(res, 200, 'Unread count retrieved successfully', { count });
  } catch (error) {
    return errorResponse(res, 500, 'Error retrieving unread count', error.message);
  }
};

// Mark notification as read
const markAsRead = async (req, res) => {
  try {
    const db = getDB();
    const { id } = req.params;
    
    const notification = await Notification.findById(db, id);
    if (!notification) return errorResponse(res, 404, 'Notification not found');
    
    // Check ownership
    if (notification.userId.toString() !== req.user.userId) {
      return errorResponse(res, 403, 'Not authorized');
    }
    
    await Notification.markAsRead(db, id);
    return successResponse(res, 200, 'Notification marked as read');
  } catch (error) {
    return errorResponse(res, 500, 'Error marking notification as read', error.message);
  }
};

// Mark all notifications as read
const markAllAsRead = async (req, res) => {
  try {
    const db = getDB();
    await Notification.markAllAsRead(db, req.user.userId);
    return successResponse(res, 200, 'All notifications marked as read');
  } catch (error) {
    return errorResponse(res, 500, 'Error marking all notifications as read', error.message);
  }
};

// Delete notification
const deleteNotification = async (req, res) => {
  try {
    const db = getDB();
    const { id } = req.params;
    
    const notification = await Notification.findById(db, id);
    if (!notification) return errorResponse(res, 404, 'Notification not found');
    
    // Check ownership
    if (notification.userId.toString() !== req.user.userId) {
      return errorResponse(res, 403, 'Not authorized');
    }
    
    await Notification.delete(db, id);
    return successResponse(res, 200, 'Notification deleted successfully');
  } catch (error) {
    return errorResponse(res, 500, 'Error deleting notification', error.message);
  }
};

// Register FCM Token
const registerToken = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return errorResponse(res, 400, 'Token is required');

    const db = getDB();
    const user = await User.findById(db, req.user.userId);

    if (!user) return errorResponse(res, 404, 'User not found');

    // Add token if not exists
    const tokens = user.fcmTokens || [];
    if (!tokens.includes(token)) {
      tokens.push(token);
      await User.update(db, req.user.userId, { fcmTokens: tokens });
    }

    return successResponse(res, 200, 'Token registered successfully');
  } catch (error) {
    return errorResponse(res, 500, 'Error registering token', error.message);
  }
};

// Unregister FCM Token
const unregisterToken = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return errorResponse(res, 400, 'Token is required');

    const db = getDB();
    const user = await User.findById(db, req.user.userId);

    if (!user) return errorResponse(res, 404, 'User not found');

    const tokens = (user.fcmTokens || []).filter(t => t !== token);
    await User.update(db, req.user.userId, { fcmTokens: tokens });

    return successResponse(res, 200, 'Token unregistered successfully');
  } catch (error) {
    return errorResponse(res, 500, 'Error unregistering token', error.message);
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  registerToken,
  unregisterToken
};
