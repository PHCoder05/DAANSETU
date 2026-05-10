const { MongoClient } = require('mongodb');
require('dotenv').config();

async function initIndexes() {
  const uri = process.env.MONGODB_URI;
  const dbName = process.env.DB_NAME || 'daansetu';

  if (!uri) {
    console.error('MONGODB_URI is not defined');
    process.exit(1);
  }

  const client = new MongoClient(uri);

  try {
    await client.connect();
    console.log('Connected to MongoDB');
    const db = client.db(dbName);

    console.log('Creating 2dsphere index on donations.location...');
    await db.collection('donations').createIndex({ location: '2dsphere' });
    console.log('✅ Index created successfully');

  } catch (error) {
    console.error('Error creating index:', error);
  } finally {
    await client.close();
  }
}

initIndexes();
