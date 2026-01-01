const { ObjectId } = require('mongodb');

class User {
  constructor(data) {
    this.email = data.email;
    this.password = data.password; // hashed
    this.name = data.name;
    this.role = data.role; // 'donor', 'ngo', 'admin'
    this.phone = data.phone || null;
    this.address = data.address || null;
    this.location = data.location || null; // { lat, lng, address }
    this.profileImage = data.profileImage || null;
    this.verified = data.verified || false;
    this.emailVerified = data.emailVerified || false;
    this.active = data.active !== undefined ? data.active : true;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
    this.bookmarks = data.bookmarks || []; // Array of Donation IDs

    // NGO-specific fields
    if (this.role === 'ngo') {
      this.ngoDetails = {
        registrationNumber: data.ngoDetails?.registrationNumber || null,
        description: data.ngoDetails?.description || null,
        website: data.ngoDetails?.website || null,
        documents: data.ngoDetails?.documents || [],
        verificationStatus: data.ngoDetails?.verificationStatus || 'pending', // 'pending', 'verified', 'rejected'
        categories: data.ngoDetails?.categories || [], // areas of work
        establishedYear: data.ngoDetails?.establishedYear || null
      };
    }

    // Donor-specific fields
    if (this.role === 'donor') {
      this.donorStats = {
        totalDonations: data.donorStats?.totalDonations || 0,
        activeDonations: data.donorStats?.activeDonations || 0,
        completedDonations: data.donorStats?.completedDonations || 0
      };

      // Gamification fields
      this.impactScore = data.impactScore || 0;
      this.badges = data.badges || []; // Array of { id, name, icon, awardedAt }
    }
  }

  static collectionName = 'users';

  static async findById(db, id) {
    try {
      return await db.collection(this.collectionName).findOne({
        _id: new ObjectId(id)
      });
    } catch (error) {
      return null;
    }
  }

  static async findByEmail(db, email) {
    return await db.collection(this.collectionName).findOne({
      email: email.toLowerCase()
    });
  }

  static async create(db, userData) {
    const user = new User(userData);
    user.email = user.email.toLowerCase();
    const result = await db.collection(this.collectionName).insertOne(user);
    return { ...user, _id: result.insertedId };
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

  static async count(db, filter = {}) {
    return await db.collection(this.collectionName).countDocuments(filter);
  }

  static async delete(db, id) {
    const result = await db.collection(this.collectionName).deleteOne({
      _id: new ObjectId(id)
    });
    return result.deletedCount > 0;
  }
}

module.exports = User;

