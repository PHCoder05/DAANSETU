const { ObjectId } = require('mongodb');

class Request {
  constructor(data) {
    this.ngoId = new ObjectId(data.ngoId);
    this.donationId = new ObjectId(data.donationId);
    this.message = data.message || null;
    this.status = data.status || 'pending'; // 'pending', 'approved', 'rejected', 'cancelled'
    this.priority = data.priority || 'normal'; // 'low', 'normal', 'high', 'urgent'
    this.needByDate = data.needByDate || null;
    this.beneficiariesCount = data.beneficiariesCount || null;
    this.notes = data.notes || null;
    
    // Response from donor
    this.response = data.response || null;
    this.respondedAt = data.respondedAt || null;
    
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static collectionName = 'requests';

  static async findById(db, id) {
    try {
      return await db.collection(this.collectionName).findOne({ 
        _id: new ObjectId(id) 
      });
    } catch (error) {
      return null;
    }
  }

  static async create(db, requestData) {
    const request = new Request(requestData);
    const result = await db.collection(this.collectionName).insertOne(request);
    return { ...request, _id: result.insertedId };
  }

  static async update(db, id, updateData) {
    updateData.updatedAt = new Date();
    const result = await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(id) },
      { $set: updateData }
    );
    return result.modifiedCount > 0;
  }

  static async findAll(db, filter = {}, options = {}) {
    const { skip = 0, limit = 10, sort = { createdAt: -1 } } = options;
    return await db.collection(this.collectionName)
      .find(filter)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .toArray();
  }

  static async findWithDetails(db, filter = {}, options = {}) {
    const { skip = 0, limit = 10, sort = { createdAt: -1 } } = options;
    return await db.collection(this.collectionName)
      .aggregate([
        { $match: filter },
        {
          $lookup: {
            from: 'users',
            localField: 'ngoId',
            foreignField: '_id',
            as: 'ngo'
          }
        },
        { $unwind: { path: '$ngo', preserveNullAndEmptyArrays: true } },
        {
          $lookup: {
            from: 'donations',
            localField: 'donationId',
            foreignField: '_id',
            as: 'donation'
          }
        },
        { $unwind: { path: '$donation', preserveNullAndEmptyArrays: true } },
        { $sort: sort },
        { $skip: skip },
        { $limit: limit },
        {
          $project: {
            'ngo.password': 0
          }
        }
      ])
      .toArray();
  }

  static async count(db, filter = {}) {
    return await db.collection(this.collectionName).countDocuments(filter);
  }

  static async updateStatus(db, requestId, status, response = null) {
    const updateData = {
      status,
      updatedAt: new Date()
    };
    
    if (response) {
      updateData.response = response;
      updateData.respondedAt = new Date();
    }
    
    const result = await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(requestId) },
      { $set: updateData }
    );
    return result.modifiedCount > 0;
  }

  static async delete(db, id) {
    const result = await db.collection(this.collectionName).deleteOne({ 
      _id: new ObjectId(id) 
    });
    return result.deletedCount > 0;
  }
}

module.exports = Request;

