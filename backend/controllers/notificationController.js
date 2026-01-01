const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const Notification = require('../models/Notification');
const {
  getPagination,
  buildPaginationResponse,
  successResponse,
  errorResponse
} = require('../utils/helpers');

// Get user's notifications
const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20, unreadOnly = false } = req.query;
    const { skip, limit: limitNum } = getPagination(page, limit);

    const db = getDB();

    const filter = { userId: new ObjectId(req.user.userId) };
    if (unreadOnly === 'true') {
      filter.read = false;
    }

    const notifications = await Notification.findAll(db, filter, {
      skip,
      limit: limitNum,
      sort: { createdAt: -1 }
    });

    const total = await Notification.count(db, filter);
    const unreadCount = await Notification.countUnread(db, req.user.userId);

    return successResponse(
      res,
      200,
      'Notifications retrieved successfully',
      {
        ...buildPaginationResponse(notifications, total, page, limitNum),
        unreadCount
      }
    );
  } catch (error) {
    console.error('Get notifications error:', error);
    return errorResponse(res, 500, 'Error fetching notifications', error.message);
  }
};

// Mark notification as read
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;

    const db = getDB();

    const notification = await Notification.findById(db, id);
    if (!notification) {
      return errorResponse(res, 404, 'Notification not found');
    }

    if (notification.userId.toString() !== req.user.userId) {
      return errorResponse(res, 403, 'You do not have permission to access this notification');
    }

    await Notification.markAsRead(db, id);

    return successResponse(res, 200, 'Notification marked as read');
  } catch (error) {
    console.error('Mark as read error:', error);
    return errorResponse(res, 500, 'Error marking notification as read', error.message);
  }
};

// Mark all notifications as read
const markAllAsRead = async (req, res) => {
  try {
    const db = getDB();
    const count = await Notification.markAllAsRead(db, req.user.userId);

    return successResponse(res, 200, `${count} notification(s) marked as read`);
  } catch (error) {
    console.error('Mark all as read error:', error);
    return errorResponse(res, 500, 'Error marking notifications as read', error.message);
  }
};

// Delete notification
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;

    const db = getDB();

    const notification = await Notification.findById(db, id);
    if (!notification) {
      return errorResponse(res, 404, 'Notification not found');
    }

    if (notification.userId.toString() !== req.user.userId) {
      return errorResponse(res, 403, 'You do not have permission to delete this notification');
    }

    await Notification.delete(db, id);

    return successResponse(res, 200, 'Notification deleted successfully');
  } catch (error) {
    console.error('Delete notification error:', error);
    return errorResponse(res, 500, 'Error deleting notification', error.message);
  }
};

// Get unread count
const getUnreadCount = async (req, res) => {
  try {
    const db = getDB();
    const count = await Notification.countUnread(db, req.user.userId);

    return successResponse(res, 200, 'Unread count retrieved successfully', { count });
  } catch (error) {
    console.error('Get unread count error:', error);
    return errorResponse(res, 500, 'Error fetching unread count', error.message);
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount
};

