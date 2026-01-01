const { ObjectId } = require('mongodb');

class Notification {
  constructor(data) {
    this.userId = new ObjectId(data.userId);
    this.title = data.title;
    this.message = data.message;
    this.type = data.type; // 'donation', 'request', 'claim', 'delivery', 'verification', 'system'
    this.relatedId = data.relatedId ? new ObjectId(data.relatedId) : null; // ID of related donation/request
    this.relatedType = data.relatedType || null; // 'donation', 'request', etc.
    this.read = data.read || false;
    this.actionUrl = data.actionUrl || null;
    this.priority = data.priority || 'normal'; // 'low', 'normal', 'high'
    this.createdAt = data.createdAt || new Date();
  }

  static collectionName = 'notifications';

  static async findById(db, id) {
    try {
      return await db.collection(this.collectionName).findOne({ 
        _id: new ObjectId(id) 
      });
    } catch (error) {
      return null;
    }
  }

  static async create(db, notificationData) {
    const notification = new Notification(notificationData);
    const result = await db.collection(this.collectionName).insertOne(notification);
    return { ...notification, _id: result.insertedId };
  }

  static async createMany(db, notificationsData) {
    const notifications = notificationsData.map(data => new Notification(data));
    const result = await db.collection(this.collectionName).insertMany(notifications);
    return result.insertedCount;
  }

  static async findAll(db, filter = {}, options = {}) {
    const { skip = 0, limit = 20, sort = { createdAt: -1 } } = options;
    return await db.collection(this.collectionName)
      .find(filter)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .toArray();
  }

  static async markAsRead(db, id) {
    const result = await db.collection(this.collectionName).updateOne(
      { _id: new ObjectId(id) },
      { $set: { read: true } }
    );
    return result.modifiedCount > 0;
  }

  static async markAllAsRead(db, userId) {
    const result = await db.collection(this.collectionName).updateMany(
      { userId: new ObjectId(userId), read: false },
      { $set: { read: true } }
    );
    return result.modifiedCount;
  }

  static async count(db, filter = {}) {
    return await db.collection(this.collectionName).countDocuments(filter);
  }

  static async countUnread(db, userId) {
    return await db.collection(this.collectionName).countDocuments({
      userId: new ObjectId(userId),
      read: false
    });
  }

  static async delete(db, id) {
    const result = await db.collection(this.collectionName).deleteOne({ 
      _id: new ObjectId(id) 
    });
    return result.deletedCount > 0;
  }

  static async deleteOld(db, daysOld = 30) {
    const date = new Date();
    date.setDate(date.getDate() - daysOld);
    
    const result = await db.collection(this.collectionName).deleteMany({
      createdAt: { $lt: date },
      read: true
    });
    return result.deletedCount;
  }
}

module.exports = Notification;

