const { ObjectId } = require('mongodb');

class EmailVerification {
    constructor(data) {
        this.userId = new ObjectId(data.userId);
        this.token = data.token; // hashed token
        this.expiresAt = data.expiresAt;
        this.used = data.used || false;
        this.createdAt = data.createdAt || new Date();
    }

    static collectionName = 'email_verifications';

    static async create(db, data) {
        const verification = new EmailVerification(data);

        // Remove any existing tokens for this user
        await db.collection(this.collectionName).deleteMany({
            userId: verification.userId
        });

        const result = await db.collection(this.collectionName).insertOne(verification);
        return { ...verification, _id: result.insertedId };
    }

    static async findByToken(db, hashedToken) {
        return await db.collection(this.collectionName).findOne({
            token: hashedToken,
            used: false,
            expiresAt: { $gt: new Date() }
        });
    }

    static async markAsUsed(db, hashedToken) {
        const result = await db.collection(this.collectionName).updateOne(
            { token: hashedToken },
            { $set: { used: true } }
        );
        return result.modifiedCount > 0;
    }

    static async deleteExpired(db) {
        return await db.collection(this.collectionName).deleteMany({
            expiresAt: { $lt: new Date() }
        });
    }
}

module.exports = EmailVerification;
