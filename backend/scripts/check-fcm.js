const { MongoClient } = require('mongodb');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI;
const DB_NAME = process.env.DB_NAME;

async function findFCMTokens() {
    const client = new MongoClient(MONGODB_URI);
    try {
        await client.connect();
        const db = client.db(DB_NAME);
        const users = await db.collection('users').find({ fcmToken: { $exists: true, $ne: null } }).toArray();
        
        if (users.length === 0) {
            console.log('No users with FCM tokens found.');
        } else {
            users.forEach(u => {
                console.log(`User: ${u.email}, Token: ${u.fcmToken}`);
            });
        }
    } catch (err) {
        console.error(err);
    } finally {
        await client.close();
    }
}

findFCMTokens();
