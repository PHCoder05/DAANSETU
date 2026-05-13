const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config();

async function debugNGO() {
    const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://localhost:27017/daansetu');
    try {
        await client.connect();
        const db = client.db();
        const ngo = await db.collection('users').findOne({ email: 'testngo@example.com' });
        console.log('NGO Record:', JSON.stringify(ngo, null, 2));
    } catch (err) {
        console.error(err);
    } finally {
        await client.close();
    }
}

debugNGO();
