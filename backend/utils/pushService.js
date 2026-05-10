const logger = require('./logger');

/**
 * Push Notification Service (Mock implementation for Firebase Cloud Messaging)
 * In a real production app, you would use firebase-admin SDK.
 */
class PushService {
  constructor() {
    this.enabled = process.env.ENABLE_PUSH_NOTIFICATIONS === 'true';
    if (this.enabled) {
      // Initialize firebase-admin here if needed
      // const admin = require('firebase-admin');
      // admin.initializeApp({ ... });
    }
  }

  /**
   * Send push notification to specific user tokens
   * @param {string[]} tokens - Array of FCM tokens
   * @param {Object} notification - Notification object { title, body, data }
   */
  async sendToTokens(tokens, { title, body, data = {} }) {
    if (!tokens || tokens.length === 0) return;
    
    if (!this.enabled) {
      logger.info(`[PushService Mock] Would send push to ${tokens.length} tokens: "${title}: ${body}"`, { data });
      return;
    }

    try {
      // Real implementation would be:
      // const response = await admin.messaging().sendMulticast({
      //   tokens,
      //   notification: { title, body },
      //   data: data,
      //   android: { priority: 'high' },
      //   apns: { payload: { aps: { badge: 1 } } }
      // });
      // logger.info(`Push notifications sent: ${response.successCount} success, ${response.failureCount} failure`);
      
      logger.info(`[PushService] Successfully sent push to ${tokens.length} tokens`);
    } catch (error) {
      logger.error('Error sending push notifications:', error);
    }
  }

  /**
   * Send push notification to a specific user
   * @param {Object} db - MongoDB database instance
   * @param {string} userId - User ID
   * @param {Object} notification - Notification object
   */
  async sendToUser(db, userId, notification) {
    try {
      const user = await db.collection('users').findOne(
        { _id: new (require('mongodb').ObjectId)(userId) },
        { projection: { fcmTokens: 1 } }
      );

      if (user && user.fcmTokens && user.fcmTokens.length > 0) {
        await this.sendToTokens(user.fcmTokens, notification);
      }
    } catch (error) {
      logger.error('Error fetching user for push notification:', error);
    }
  }
}

module.exports = new PushService();
