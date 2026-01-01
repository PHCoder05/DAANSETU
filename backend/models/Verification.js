const { ObjectId } = require('mongodb');

/**
 * Verification Model - TWO-STEP VERIFICATION
 * Step 1: Government API auto-verification (Darpan, 80G, MCA)
 * Step 2: Admin manual review
 * 
 * NGO can see all steps and their status at any time
 */
class Verification {
    constructor(data) {
        this.userId = new ObjectId(data.userId);
        this.type = data.type; // email, phone, id_proof, ngo_registration, ngo_certificate

        // Overall status based on both steps
        // pending → api_verifying → api_verified/api_failed → admin_review → approved/rejected
        this.status = data.status || 'pending';

        // Documents
        this.documents = data.documents || [];

        // ═══════════════════════════════════════════════════════════════════
        // TWO-STEP VERIFICATION TRACKING
        // ═══════════════════════════════════════════════════════════════════

        this.steps = data.steps || {
            // Step 1: Government API Verification
            apiVerification: {
                status: 'pending', // pending, in_progress, passed, failed, skipped
                startedAt: null,
                completedAt: null,
                sources: [], // darpan, 80g, mca
                score: 0,
                confidence: null, // low, medium, high
                details: {},
                errors: []
            },
            // Step 2: Admin Manual Review
            adminReview: {
                status: 'pending', // pending, in_progress, approved, rejected
                assignedTo: null,
                startedAt: null,
                completedAt: null,
                notes: null,
                rejectionReason: null
            }
        };

        // Input data for verification
        this.verificationData = data.verificationData || {
            darpanId: null,
            pan: null,
            cin: null,
            registrationNumber: null
        };

        // Document details
        this.documentType = data.documentType || null;
        this.documentNumber = data.documentNumber || null;

        // Final verification
        this.verifiedBy = data.verifiedBy ? new ObjectId(data.verifiedBy) : null;
        this.verifiedAt = data.verifiedAt || null;
        this.rejectionReason = data.rejectionReason || null;
        this.expiresAt = data.expiresAt || null;

        // Timestamps
        this.createdAt = data.createdAt || new Date();
        this.updatedAt = data.updatedAt || new Date();
    }

    static collectionName = 'verifications';

    // ═══════════════════════════════════════════════════════════════════
    // CRUD Operations
    // ═══════════════════════════════════════════════════════════════════

    static async create(db, verificationData) {
        const verification = new Verification(verificationData);
        const result = await db.collection(this.collectionName).insertOne(verification);
        return { ...verification, _id: result.insertedId };
    }

    static async findById(db, id) {
        return await db.collection(this.collectionName).findOne({
            _id: new ObjectId(id)
        });
    }

    static async findByUser(db, userId, type = null) {
        const filter = { userId: new ObjectId(userId) };
        if (type) filter.type = type;

        return await db.collection(this.collectionName)
            .find(filter)
            .sort({ createdAt: -1 })
            .toArray();
    }

    static async update(db, id, updateData) {
        updateData.updatedAt = new Date();
        return await db.collection(this.collectionName).updateOne(
            { _id: new ObjectId(id) },
            { $set: updateData }
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    // TWO-STEP VERIFICATION FLOW
    // ═══════════════════════════════════════════════════════════════════

    static async requestVerification(db, userId, type, documents, documentInfo = {}) {
        // Check if pending verification already exists
        const existing = await db.collection(this.collectionName).findOne({
            userId: new ObjectId(userId),
            type,
            status: { $nin: ['approved', 'rejected', 'expired'] }
        });

        if (existing) {
            throw new Error('Verification already in progress');
        }

        return this.create(db, {
            userId,
            type,
            status: 'pending',
            documents,
            documentType: documentInfo.documentType,
            documentNumber: documentInfo.documentNumber,
            verificationData: {
                darpanId: documentInfo.darpanId,
                pan: documentInfo.pan,
                cin: documentInfo.cin,
                registrationNumber: documentInfo.documentNumber
            }
        });
    }

    /**
     * Step 1: Update API verification result
     */
    static async updateApiVerification(db, id, result) {
        const newStatus = result.overallVerified ? 'api_verified' : 'api_failed';

        return this.update(db, id, {
            status: newStatus,
            'steps.apiVerification': {
                status: result.overallVerified ? 'passed' : 'failed',
                startedAt: result.startedAt || new Date(),
                completedAt: new Date(),
                sources: result.sources || [],
                score: result.verificationScore || 0,
                confidence: result.confidence || 'low',
                details: result.details || {},
                errors: result.errors || []
            }
        });
    }

    /**
     * Step 2: Admin starts review
     */
    static async startAdminReview(db, id, adminId) {
        return this.update(db, id, {
            status: 'admin_review',
            'steps.adminReview.status': 'in_progress',
            'steps.adminReview.assignedTo': new ObjectId(adminId),
            'steps.adminReview.startedAt': new Date()
        });
    }

    /**
     * Step 2: Admin approves
     */
    static async approve(db, id, adminId, notes = null) {
        const verification = await this.findById(db, id);
        let expiresAt = null;

        if (['id_proof', 'ngo_registration', 'ngo_certificate'].includes(verification.type)) {
            expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year
        }

        await this.update(db, id, {
            status: 'approved',
            verifiedBy: adminId,
            verifiedAt: new Date(),
            expiresAt,
            'steps.adminReview': {
                status: 'approved',
                assignedTo: new ObjectId(adminId),
                completedAt: new Date(),
                notes
            }
        });

        // Update user's verification status
        try {
            const User = require('./User');
            await User.updateVerificationStatus(db, verification.userId, verification.type, true);
        } catch (e) {
            console.error('Failed to update user verification status:', e);
        }

        return this.findById(db, id);
    }

    /**
     * Step 2: Admin rejects
     */
    static async reject(db, id, adminId, reason) {
        await this.update(db, id, {
            status: 'rejected',
            verifiedBy: adminId,
            verifiedAt: new Date(),
            rejectionReason: reason,
            'steps.adminReview': {
                status: 'rejected',
                assignedTo: new ObjectId(adminId),
                completedAt: new Date(),
                rejectionReason: reason
            }
        });

        return this.findById(db, id);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Query Methods
    // ═══════════════════════════════════════════════════════════════════

    static async getPending(db, limit = 50) {
        // Get verifications that passed API check and need admin review
        return await db.collection(this.collectionName)
            .aggregate([
                {
                    $match: {
                        status: { $in: ['api_verified', 'admin_review'] }
                    }
                },
                { $sort: { createdAt: 1 } },
                { $limit: limit },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'userId',
                        foreignField: '_id',
                        as: 'user'
                    }
                },
                { $unwind: '$user' }
            ])
            .toArray();
    }

    /**
     * Get detailed verification steps for NGO to see progress
     */
    static async getVerificationSteps(db, userId, type = 'ngo_registration') {
        const verification = await db.collection(this.collectionName).findOne({
            userId: new ObjectId(userId),
            type
        });

        if (!verification) {
            return {
                started: false,
                steps: [
                    { step: 1, name: 'Submit Documents', status: 'not_started', description: 'Upload registration documents' },
                    { step: 2, name: 'Government Database Check', status: 'not_started', description: 'Auto-verify via Darpan, 80G, MCA' },
                    { step: 3, name: 'Admin Review', status: 'not_started', description: 'Final verification by admin' }
                ]
            };
        }

        const steps = [
            {
                step: 1,
                name: 'Submit Documents',
                status: 'completed',
                completedAt: verification.createdAt,
                description: 'Documents uploaded successfully'
            },
            {
                step: 2,
                name: 'Government Database Check',
                status: verification.steps?.apiVerification?.status || 'pending',
                startedAt: verification.steps?.apiVerification?.startedAt,
                completedAt: verification.steps?.apiVerification?.completedAt,
                description: this.getApiStepDescription(verification.steps?.apiVerification),
                sources: verification.steps?.apiVerification?.sources,
                score: verification.steps?.apiVerification?.score,
                confidence: verification.steps?.apiVerification?.confidence
            },
            {
                step: 3,
                name: 'Admin Review',
                status: verification.steps?.adminReview?.status || 'pending',
                startedAt: verification.steps?.adminReview?.startedAt,
                completedAt: verification.steps?.adminReview?.completedAt,
                description: this.getAdminStepDescription(verification.steps?.adminReview, verification.status),
                rejectionReason: verification.steps?.adminReview?.rejectionReason
            }
        ];

        return {
            started: true,
            verificationId: verification._id,
            overallStatus: verification.status,
            steps,
            currentStep: this.getCurrentStep(verification.status),
            isComplete: verification.status === 'approved',
            isRejected: verification.status === 'rejected'
        };
    }

    static getApiStepDescription(apiStep) {
        if (!apiStep || apiStep.status === 'pending') return 'Waiting to verify with government databases';
        if (apiStep.status === 'in_progress') return 'Checking Darpan, 80G, MCA databases...';
        if (apiStep.status === 'passed') return `Verified via ${apiStep.sources?.join(', ') || 'government databases'}`;
        if (apiStep.status === 'failed') return 'Could not verify automatically - proceeding to manual review';
        return 'Verification pending';
    }

    static getAdminStepDescription(adminStep, status) {
        if (status === 'approved') return 'Approved by admin';
        if (status === 'rejected') return 'Rejected by admin';
        if (adminStep?.status === 'in_progress') return 'Under review by admin';
        return 'Waiting for admin review';
    }

    static getCurrentStep(status) {
        switch (status) {
            case 'pending': return 1;
            case 'api_verifying': return 2;
            case 'api_verified':
            case 'api_failed': return 2;
            case 'admin_review': return 3;
            case 'approved':
            case 'rejected': return 3;
            default: return 1;
        }
    }

    static async getUserVerificationStatus(db, userId) {
        const verifications = await this.findByUser(db, userId);

        const status = {
            email: 'not_started',
            phone: 'not_started',
            id_proof: 'not_started',
            ngo_registration: 'not_started',
            ngo_certificate: 'not_started'
        };

        for (const v of verifications) {
            if (v.status === 'approved' && (!v.expiresAt || v.expiresAt > new Date())) {
                status[v.type] = 'verified';
            } else if (['pending', 'api_verifying', 'api_verified', 'admin_review'].includes(v.status)) {
                status[v.type] = 'in_progress';
            } else if (v.status === 'rejected') {
                status[v.type] = 'rejected';
            } else if (v.status === 'api_failed') {
                status[v.type] = 'needs_review';
            } else if (v.expiresAt && v.expiresAt < new Date()) {
                status[v.type] = 'expired';
            }
        }

        return status;
    }

    static async isFullyVerified(db, userId, role) {
        const status = await this.getUserVerificationStatus(db, userId);

        if (role === 'donor') {
            return status.email === 'verified' && status.phone === 'verified';
        } else if (role === 'ngo') {
            return status.email === 'verified' &&
                status.phone === 'verified' &&
                status.ngo_registration === 'verified';
        }

        return false;
    }
}

module.exports = Verification;

