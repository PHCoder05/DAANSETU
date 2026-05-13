const { MongoClient } = require('mongodb');
require('dotenv').config();

async function findNGO() {
    const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://localhost:21017/daansetu');
    try {
        await client.connect();
        const db = client.db();
        const ngo = await db.collection('users').findOne({ role: 'ngo' });
        if (ngo) {
            console.log('NGO Found:', { id: ngo._id, email: ngo.email });
        } else {
            console.log('No NGO found.');
        }
    } catch (err) {
        console.error(err);
    } finally {
        await client.close();
    }
}

findNGO();
