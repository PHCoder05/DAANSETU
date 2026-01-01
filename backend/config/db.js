const { MongoClient } = require('mongodb');
require('dotenv').config();

let client;
let db;
let logger;

// Import logger only when available
try {
  logger = require('../utils/logger');
} catch (e) {
  logger = console; // Fallback to console if logger not available
}

async function connectDB() {
  try {
    if (db) {
      logger.info('✅ Using existing database connection');
      return db;
    }

    const uri = process.env.MONGODB_URI;
    const dbName = process.env.DB_NAME || 'daansetu';

    if (!uri) {
      throw new Error('MONGODB_URI is not defined in environment variables');
    }

    logger.info('🔄 Connecting to MongoDB...');
    
    client = new MongoClient(uri, {
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    await client.connect();
    
    // Verify connection
    await client.db('admin').command({ ping: 1 });
    
    db = client.db(dbName);
    logger.info(`✅ Connected to MongoDB database: ${dbName}`);
    
    return db;
  } catch (error) {
    logger.error('❌ MongoDB connection error:', error.message);
    throw error;
  }
}

async function closeDB() {
  try {
    if (client) {
      await client.close();
      client = null;
      db = null;
      logger.info('✅ MongoDB connection closed');
    }
  } catch (error) {
    logger.error('❌ Error closing MongoDB connection:', error.message);
    throw error;
  }
}

function getDB() {
  if (!db) {
    throw new Error('Database not initialized. Call connectDB() first.');
  }
  return db;
}

module.exports = {
  connectDB,
  closeDB,
  getDB
};

