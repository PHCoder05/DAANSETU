const { MongoClient } = require('mongodb');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI;
const DB_NAME = process.env.DB_NAME || 'daansetu';

async function findUser() {
  const client = new MongoClient(MONGODB_URI);
  try {
    await client.connect();
    const db = client.db(DB_NAME);
    const users = db.collection('users');
    const user = await users.findOne({ email: 'pankaj@t3sync.tech' });
    console.log('User found:', user);
  } catch (err) {
    console.error(err);
  } finally {
    await client.close();
  }
}

findUser();
