const { MongoClient } = require('mongodb');
require('dotenv').config({ path: __dirname + '/../.env' });
const Notification = require('../models/Notification');

async function seedNotification() {
  const uri = process.env.MONGODB_URI;
  const client = new MongoClient(uri);

  try {
    await client.connect();
    console.log('Connected to MongoDB');
    
    const db = client.db(process.env.DB_NAME);
    
    const users = await db.collection('users').find({}).toArray();
    console.log(`Found ${users.length} users. Sending test notification to all...`);

    let count = 0;
    for (const user of users) {
      await Notification.create(db, {
        userId: user._id.toString(),
        title: '🎉 You have a new update!',
        message: 'This is a test notification to see how it shows in your notification tab.',
        type: 'donation',
        priority: 'high',
        read: false
      });
      count++;
    }

    console.log(`Successfully created ${count} test notifications.`);
  } catch (error) {
    console.error('Error seeding notifications:', error);
  } finally {
    await client.close();
  }
}

seedNotification();
