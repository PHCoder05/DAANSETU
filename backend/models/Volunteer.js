const { ObjectId } = require('mongodb');

class Volunteer {
  constructor(data) {
    this.userId = new ObjectId(data.userId);
    this.name = data.name || '';
    this.email = data.email || '';
    this.phone = data.phone || '';
    this.location = data.location || null;
    this.status = data.status || 'active'; // 'active', 'inactive', 'on-duty'
    this.vehicleType = data.vehicleType || 'none'; // 'none', 'bike', 'scooter', 'car', 'van'
    this.availability = data.availability !== undefined ? data.availability : true;
    this.stats = {
      completedPickups: data.stats?.completedPickups || 0,
      totalWeightHandled: data.stats?.totalWeightHandled || 0, // In kg
      rating: data.stats?.rating || 5.0,
      totalReviews: data.stats?.totalReviews || 0
    };
    this.preferences = {
      maxDistance: data.preferences?.maxDistance || 10, // In km
      categories: data.preferences?.categories || [], // categories they prefer to handle
    };
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static collectionName = 'volunteers';

  static async create(db, volunteerData) {
    const volunteer = new Volunteer(volunteerData);
    const result = await db.collection(this.collectionName).insertOne(volunteer);
    return { ...volunteer, _id: result.insertedId };
  }

  static async findByUserId(db, userId) {
    return await db.collection(this.collectionName).findOne({
      userId: new ObjectId(userId)
    });
  }

  static async update(db, userId, updateData) {
    updateData.updatedAt = new Date();
    const result = await db.collection(this.collectionName).updateOne(
      { userId: new ObjectId(userId) },
      { $set: updateData }
    );
    return result.modifiedCount > 0;
  }
}

module.exports = Volunteer;
