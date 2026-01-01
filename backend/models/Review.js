const { ObjectId } = require('mongodb');

class Review {
  constructor(data) {
    this.donorId = new ObjectId(data.donorId);
    this.ngoId = new ObjectId(data.ngoId);
    this.donationId = new ObjectId(data.donationId);
    this.rating = data.rating; // 1-5
    this.comment = data.comment || null;
    this.response = data.response || null; // NGO response to review
    this.respondedAt = data.respondedAt || null;
    this.helpful = data.helpful || 0; // Helpful count
    this.reported = data.reported || false;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static collectionName = 'reviews';

  static async create(db, reviewData) {
    const review = new Review(reviewData);
    const result = await db.collection(this.collectionName).insertOne(review);
    return { ...review, _id: result.insertedId };
  }

  static async findById(db, id) {
    try {
      return await db.collection(this.collectionName).findOne({
        _id: new ObjectId(id)
      });
    } catch (error) {
      return null;
    }
  }

  static async findByNGO(db, ngoId, options = {}) {
    const { skip = 0, limit = 10, sort = { createdAt: -1 } } = options;
    return await db.collection(this.collectionName)
      .find({ ngoId: new ObjectId(ngoId), reported: false })
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .toArray();
  }

  static async getAverageRating(db, ngoId) {
    const result = await db.collection(this.collectionName).aggregate([
      { $match: { ngoId: new ObjectId(ngoId), reported: false } },
      {
        $group: {
          _id: null,
          avgRating: { $avg: '$rating' },
          totalReviews: { $sum: 1 },
          ratings: {
            $push: '$rating'
          }
        }
      }
    ]).toArray();

    if (result.length === 0) {
      return { avgRating: 0, totalReviews: 0, distribution: {} };
    }

    const { avgRating, totalReviews, ratings } = result[0];

    // Calculate rating distribution
    const distribution = ratings.reduce((acc, rating) => {
      acc[rating] = (acc[rating] || 0) + 1;
      return acc;
    }, {});

    return {
      avgRating: Math.round(avgRating * 10) / 10,
      totalReviews,
      distribution
    };
  }

  static async update(db, id, updateData) {
    updateData.updatedAt = new Date();
    const result = await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(id) },
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

  static async checkExisting(db, donorId, donationId) {
    return await db.collection(this.collectionName).findOne({
      donorId: new ObjectId(donorId),
      donationId: new ObjectId(donationId)
    });
  }
}

module.exports = Review;

