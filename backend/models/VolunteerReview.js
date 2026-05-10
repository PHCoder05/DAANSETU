const { ObjectId } = require('mongodb');

/**
 * VolunteerReview Model
 * Tracks ratings for volunteers from donors and NGOs
 */
class VolunteerReview {
  constructor(data) {
    this.volunteerId = new ObjectId(data.volunteerId);
    this.reviewerId = new ObjectId(data.reviewerId);
    this.reviewerRole = data.reviewerRole; // 'donor' or 'ngo'
    this.donationId = new ObjectId(data.donationId);
    this.rating = data.rating; // 1-5
    this.comment = data.comment || null;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static collectionName = 'volunteer_reviews';

  /**
   * Create a new volunteer review
   */
  static async create(db, reviewData) {
    const review = new VolunteerReview(reviewData);
    const result = await db.collection(this.collectionName).insertOne(review);
    return { ...review, _id: result.insertedId };
  }

  /**
   * Find a review by its ID
   */
  static async findById(db, id) {
    try {
      return await db.collection(this.collectionName).findOne({
        _id: new ObjectId(id)
      });
    } catch (error) {
      return null;
    }
  }

  /**
   * Get reviews for a volunteer
   */
  static async findByVolunteer(db, volunteerId, options = {}) {
    const { skip = 0, limit = 10, sort = { createdAt: -1 } } = options;
    return await db.collection(this.collectionName)
      .find({ volunteerId: new ObjectId(volunteerId) })
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .toArray();
  }

  /**
   * Calculate average rating for a volunteer
   */
  static async getAverageRating(db, volunteerId) {
    const result = await db.collection(this.collectionName).aggregate([
      { $match: { volunteerId: new ObjectId(volunteerId) } },
      {
        $group: {
          _id: null,
          avgRating: { $avg: '$rating' },
          totalReviews: { $sum: 1 }
        }
      }
    ]).toArray();

    if (result.length === 0) {
      return { avgRating: 0, totalReviews: 0 };
    }

    return {
      avgRating: Math.round(result[0].avgRating * 10) / 10,
      totalReviews: result[0].totalReviews
    };
  }

  /**
   * Check if a reviewer already reviewed a specific volunteer for a donation
   */
  static async checkExisting(db, reviewerId, donationId) {
    return await db.collection(this.collectionName).findOne({
      reviewerId: new ObjectId(reviewerId),
      donationId: new ObjectId(donationId)
    });
  }
}

module.exports = VolunteerReview;
