const { ObjectId } = require('mongodb');

class RefreshToken {
  constructor(data) {
    this.userId = new ObjectId(data.userId);
    this.token = data.token;
    this.expiresAt = data.expiresAt;
    this.createdAt = data.createdAt || new Date();
    this.revoked = data.revoked || false;
    this.revokedAt = data.revokedAt || null;
    this.replacedByToken = data.replacedByToken || null;
  }

  static collectionName = 'refresh_tokens';

  static async create(db, tokenData) {
    const token = new RefreshToken(tokenData);
    const result = await db.collection(this.collectionName).insertOne(token);
    return { ...token, _id: result.insertedId };
  }

  static async findByToken(db, token) {
    return await db.collection(this.collectionName).findOne({ 
      token,
      revoked: false,
      expiresAt: { $gt: new Date() }
    });
  }

  static async findByUserId(db, userId) {
    return await db.collection(this.collectionName)
      .find({ 
        userId: new ObjectId(userId),
        revoked: false,
        expiresAt: { $gt: new Date() }
      })
      .toArray();
  }

  static async revokeToken(db, token, replacedBy = null) {
    const updateData = {
      revoked: true,
      revokedAt: new Date()
    };
    
    if (replacedBy) {
      updateData.replacedByToken = replacedBy;
    }

    const result = await db.collection(this.collectionName).updateOne(
      { token },
      { $set: updateData }
    );
    return result.modifiedCount > 0;
  }

  static async revokeAllUserTokens(db, userId) {
    const result = await db.collection(this.collectionName).updateMany(
      { 
        userId: new ObjectId(userId),
        revoked: false 
      },
      { 
        $set: { 
          revoked: true,
          revokedAt: new Date()
        } 
      }
    );
    return result.modifiedCount;
  }

  static async deleteExpired(db) {
    const result = await db.collection(this.collectionName).deleteMany({
      expiresAt: { $lt: new Date() }
    });
    return result.deletedCount;
  }

  static async deleteOld(db, daysOld = 30) {
    const date = new Date();
    date.setDate(date.getDate() - daysOld);
    
    const result = await db.collection(this.collectionName).deleteMany({
      createdAt: { $lt: date },
      revoked: true
    });
    return result.deletedCount;
  }
}

module.exports = RefreshToken;

