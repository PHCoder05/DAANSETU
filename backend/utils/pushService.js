const logger = require('./logger');

/**
 * Push Notification Service (Mock implementation for Firebase Cloud Messaging)
 * In a real production app, you would use firebase-admin SDK.
 */
class PushService {
  constructor() {
    this.enabled = process.env.ENABLE_PUSH_NOTIFICATIONS === 'true';
    if (this.enabled) {
      try {
        const admin = require('firebase-admin');
        const serviceAccount = require('../../firebase-adminsdk.json');
        
        if (!admin.apps.length) {
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
          });
          logger.info('[PushService] Firebase Admin initialized successfully');
        }
      } catch (error) {
        logger.error('[PushService] Failed to initialize Firebase Admin:', error);
        this.enabled = false;
      }
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
      const admin = require('firebase-admin');
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data: data,
        android: { priority: 'high' },
        apns: { payload: { aps: { badge: 1 } } }
      });
      logger.info(`[PushService] Successfully sent push to ${response.successCount} tokens, ${response.failureCount} failed`);
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
