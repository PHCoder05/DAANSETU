# 🚀 DAANSETU Backend - Quick Start Guide

Get your DAANSETU backend API up and running in 5 minutes!

## ⚡ Quick Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
The `.env` file is already created with your MongoDB connection. If you need to change it:
```env
MONGODB_URI=your_mongodb_connection_string
DB_NAME=daansetu
PORT=3000
NODE_ENV=development
JWT_SECRET=your-secret-key
```

### 3. Start the Server
```bash
npm start
```

The server will start at `http://localhost:3000`

## 🧪 Test the API

### Check Server Health
```bash
curl http://localhost:3000/health
```

### Seed Test Data (First Time Setup)
First, you need to create an admin user manually or use the test credentials after seeding.

For development, you can create test data:
1. Register as admin (or modify a user in DB to be admin)
2. Then call: `POST /api/admin/seed`

Or manually test with these steps:

## 📝 Basic Usage Flow

### 1. Register a Donor
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "donor@example.com",
    "password": "password123",
    "name": "John Doe",
    "role": "donor",
    "phone": "+1234567890",
    "location": {
      "lat": 40.7128,
      "lng": -74.0060,
      "address": "New York, NY"
    }
  }'
```

**Save the token from the response!**

### 2. Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "donor@example.com",
    "password": "password123"
  }'
```

### 3. Create a Donation
```bash
curl -X POST http://localhost:3000/api/donations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "title": "Fresh Vegetables",
    "description": "Organic vegetables from local farm",
    "category": "food",
    "quantity": 50,
    "unit": "kg",
    "condition": "new",
    "pickupLocation": {
      "lat": 40.7128,
      "lng": -74.0060,
      "address": "123 Main St, New York, NY"
    },
    "priority": "high"
  }'
```

### 4. Get All Donations
```bash
curl http://localhost:3000/api/donations
```

### 5. Register an NGO
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ngo@example.com",
    "password": "password123",
    "name": "Hope Foundation",
    "role": "ngo",
    "phone": "+1234567891",
    "location": {
      "lat": 40.7580,
      "lng": -73.9855,
      "address": "New York, NY"
    },
    "ngoDetails": {
      "registrationNumber": "NGO12345",
      "description": "Helping communities in need",
      "categories": ["food", "clothes"],
      "establishedYear": 2020
    }
  }'
```

**Note:** NGOs need admin verification before they can claim donations!

## 🎯 Quick API Reference

| Endpoint | Method | Description | Auth |
|----------|--------|-------------|------|
| `/api/auth/register` | POST | Register user | No |
| `/api/auth/login` | POST | Login | No |
| `/api/auth/profile` | GET | Get profile | Yes |
| `/api/donations` | GET | List donations | Optional |
| `/api/donations` | POST | Create donation | Yes (Donor) |
| `/api/donations/:id/claim` | POST | Claim donation | Yes (NGO) |
| `/api/ngos` | GET | List NGOs | Optional |
| `/api/notifications` | GET | Get notifications | Yes |
| `/api/admin/stats` | GET | Platform stats | Yes (Admin) |

## 📚 Import Postman Collection

We've included a Postman collection (`DAANSETU.postman_collection.json`) with all API endpoints pre-configured!

1. Open Postman
2. Click Import
3. Select `DAANSETU.postman_collection.json`
4. Update the `token` variable after login
5. Start testing!

## 🔑 User Roles

- **Donor**: Create and manage donations
- **NGO**: Browse and claim donations (needs verification)
- **Admin**: Manage users, verify NGOs, view stats

## 📖 Full Documentation

For complete API documentation, see:
- [README.md](./README.md) - Complete setup guide
- [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - Detailed API reference

## 🐛 Troubleshooting

### Server won't start?
- Check if MongoDB URI is correct in `.env`
- Ensure port 3000 is not in use
- Check console for error messages

### Can't connect to MongoDB?
- Verify your MongoDB Atlas cluster is running
- Check if your IP is whitelisted in MongoDB Atlas
- Ensure database user credentials are correct

### Authentication errors?
- Make sure you include the token: `Authorization: Bearer YOUR_TOKEN`
- Token expires in 7 days by default
- Re-login if token expired

## 💡 Pro Tips

1. **Use the Postman collection** for easier testing
2. **Seed test data** with `/api/admin/seed` for development
3. **Check logs** for detailed error messages
4. **Use environment variables** for different environments
5. **Enable CORS** properly for your frontend domain

## 🎉 You're Ready!

Start building amazing features with DAANSETU API! 

For questions or issues, check the full documentation or open an issue on GitHub.

Happy coding! 🚀

