const { ObjectId } = require('mongodb');

class PasswordReset {
  constructor(data) {
    this.userId = new ObjectId(data.userId);
    this.token = data.token;
    this.expiresAt = data.expiresAt;
    this.used = data.used || false;
    this.usedAt = data.usedAt || null;
    this.createdAt = data.createdAt || new Date();
  }

  static collectionName = 'password_resets';

  static async create(db, resetData) {
    const reset = new PasswordReset(resetData);
    const result = await db.collection(this.collectionName).insertOne(reset);
    return { ...reset, _id: result.insertedId };
  }

  static async findByToken(db, token) {
    return await db.collection(this.collectionName).findOne({
      token,
      used: false,
      expiresAt: { $gt: new Date() }
    });
  }

  static async markAsUsed(db, token) {
    const result = await db.collection(this.collectionName).updateOne(
      { token },
      {
        $set: {
          used: true,
          usedAt: new Date()
        }
      }
    );
    return result.modifiedCount > 0;
  }

  static async deleteExpired(db) {
    const result = await db.collection(this.collectionName).deleteMany({
      expiresAt: { $lt: new Date() }
    });
    return result.deletedCount;
  }
}

module.exports = PasswordReset;

