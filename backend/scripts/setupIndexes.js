const { connectDB, getDB, closeDB } = require('../config/db');

async function setupIndexes() {
  try {
    const db = await connectDB();
    console.log('🔄 Setting up indexes...');

    // ── Donations Collection ──
    const donations = db.collection('donations');
    
    console.log('📦 Indexing donations...');
    await donations.createIndex({ donorId: 1 });
    await donations.createIndex({ claimedBy: 1 });
    await donations.createIndex({ status: 1 });
    await donations.createIndex({ createdAt: -1 });
    await donations.createIndex({ category: 1 });
    await donations.createIndex({ location: '2dsphere' });
    console.log('✅ Donation indexes created.');

    // ── Users Collection ──
    const users = db.collection('users');
    
    console.log('👤 Indexing users...');
    await users.createIndex({ email: 1 }, { unique: true });
    await users.createIndex({ role: 1 });
    console.log('✅ User indexes created.');

    // ── Notifications Collection ──
    const notifications = db.collection('notifications');
    
    console.log('🔔 Indexing notifications...');
    await notifications.createIndex({ userId: 1 });
    await notifications.createIndex({ createdAt: -1 });
    console.log('✅ Notification indexes created.');

    // ── Requests Collection ──
    const requests = db.collection('requests');
    
    console.log('📝 Indexing requests...');
    await requests.createIndex({ donationId: 1 });
    await requests.createIndex({ ngoId: 1 });
    await requests.createIndex({ status: 1 });
    console.log('✅ Request indexes created.');

    console.log('✨ All indexes setup successfully!');
  } catch (error) {
    console.error('❌ Error setting up indexes:', error);
  } finally {
    await closeDB();
  }
}

setupIndexes();
