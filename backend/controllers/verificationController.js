const { getDB } = require('../config/db');
const Verification = require('../models/Verification');
const FraudAlert = require('../models/FraudAlert');
const NgoVerificationService = require('../services/ngoVerificationService');
const { successResponse, errorResponse } = require('../utils/helpers');
const { logActivity } = require('../middleware/activityLogger');

/**
 * Request verification
 */
const requestVerification = async (req, res) => {
    try {
        const { type, documents, documentType, documentNumber, darpanId, pan, cin } = req.body;
        const db = getDB();

        // For NGO verification types, run auto-verification first
        let autoVerifyResult = null;
        if (['ngo_registration', 'ngo_certificate'].includes(type)) {
            autoVerifyResult = await NgoVerificationService.verifyNgo({
                darpanId,
                pan,
                cin,
                registrationNumber: documentNumber
            });
        }

        const verification = await Verification.requestVerification(
            db,
            req.user.userId,
            type,
            documents,
            {
                documentType,
                documentNumber,
                autoVerification: autoVerifyResult
            }
        );

        // If high confidence auto-verification, mark as pre-approved
        if (autoVerifyResult?.confidence === 'high') {
            await db.collection('verifications').updateOne(
                { _id: verification._id },
                {
                    $set: {
                        status: 'auto_verified',
                        autoVerificationResult: autoVerifyResult,
                        updatedAt: new Date()
                    }
                }
            );
            verification.status = 'auto_verified';
        }

        await logActivity(req, 'verification_requested', 'verification', verification._id, {
            type,
            autoVerified: autoVerifyResult?.overallVerified || false
        });

        return successResponse(res, 201, 'Verification request submitted', {
            verification,
            autoVerification: autoVerifyResult
        });
    } catch (error) {
        console.error('Request verification error:', error);
        return errorResponse(res, 500, error.message || 'Error submitting verification request');
    }
};

/**
 * Auto-verify NGO using government APIs
 * This runs BEFORE admin review
 */
const autoVerifyNgo = async (req, res) => {
    try {
        const { darpanId, pan, cin, registrationNumber } = req.body;

        if (!darpanId && !pan && !cin) {
            return errorResponse(res, 400, 'At least one identifier required: darpanId, pan, or cin');
        }

        const result = await NgoVerificationService.verifyNgo({
            darpanId,
            pan,
            cin,
            registrationNumber
        });

        // Store verification attempt
        const db = getDB();
        await db.collection('ngo_verification_attempts').insertOne({
            userId: req.user.userId,
            input: { darpanId, pan, cin, registrationNumber },
            result,
            createdAt: new Date()
        });

        await logActivity(req, 'ngo_auto_verify', 'verification', null, {
            verified: result.overallVerified,
            confidence: result.confidence,
            sources: result.sources
        });

        return successResponse(res, 200, 'NGO verification complete', {
            verification: result
        });
    } catch (error) {
        console.error('Auto verify NGO error:', error);
        return errorResponse(res, 500, 'Error verifying NGO', error.message);
    }
};

/**
 * Verify Darpan ID only
 */
const verifyDarpanId = async (req, res) => {
    try {
        const { darpanId } = req.body;

        if (!darpanId) {
            return errorResponse(res, 400, 'Darpan ID is required');
        }

        const result = await NgoVerificationService.verifyDarpanId(darpanId);

        return successResponse(res, 200, 'Darpan verification complete', { result });
    } catch (error) {
        console.error('Verify Darpan ID error:', error);
        return errorResponse(res, 500, 'Error verifying Darpan ID', error.message);
    }
};

/**
 * Verify 80G certificate
 */
const verify80G = async (req, res) => {
    try {
        const { pan } = req.body;

        if (!pan) {
            return errorResponse(res, 400, 'PAN number is required');
        }

        const result = await NgoVerificationService.verify80GByPan(pan);

        return successResponse(res, 200, '80G verification complete', { result });
    } catch (error) {
        console.error('Verify 80G error:', error);
        return errorResponse(res, 500, 'Error verifying 80G certificate', error.message);
    }
};

/**
 * Get verification steps progress (for NGO to see their verification journey)
 */
const getVerificationSteps = async (req, res) => {
    try {
        const { type = 'ngo_registration' } = req.query;
        const db = getDB();

        const steps = await Verification.getVerificationSteps(db, req.user.userId, type);

        return successResponse(res, 200, 'Verification steps retrieved', steps);
    } catch (error) {
        console.error('Get verification steps error:', error);
        return errorResponse(res, 500, 'Error fetching verification steps', error.message);
    }
};

/**
 * Get my verification status
 */
const getMyVerificationStatus = async (req, res) => {
    try {
        const db = getDB();
        const status = await Verification.getUserVerificationStatus(db, req.user.userId);
        const verifications = await Verification.findByUser(db, req.user.userId);

        // Also get detailed steps for NGO types
        let ngoSteps = null;
        if (req.user.role === 'ngo') {
            ngoSteps = await Verification.getVerificationSteps(db, req.user.userId, 'ngo_registration');
        }

        return successResponse(res, 200, 'Verification status retrieved', {
            status,
            verifications,
            ngoVerificationSteps: ngoSteps
        });
    } catch (error) {
        console.error('Get verification status error:', error);
        return errorResponse(res, 500, 'Error fetching verification status', error.message);
    }
};

/**
 * Admin: Get pending verifications
 */
const getPendingVerifications = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const db = getDB();
        const pending = await Verification.getPending(db);

        return successResponse(res, 200, 'Pending verifications retrieved', { verifications: pending });
    } catch (error) {
        console.error('Get pending verifications error:', error);
        return errorResponse(res, 500, 'Error fetching pending verifications', error.message);
    }
};

/**
 * Admin: Approve verification
 */
const approveVerification = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const { id } = req.params;
        const db = getDB();

        const verification = await Verification.approve(db, id, req.user.userId);

        await logActivity(req, 'verification_approved', 'verification', id, {});

        return successResponse(res, 200, 'Verification approved', { verification });
    } catch (error) {
        console.error('Approve verification error:', error);
        return errorResponse(res, 500, 'Error approving verification', error.message);
    }
};

/**
 * Admin: Reject verification
 */
const rejectVerification = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const { id } = req.params;
        const { reason } = req.body;
        const db = getDB();

        const verification = await Verification.reject(db, id, req.user.userId, reason);

        await logActivity(req, 'verification_rejected', 'verification', id, { reason });

        return successResponse(res, 200, 'Verification rejected', { verification });
    } catch (error) {
        console.error('Reject verification error:', error);
        return errorResponse(res, 500, 'Error rejecting verification', error.message);
    }
};

// ═══════════════════════════════════════════════════════════════════
// Admin Bypass & Override Functions
// ═══════════════════════════════════════════════════════════════════

/**
 * Admin: Bypass government API verification and directly approve
 * REQUIRES: reason, supporting evidence documents
 * Creates detailed audit trail for compliance
 */
const adminBypassVerification = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const { id } = req.params;
        const { reason, evidenceDocuments, notes } = req.body;

        if (!reason || reason.length < 10) {
            return errorResponse(res, 400, 'Detailed bypass reason required (min 10 characters)');
        }

        const db = getDB();
        const verification = await Verification.findById(db, id);

        if (!verification) {
            return errorResponse(res, 404, 'Verification not found');
        }

        // Update verification with bypass
        await db.collection('verifications').updateOne(
            { _id: verification._id },
            {
                $set: {
                    status: 'approved',
                    verifiedBy: req.user.userId,
                    verifiedAt: new Date(),
                    updatedAt: new Date(),
                    'steps.apiVerification': {
                        status: 'bypassed',
                        bypassedBy: req.user.userId,
                        bypassedAt: new Date(),
                        bypassReason: reason
                    },
                    'steps.adminReview': {
                        status: 'approved',
                        assignedTo: req.user.userId,
                        completedAt: new Date(),
                        notes,
                        bypassUsed: true
                    },
                    adminBypass: {
                        used: true,
                        adminId: req.user.userId,
                        reason,
                        evidenceDocuments: evidenceDocuments || [],
                        timestamp: new Date()
                    }
                }
            }
        );

        // Create detailed audit log for bypass
        await logActivity(req, 'admin_bypass_verification', 'verification', id, {
            bypassReason: reason,
            hasEvidence: !!evidenceDocuments?.length,
            previousStatus: verification.status,
            ngoUserId: verification.userId
        });

        // Update user's verification status
        try {
            const User = require('../models/User');
            await User.updateVerificationStatus(db, verification.userId, verification.type, true);
        } catch (e) {
            console.error('Failed to update user verification status:', e);
        }

        // Create notification for NGO
        const Notification = require('../models/Notification');
        await Notification.create(db, {
            userId: verification.userId,
            type: 'verification',
            title: 'Verification Approved',
            message: 'Your NGO verification has been approved by admin!',
            data: { verificationId: id, bypassUsed: true }
        });

        return successResponse(res, 200, 'Verification bypassed and approved', {
            verification: await Verification.findById(db, id)
        });
    } catch (error) {
        console.error('Admin bypass verification error:', error);
        return errorResponse(res, 500, 'Error bypassing verification', error.message);
    }
};

/**
 * Admin: Force re-run government API verification
 */
const adminRerunApiVerification = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const { id } = req.params;
        const db = getDB();
        const verification = await Verification.findById(db, id);

        if (!verification) {
            return errorResponse(res, 404, 'Verification not found');
        }

        // Re-run API verification
        const result = await NgoVerificationService.verifyNgo({
            darpanId: verification.verificationData?.darpanId,
            pan: verification.verificationData?.pan,
            cin: verification.verificationData?.cin,
            registrationNumber: verification.verificationData?.registrationNumber
        });

        // Update verification with new results
        await Verification.updateApiVerification(db, id, result);

        await logActivity(req, 'admin_rerun_api_verification', 'verification', id, {
            result: result.overallVerified,
            confidence: result.confidence
        });

        return successResponse(res, 200, 'API verification re-run complete', {
            verification: await Verification.findById(db, id),
            apiResult: result
        });
    } catch (error) {
        console.error('Admin rerun API verification error:', error);
        return errorResponse(res, 500, 'Error re-running verification', error.message);
    }
};

// ═══════════════════════════════════════════════════════════════════
// NGO Support Contact System
// ═══════════════════════════════════════════════════════════════════

/**
 * NGO: Request support / contact admin for verification issues
 */
const requestSupport = async (req, res) => {
    try {
        const { verificationId, issue, message, contactEmail, contactPhone } = req.body;
        const db = getDB();

        if (!issue || !message) {
            return errorResponse(res, 400, 'Issue type and message are required');
        }

        // Create support ticket
        const supportRequest = {
            userId: req.user.userId,
            verificationId: verificationId ? new (require('mongodb').ObjectId)(verificationId) : null,
            issue, // api_verification_failed, documents_rejected, other
            message,
            contactEmail: contactEmail || req.user.email,
            contactPhone,
            status: 'open', // open, in_progress, resolved, closed
            priority: 'normal',
            assignedTo: null,
            responses: [],
            createdAt: new Date(),
            updatedAt: new Date()
        };

        const result = await db.collection('support_requests').insertOne(supportRequest);

        // If verification exists, link the support request
        if (verificationId) {
            await db.collection('verifications').updateOne(
                { _id: new (require('mongodb').ObjectId)(verificationId) },
                {
                    $set: { hasSupportRequest: true },
                    $push: { supportRequestIds: result.insertedId }
                }
            );
        }

        await logActivity(req, 'support_request_created', 'support', result.insertedId, { issue });

        return successResponse(res, 201, 'Support request submitted. Our team will contact you soon.', {
            requestId: result.insertedId
        });
    } catch (error) {
        console.error('Request support error:', error);
        return errorResponse(res, 500, 'Error submitting support request', error.message);
    }
};

/**
 * NGO: Get my support requests
 */
const getMySupportRequests = async (req, res) => {
    try {
        const db = getDB();
        const requests = await db.collection('support_requests')
            .find({ userId: req.user.userId })
            .sort({ createdAt: -1 })
            .toArray();

        return successResponse(res, 200, 'Support requests retrieved', { requests });
    } catch (error) {
        console.error('Get my support requests error:', error);
        return errorResponse(res, 500, 'Error fetching support requests', error.message);
    }
};

/**
 * Admin: Get all support requests
 */
const getAllSupportRequests = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const { status = 'open' } = req.query;
        const db = getDB();

        const requests = await db.collection('support_requests')
            .aggregate([
                { $match: status === 'all' ? {} : { status } },
                { $sort: { createdAt: -1 } },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'userId',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                { $unwind: { path: '$user', preserveNullAndEmptyArrays: true } },
                {
                    $lookup: {
                        from: 'verifications',
                        localField: 'verificationId',
                        foreignField: '_id',
                        as: 'verification'
                    }
                },
                { $unwind: { path: '$verification', preserveNullAndEmptyArrays: true } }
            ])
            .toArray();

        return successResponse(res, 200, 'Support requests retrieved', { requests });
    } catch (error) {
        console.error('Get all support requests error:', error);
        return errorResponse(res, 500, 'Error fetching support requests', error.message);
    }
};

/**
 * Admin: Respond to support request
 */
const respondToSupport = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const { id } = req.params;
        const { message, newStatus } = req.body;
        const db = getDB();

        const { ObjectId } = require('mongodb');

        await db.collection('support_requests').updateOne(
            { _id: new ObjectId(id) },
            {
                $set: {
                    status: newStatus || 'in_progress',
                    assignedTo: req.user.userId,
                    updatedAt: new Date()
                },
                $push: {
                    responses: {
                        adminId: req.user.userId,
                        message,
                        timestamp: new Date()
                    }
                }
            }
        );

        // Create notification for NGO
        const request = await db.collection('support_requests').findOne({ _id: new ObjectId(id) });
        if (request) {
            const Notification = require('../models/Notification');
            await Notification.create(db, {
                userId: request.userId,
                type: 'support',
                title: 'Support Response',
                message: 'Admin has responded to your support request',
                data: { supportRequestId: id }
            });
        }

        await logActivity(req, 'support_response', 'support', id, { newStatus });

        return successResponse(res, 200, 'Response sent');
    } catch (error) {
        console.error('Respond to support error:', error);
        return errorResponse(res, 500, 'Error responding to support', error.message);
    }
};

// ═══════════════════════════════════════════════════════════════════
// Fraud Alert endpoints
// ═══════════════════════════════════════════════════════════════════

/**
 * Admin: Get open fraud alerts
 */
const getFraudAlerts = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const { severity } = req.query;
        const db = getDB();
        const alerts = await FraudAlert.getOpenAlerts(db, severity);

        return successResponse(res, 200, 'Fraud alerts retrieved', { alerts });
    } catch (error) {
        console.error('Get fraud alerts error:', error);
        return errorResponse(res, 500, 'Error fetching fraud alerts', error.message);
    }
};

/**
 * Admin: Resolve fraud alert
 */
const resolveFraudAlert = async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return errorResponse(res, 403, 'Admin access required');
        }

        const { id } = req.params;
        const { resolution, isFalsePositive } = req.body;
        const db = getDB();

        await FraudAlert.resolve(db, id, req.user.userId, resolution, isFalsePositive);

        await logActivity(req, 'fraud_alert_resolved', 'fraud_alert', id, { resolution, isFalsePositive });

        return successResponse(res, 200, 'Fraud alert resolved');
    } catch (error) {
        console.error('Resolve fraud alert error:', error);
        return errorResponse(res, 500, 'Error resolving fraud alert', error.message);
    }
};

/**
 * Upload verification document
 */
const uploadVerificationDocument = async (req, res) => {
    try {
        if (!req.file) {
            return errorResponse(res, 400, 'No file uploaded');
        }

        const fileUrl = `/uploads/verification/${req.file.filename}`;
        
        return successResponse(res, 200, 'Document uploaded successfully', {
            url: fileUrl,
            filename: req.file.originalname,
            mimetype: req.file.mimetype
        });
    } catch (error) {
        console.error('Upload document error:', error);
        return errorResponse(res, 500, 'Error uploading document');
    }
};

module.exports = {
    requestVerification,
    autoVerifyNgo,
    verifyDarpanId,
    verify80G,
    getVerificationSteps,
    getMyVerificationStatus,
    getPendingVerifications,
    approveVerification,
    rejectVerification,
    // Admin bypass & override
    adminBypassVerification,
    adminRerunApiVerification,
    // Support system
    requestSupport,
    getMySupportRequests,
    getAllSupportRequests,
    respondToSupport,
    // Fraud alerts
    getFraudAlerts,
    resolveFraudAlert,
    uploadVerificationDocument
};
