const { ObjectId } = require('mongodb');

class ImpactStory {
  constructor(data) {
    this.ngoId        = new ObjectId(data.ngoId);
    this.donationId   = data.donationId ? new ObjectId(data.donationId) : null;
    this.title        = data.title;
    this.story        = data.story;           // Rich description text
    this.photos       = data.photos || [];    // Array of image URLs / base64
    this.category     = data.category || 'general'; // food, clothes, books, etc.
    this.beneficiariesCount = data.beneficiariesCount || 0;
    this.location     = data.location || null; // { city, state }
    this.likes        = data.likes || [];     // Array of userIds who liked
    this.likesCount   = data.likesCount || 0;
    this.comments     = data.comments || [];  // [{ userId, text, createdAt }]
    this.isPublished  = data.isPublished !== undefined ? data.isPublished : true;
    this.createdAt    = data.createdAt || new Date();
    this.updatedAt    = data.updatedAt || new Date();
  }

  static collectionName = 'impact_stories';

  static async create(db, data) {
    const story = new ImpactStory(data);
    const result = await db.collection(this.collectionName).insertOne(story);
    return { ...story, _id: result.insertedId };
  }

  static async findById(db, id) {
    try {
      return await db.collection(this.collectionName).findOne({ _id: new ObjectId(id) });
    } catch {
      return null;
    }
  }

  static async findAll(db, filter = {}, options = {}) {
    const { skip = 0, limit = 10, sort = { createdAt: -1 } } = options;
    return await db.collection(this.collectionName)
      .aggregate([
        { $match: { isPublished: true, ...filter } },
        { $sort: sort },
        { $skip: skip },
        { $limit: limit },
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
        {
          $project: {
            'ngo.password': 0, 'ngo.phone': 0, 'ngo.email': 0,
            'ngo.ngoDetails.documents': 0, 'ngo.address': 0
          }
        }
      ]).toArray();
  }

  static async toggleLike(db, storyId, userId) {
    const userObjId = new ObjectId(userId);
    const story = await this.findById(db, storyId);
    if (!story) return null;

    const hasLiked = story.likes.some(id => id.toString() === userId);
    if (hasLiked) {
      await db.collection(this.collectionName).updateOne(
        { _id: new ObjectId(storyId) },
        { $pull: { likes: userObjId }, $inc: { likesCount: -1 } }
      );
      return { liked: false };
    } else {
      await db.collection(this.collectionName).updateOne(
        { _id: new ObjectId(storyId) },
        { $addToSet: { likes: userObjId }, $inc: { likesCount: 1 } }
      );
      return { liked: true };
    }
  }

  static async addComment(db, storyId, userId, text) {
    const comment = {
      _id: new ObjectId(),
      userId: new ObjectId(userId),
      text,
      createdAt: new Date()
    };
    await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(storyId) },
      { $push: { comments: comment }, $set: { updatedAt: new Date() } }
    );
    return comment;
  }

  static async count(db, filter = {}) {
    return await db.collection(this.collectionName).countDocuments({ isPublished: true, ...filter });
  }

  static async delete(db, id) {
    const result = await db.collection(this.collectionName).deleteOne({ _id: new ObjectId(id) });
    return result.deletedCount > 0;
  }
}

module.exports = ImpactStory;
