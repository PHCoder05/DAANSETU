# 🎯 DAANSETU Backend - Getting Started

Welcome to the DAANSETU Backend API! This guide will help you get up and running in minutes.

## 📚 What You've Got

Your complete backend API is ready with:

✅ **33 API Endpoints** across 5 modules  
✅ **4 Database Models** (User, Donation, Request, Notification)  
✅ **JWT Authentication** with role-based access  
✅ **Complete Documentation** (5 comprehensive guides)  
✅ **Postman Collection** for instant testing  
✅ **Production-Ready** code with error handling  

## 🚀 Quick Start (2 Minutes)

### 1. Verify Installation
Your dependencies are already installed! ✅

### 2. Check Environment
Your `.env` file is configured with:
- MongoDB connection ✅
- JWT secret ✅
- Server port (3000) ✅

### 3. Start Server
```bash
npm start
```

You should see:
```
🚀 DAANSETU API Server is running!
📡 Port: 3000
🌍 Environment: development
```

### 4. Test API
Open your browser or Postman and go to:
```
http://localhost:3000
```

You should get a JSON response confirming the server is running!

## 📖 Documentation Guide

We've created comprehensive documentation for you:

### 1. **README.md** 📘
- Complete project overview
- Full feature list
- Installation instructions
- Environment variables
- Tech stack details

### 2. **API_DOCUMENTATION.md** 📗
- Every endpoint documented
- Request/response examples
- Authentication guide
- Error codes
- Query parameters

### 3. **QUICKSTART.md** 📙
- Fast setup (5 minutes)
- Basic API usage examples
- Test commands
- Common use cases

### 4. **DEPLOYMENT.md** 🚢
- Production deployment guide
- Multiple platform options
- Security best practices
- Monitoring setup
- Troubleshooting

### 5. **PROJECT_SUMMARY.md** 📊
- Complete feature checklist
- Project structure
- Tech stack
- Database schema
- Learning outcomes

## 🧪 Test Your API

### Method 1: Postman (Recommended)

1. **Import Collection**
   - Open Postman
   - Import `DAANSETU.postman_collection.json`
   - Set baseUrl to `http://localhost:3000/api`

2. **Register a User**
   - Use "Register Donor" request
   - Copy the token from response

3. **Update Token**
   - In Postman, set the `token` variable
   - Now all authenticated requests will work!

### Method 2: cURL

**Test Server:**
```bash
curl http://localhost:3000/health
```

**Register User:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User",
    "role": "donor"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Method 3: Browser
Just open: `http://localhost:3000`

## 🔐 Understanding User Roles

### 1. **Donor** (Role: `donor`)
**Can:**
- Create donations
- View all donations
- Update own donations
- Approve/reject NGO requests
- Track donation status

**Cannot:**
- Claim donations
- Create requests

### 2. **NGO** (Role: `ngo`)
**Can:**
- View all donations
- Request donations
- Claim donations (when verified)
- Update claimed donation status
- View own requests

**Cannot:**
- Create donations
- Access admin functions

**Note:** NGOs need admin verification before claiming donations!

### 3. **Admin** (Role: `admin`)
**Can:**
- Manage all users
- Verify NGOs
- View platform statistics
- Delete users
- Activate/deactivate accounts
- Access all data

## 📋 Complete API Overview

### Authentication (`/api/auth`)
- `POST /register` - Register new user
- `POST /login` - Login user
- `GET /profile` - Get user profile
- `PUT /profile` - Update profile
- `PUT /change-password` - Change password
- `PUT /ngo-details` - Update NGO details

### Donations (`/api/donations`)
- `GET /` - List all donations
- `GET /:id` - Get donation details
- `POST /` - Create donation
- `PUT /:id` - Update donation
- `DELETE /:id` - Delete donation
- `POST /:id/claim` - Claim donation
- `PUT /:id/status` - Update status
- `GET /nearby` - Find nearby donations
- `GET /stats/summary` - Get statistics

### NGOs (`/api/ngos`)
- `GET /` - List verified NGOs
- `GET /:id` - Get NGO details
- `POST /requests` - Create request
- `GET /requests/list` - List requests
- `PUT /requests/:id/status` - Update request
- `PUT /requests/:id/cancel` - Cancel request

### Notifications (`/api/notifications`)
- `GET /` - Get notifications
- `GET /unread-count` - Get unread count
- `PUT /:id/read` - Mark as read
- `PUT /read-all` - Mark all as read
- `DELETE /:id` - Delete notification

### Admin (`/api/admin`)
- `GET /users` - List users
- `DELETE /users/:userId` - Delete user
- `PUT /users/:userId/toggle-status` - Toggle status
- `GET /ngos/pending` - Pending NGOs
- `PUT /ngos/:userId/verify` - Verify NGO
- `GET /stats` - Platform statistics
- `POST /seed` - Seed test data (dev only)

## 🎯 Common Workflows

### Workflow 1: Donor Creates Donation
1. Register as donor
2. Login (get token)
3. Create donation with details
4. Wait for NGO requests
5. Approve request
6. Update status as donation progresses

### Workflow 2: NGO Claims Donation
1. Register as NGO
2. Login (get token)
3. Admin verifies NGO
4. Browse available donations
5. Claim donation
6. Update delivery status

### Workflow 3: Admin Manages Platform
1. Login as admin
2. View pending NGO verifications
3. Verify NGOs
4. Monitor platform statistics
5. Manage users if needed

## 🐛 Troubleshooting

### Server won't start?
```bash
# Check if port 3000 is in use
# Windows:
netstat -ano | findstr :3000

# Stop process if needed
# Then restart server
npm start
```

### MongoDB connection error?
- Check `.env` file has correct MONGODB_URI
- Verify MongoDB Atlas cluster is running
- Check IP whitelist in MongoDB Atlas
- Ensure database user has correct permissions

### Authentication not working?
- Verify JWT_SECRET is set in `.env`
- Check token format: `Bearer <token>`
- Ensure token hasn't expired (7 days default)
- Try logging in again to get fresh token

### CORS errors?
- Update CORS_ORIGIN in `.env` to match your frontend domain
- In development, `*` allows all origins

## 💡 Pro Tips

1. **Use Postman Collection**
   - Fastest way to test all endpoints
   - Pre-configured requests
   - Easy token management

2. **Seed Test Data**
   - Call `POST /api/admin/seed` to create test users
   - Credentials: `donor@test.com` / `password123`
   - Saves time during development

3. **Check Logs**
   - Server logs show all requests
   - Helpful for debugging
   - Shows database queries

4. **Read API_DOCUMENTATION.md**
   - Complete reference for all endpoints
   - Request/response examples
   - Error codes explained

5. **Test Incrementally**
   - Start with auth endpoints
   - Then test each module
   - Verify error handling

## 📞 Need Help?

**Documentation:**
- README.md - Full documentation
- API_DOCUMENTATION.md - API reference
- DEPLOYMENT.md - Production guide

**Common Issues:**
- Check server logs
- Verify environment variables
- Test MongoDB connection
- Review request format

**Still Stuck?**
- Review the documentation
- Check code comments
- Test with Postman collection
- Verify database connectivity

## 🎉 You're All Set!

Your DAANSETU Backend API is:
✅ Fully functional  
✅ Well documented  
✅ Production ready  
✅ Easy to test  
✅ Scalable  

### Next Steps:
1. **Test the API** with Postman
2. **Integrate with frontend**
3. **Deploy to production** (see DEPLOYMENT.md)
4. **Monitor and scale** as needed

---

**Happy Coding! 🚀**

*Making the world a better place, one donation at a time.*

---

**Quick Links:**
- 📘 [README.md](./README.md) - Full documentation
- 📗 [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - API reference
- 📙 [QUICKSTART.md](./QUICKSTART.md) - Quick setup
- 🚢 [DEPLOYMENT.md](./DEPLOYMENT.md) - Deploy guide
- 📊 [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md) - Project overview

