const { getDB } = require('../config/db');
const Report = require('../models/Report');
const Notification = require('../models/Notification');
const { successResponse, errorResponse } = require('../utils/helpers');

/**
 * Submit a new report
 */
const submitReport = async (req, res) => {
  try {
    const { targetId, targetType, reason, description, evidence } = req.body;
    const db = getDB();

    const report = await Report.create(db, {
      reporterId: req.user.userId,
      targetId,
      targetType,
      reason,
      description,
      evidence
    });

    // Notify Admins
    const admins = await db.collection('users').find({ role: 'admin' }).toArray();
    for (const admin of admins) {
      await Notification.create(db, {
        userId: admin._id,
        type: 'admin',
        title: 'New Report Submitted',
        message: `A new ${targetType} report has been filed for reason: ${reason}.`,
        data: { reportId: report._id }
      });
    }

    return successResponse(res, 201, 'Report submitted successfully. Our team will investigate.', { report });
  } catch (error) {
    console.error('Submit report error:', error);
    return errorResponse(res, 500, 'Error submitting report', error.message);
  }
};

/**
 * Get reports (Admin only)
 */
const getAllReports = async (req, res) => {
  try {
    const { status, targetType, page = 1, limit = 10 } = req.query;
    const db = getDB();

    const filter = {};
    if (status) filter.status = status;
    if (targetType) filter.targetType = targetType;

    const reports = await Report.getReports(db, filter, {
      skip: (parseInt(page) - 1) * parseInt(limit),
      limit: parseInt(limit)
    });

    const total = await db.collection(Report.collectionName).countDocuments(filter);

    return successResponse(res, 200, 'Reports retrieved', {
      reports,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get reports error:', error);
    return errorResponse(res, 500, 'Error fetching reports', error.message);
  }
};

/**
 * Resolve a report (Admin only)
 */
const resolveReport = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolution } = req.body; // status: 'resolved' or 'dismissed'
    const db = getDB();

    const result = await Report.updateStatus(db, id, status, req.user.userId, resolution);

    if (result.matchedCount === 0) {
      return errorResponse(res, 404, 'Report not found');
    }

    // Notify the reporter
    const report = await Report.findById(db, id);
    await Notification.create(db, {
      userId: report.reporterId,
      type: 'system',
      title: 'Report Update',
      message: `Your report regarding a ${report.targetType} has been ${status}. Resolution: ${resolution}`,
      data: { reportId: id }
    });

    return successResponse(res, 200, `Report ${status} successfully`);
  } catch (error) {
    console.error('Resolve report error:', error);
    return errorResponse(res, 500, 'Error resolving report', error.message);
  }
};

module.exports = {
  submitReport,
  getAllReports,
  resolveReport
};
