const { ObjectId } = require('mongodb');

/**
 * Report Model
 * Handles manual reports for fraud, abuse, or issues
 */
class Report {
  constructor(data) {
    this.reporterId = new ObjectId(data.reporterId);
    this.targetId = new ObjectId(data.targetId); // ID of User, Donation, or Request being reported
    this.targetType = data.targetType; // 'user', 'donation', 'request'
    
    this.reason = data.reason; // 'fraud', 'abuse', 'spam', 'wrong_details', 'spoiled_food', 'unprofessional_behavior', 'other'
    this.description = data.description || '';
    
    this.evidence = data.evidence || []; // Array of image URLs/document links
    
    this.status = data.status || 'pending'; // 'pending', 'investigating', 'resolved', 'dismissed'
    this.severity = data.severity || 'medium'; // 'low', 'medium', 'high'
    
    this.resolution = data.resolution || null;
    this.resolvedBy = data.resolvedBy ? new ObjectId(data.resolvedBy) : null;
    this.resolvedAt = data.resolvedAt || null;
    
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static collectionName = 'reports';

  static async create(db, reportData) {
    const report = new Report(reportData);
    const result = await db.collection(this.collectionName).insertOne(report);
    return { ...report, _id: result.insertedId };
  }

  static async findById(db, id) {
    return await db.collection(this.collectionName).findOne({ _id: new ObjectId(id) });
  }

  static async getReports(db, filter = {}, options = {}) {
    const { skip = 0, limit = 10, sort = { createdAt: -1 } } = options;
    return await db.collection(this.collectionName)
      .aggregate([
        { $match: filter },
        { $sort: sort },
        { $skip: skip },
        { $limit: limit },
        {
          $lookup: {
            from: 'users',
            localField: 'reporterId',
            foreignField: '_id',
            as: 'reporter'
          }
        },
        { $unwind: '$reporter' },
        {
          $project: {
            'reporter.password': 0,
            'reporter.fcmTokens': 0
          }
        }
      ])
      .toArray();
  }

  static async updateStatus(db, id, status, adminId, resolution) {
    return await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(id) },
      { 
        $set: { 
          status, 
          resolvedBy: new ObjectId(adminId),
          resolution,
          resolvedAt: new Date(),
          updatedAt: new Date()
        } 
      }
    );
  }
}

module.exports = Report;
