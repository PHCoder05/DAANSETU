const { ObjectId } = require('mongodb');

class Donation {
  constructor(data) {
    this.donorId = new ObjectId(data.donorId);
    this.title = data.title;
    this.description = data.description;
    this.category = data.category; // 'food', 'clothes', 'books', 'medical', 'electronics', 'furniture', 'other'
    this.quantity = data.quantity || null;
    this.unit = data.unit || null; // 'kg', 'pieces', 'boxes', etc.
    this.images = data.images || [];
    this.condition = data.condition || 'good'; // 'new', 'good', 'fair', 'used'
    this.expiryDate = data.expiryDate || null; // for food items

    // Location
    this.pickupLocation = data.pickupLocation; // { lat, lng, address }
    this.pickupInstructions = data.pickupInstructions || null;

    // Status
    this.status = data.status || 'available'; // 'available', 'claimed', 'in-transit', 'delivered', 'cancelled'
    this.claimedBy = data.claimedBy ? new ObjectId(data.claimedBy) : null; // NGO ID
    this.claimedAt = data.claimedAt || null;

    // Delivery tracking
    this.deliveryStatus = data.deliveryStatus || null;
    this.deliveryDate = data.deliveryDate || null;
    this.deliveryNotes = data.deliveryNotes || null;
    this.deliveryImages = data.deliveryImages || [];

    // Metadata
    this.priority = data.priority || 'normal'; // 'low', 'normal', 'high', 'urgent'
    this.tags = data.tags || [];
    this.active = data.active !== undefined ? data.active : true;
    this.views = data.views || 0;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static collectionName = 'donations';

  static async findById(db, id) {
    try {
      return await db.collection(this.collectionName).findOne({
        _id: new ObjectId(id)
      });
    } catch (error) {
      return null;
    }
  }

  static async create(db, donationData) {
    const donation = new Donation(donationData);
    const result = await db.collection(this.collectionName).insertOne(donation);
    return { ...donation, _id: result.insertedId };
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

  static async findWithDonorDetails(db, filter = {}, options = {}) {
    const { skip = 0, limit = 10, sort = { createdAt: -1 } } = options;
    return await db.collection(this.collectionName)
      .aggregate([
        { $match: filter },
        {
          $lookup: {
            from: 'users',
            localField: 'donorId',
            foreignField: '_id',
            as: 'donor'
          }
        },
        { $unwind: { path: '$donor', preserveNullAndEmptyArrays: true } },
        {
          $lookup: {
            from: 'users',
            localField: 'claimedBy',
            foreignField: '_id',
            as: 'ngo'
          }
        },
        { $unwind: { path: '$ngo', preserveNullAndEmptyArrays: true } },
        { $sort: sort },
        { $skip: skip },
        { $limit: limit },
        {
          $project: {
            'donor.password': 0,
            'ngo.password': 0
          }
        }
      ])
      .toArray();
  }

  static async count(db, filter = {}) {
    return await db.collection(this.collectionName).countDocuments(filter);
  }

  static async incrementViews(db, id) {
    await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(id) },
      { $inc: { views: 1 } }
    );
  }

  static async claim(db, donationId, ngoId) {
    const result = await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(donationId), status: 'available' },
      {
        $set: {
          status: 'claimed',
          claimedBy: new ObjectId(ngoId),
          claimedAt: new Date(),
          updatedAt: new Date()
        }
      }
    );
    return result.modifiedCount > 0;
  }

  static async updateStatus(db, donationId, status, additionalData = {}) {
    const updateData = {
      status,
      updatedAt: new Date(),
      ...additionalData
    };

    const result = await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(donationId) },
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

  // Find nearby donations based on location
  static async findNearby(db, lat, lng, maxDistance = 50000, options = {}) {
    // maxDistance in meters (default 50km)
    const { skip = 0, limit = 10 } = options;

    return await db.collection(this.collectionName)
      .find({
        status: 'available',
        active: true,
        'pickupLocation.lat': { $exists: true },
        'pickupLocation.lng': { $exists: true }
      })
      .skip(skip)
      .limit(limit)
      .toArray();
  }
}

module.exports = Donation;

