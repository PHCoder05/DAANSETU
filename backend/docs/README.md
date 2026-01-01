# 📚 DAANSETU Backend Documentation

Welcome to the comprehensive documentation for the DAANSETU Backend API!

---

## 🚀 Quick Navigation

### **New User? Start Here! 👇**
📖 **[Getting Started Guide](./GETTING_STARTED.md)** - Your first stop!

### **Essential Documentation**

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[Getting Started](./GETTING_STARTED.md)** | Complete overview & quick start | 👈 **START HERE** |
| **[Quick Start](./QUICKSTART.md)** | 5-minute setup guide | When you're in a hurry |
| **[API Documentation](./API_DOCUMENTATION.md)** | Complete API reference | When coding |
| **[README](./README.md)** | Main project documentation | General info |

### **New Features** ⭐

| Document | Purpose |
|----------|---------|
| **[Token Authentication](./TOKEN_AUTHENTICATION.md)** | Access & refresh tokens guide |
| **[Verification Process](./VERIFICATION_PROCESS.md)** | NGO verification workflow |
| **[New Features Summary](./NEW_FEATURES_SUMMARY.md)** | All enhancements explained |

### **Deployment & Production**

| Document | Purpose |
|----------|---------|
| **[Deployment Guide](./DEPLOYMENT.md)** | Production deployment |
| **[Production Checklist](./PRODUCTION_CHECKLIST.md)** | Pre-launch checklist |

### **Reference**

| Document | Purpose |
|----------|---------|
| **[Project Summary](./PROJECT_SUMMARY.md)** | Complete feature list |

---

## 🎯 Choose Your Path

### 1. **I'm Just Getting Started**
```
1. Read: Getting Started Guide
2. Start server: npm start
3. Open: http://localhost:3000/api-docs
4. Test with Swagger UI
```

### 2. **I Want to Integrate with Frontend**
```
1. Read: Token Authentication Guide
2. Read: API Documentation
3. Use Postman collection
4. Implement auth flow
```

### 3. **I'm Ready to Deploy**
```
1. Read: Production Checklist
2. Read: Deployment Guide
3. Update environment variables
4. Deploy!
```

### 4. **I Need to Understand a Feature**
```
NGO Verification → Verification Process Guide
Authentication → Token Authentication Guide
API Endpoints → API Documentation
All Features → New Features Summary
```

---

## 📊 What's in the API

### **38 Total Endpoints**

**Authentication (9)**
- Register, Login, Refresh Token, Logout, Profile, etc.

**Donations (9)**
- CRUD operations, Claim, Status updates, Search, Stats

**NGOs (6)**
- List NGOs, Requests, Approval workflow

**Notifications (5)**
- Get, Mark read, Delete, Unread count

**Admin (7)**
- User management, NGO verification, Platform stats

**Setup (2)**
- First-time admin creation

---

## 🔐 Key Features

### **Implemented & Production-Ready**

✅ **JWT Authentication** with access & refresh tokens  
✅ **Role-Based Access** (Donor, NGO, Admin)  
✅ **Multi-Stage Verification** for NGOs  
✅ **Token Rotation** for security  
✅ **Swagger Documentation** (interactive!)  
✅ **Input Validation** on all endpoints  
✅ **CORS Configuration**  
✅ **Password Hashing** (bcrypt)  
✅ **Notification System**  
✅ **Request Management**  
✅ **Statistics & Analytics**  

---

## 🧭 Navigation by Task

### **Authentication Tasks**
- How do tokens work? → [Token Authentication Guide](./TOKEN_AUTHENTICATION.md)
- How to implement login? → [API Documentation - Auth](./API_DOCUMENTATION.md#authentication)
- Token expired? → [Token Authentication - Refresh Flow](./TOKEN_AUTHENTICATION.md#token-refresh)

### **NGO Tasks**
- How does verification work? → [Verification Process](./VERIFICATION_PROCESS.md)
- How to verify an NGO? → [Verification Process - Admin](./VERIFICATION_PROCESS.md#admin-decision)
- NGO can't claim? → [Verification Process - Stage 3](./VERIFICATION_PROCESS.md#multi-stage-verification)

### **Admin Tasks**
- How to create first admin? → [Verification Process - Admin Setup](./VERIFICATION_PROCESS.md#admin)
- How to manage users? → [API Documentation - Admin](./API_DOCUMENTATION.md#admin)
- Platform stats? → [API Documentation - Stats](./API_DOCUMENTATION.md#get-platform-statistics)

### **Development Tasks**
- Setup local environment? → [Quick Start Guide](./QUICKSTART.md)
- API endpoint reference? → [API Documentation](./API_DOCUMENTATION.md)
- Test with Postman? → Use `DAANSETU.postman_collection.json`

### **Deployment Tasks**
- Ready to deploy? → [Production Checklist](./PRODUCTION_CHECKLIST.md)
- How to deploy? → [Deployment Guide](./DEPLOYMENT.md)
- Security setup? → [Production Checklist - Security](./PRODUCTION_CHECKLIST.md#critical-security-items)

---

## 🔧 Quick Commands

```bash
# Start server
npm start

# Test server
curl http://localhost:3000/health

# Access Swagger docs
# Open: http://localhost:3000/api-docs

# Create first admin
curl -X POST http://localhost:3000/api/setup/admin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123!",
    "name": "Admin",
    "setupKey": "change-this-setup-key-in-production"
  }'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

---

## 📞 Need Help?

1. **Check documentation** - 90% of questions answered here
2. **Review API docs** - Complete endpoint reference
3. **Use Swagger UI** - Interactive testing at `/api-docs`
4. **Check logs** - Server logs show detailed errors
5. **Read error messages** - They're descriptive!

---

## 🎓 Learning Path

**Beginner:**
1. Getting Started Guide
2. Quick Start Guide
3. API Documentation (basics)

**Intermediate:**
1. Token Authentication Guide
2. Verification Process
3. Complete API Documentation

**Advanced:**
1. Production Checklist
2. Deployment Guide
3. Security best practices

---

## 📦 What's New

### Latest Enhancements ⭐

**Authentication:**
- ✅ Access & refresh token system
- ✅ Token rotation for security
- ✅ Multi-device logout

**Documentation:**
- ✅ Swagger interactive docs
- ✅ Token authentication guide
- ✅ Verification process guide
- ✅ Production checklist

**Admin:**
- ✅ First-time setup system
- ✅ Secure admin creation
- ✅ Enhanced NGO verification

**Security:**
- ✅ Enhanced token security
- ✅ Input validation
- ✅ CORS configuration
- ✅ Production guidelines

**Full Details:** [New Features Summary](./NEW_FEATURES_SUMMARY.md)

---

## ⚡ Quick Reference

### **Important URLs**
- Server: `http://localhost:3000`
- Health Check: `http://localhost:3000/health`
- Swagger Docs: `http://localhost:3000/api-docs` ⭐

### **Environment Variables**
See `.env` file or [Production Checklist](./PRODUCTION_CHECKLIST.md)

### **Database Collections**
- users
- donations
- requests
- notifications
- refresh_tokens ⭐ NEW

### **User Roles**
- `donor` - Creates donations
- `ngo` - Claims donations (after verification)
- `admin` - Manages platform

---

## ✅ Documentation Checklist

When starting a new task:

- [ ] Read the relevant documentation section
- [ ] Check API documentation for endpoint details
- [ ] Review examples in documentation
- [ ] Test with Swagger UI or Postman
- [ ] Check error responses
- [ ] Review security considerations

---

## 📖 Documentation Quality

All documentation includes:
✅ Clear explanations  
✅ Code examples  
✅ Request/response samples  
✅ Error handling  
✅ Best practices  
✅ Security considerations  
✅ Production guidelines  

---

## 🎉 You're Ready!

Pick your starting point and dive in!

**Most Common Starting Points:**
1. **[Getting Started Guide](./GETTING_STARTED.md)** - Best for new users
2. **[Swagger UI](http://localhost:3000/api-docs)** - Best for testing
3. **[API Documentation](./API_DOCUMENTATION.md)** - Best for development

---

**Happy Coding! 🚀**

*Last Updated: October 2025*
