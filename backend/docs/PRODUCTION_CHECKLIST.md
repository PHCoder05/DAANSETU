# 🚀 Production Deployment Checklist

## ⚠️ Critical Security Items

### 1. Environment Variables ✅

Update ALL these in production `.env`:

```env
# MongoDB - Use Production Cluster
MONGODB_URI=mongodb+srv://prod_user:STRONG_PASSWORD@prod-cluster.mongodb.net/?retryWrites=true&w=majority
DB_NAME=daansetu_production

# Server
PORT=3000
NODE_ENV=production

# JWT Secrets - MUST BE DIFFERENT AND SECURE
JWT_SECRET=GENERATE_64_CHAR_RANDOM_STRING_HERE
JWT_REFRESH_SECRET=GENERATE_DIFFERENT_64_CHAR_STRING_HERE
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Admin Setup - STRONG SECRET
ADMIN_SETUP_KEY=GENERATE_STRONG_RANDOM_KEY_HERE

# CORS - Set to Your Frontend Domain
CORS_ORIGIN=https://yourdomain.com
```

**Generate Secure Secrets:**
```bash
# Run this command to generate random secrets:
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 2. MongoDB Security 🔐

- [ ] Create production database user with minimal permissions
- [ ] Enable IP whitelist (allow only your server IP)
- [ ] Enable MongoDB authentication
- [ ] Use strong passwords (20+ characters)
- [ ] Enable audit logging
- [ ] Set up automated backups
- [ ] Enable encryption at rest

### 3. API Security 🛡️

**Install Rate Limiting:**
```bash
npm install express-rate-limit
```

**Add to `app.js`:**
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

app.use('/api/', limiter);

// Stricter rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 requests per 15 minutes
  skipSuccessfulRequests: true
});

app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);
```

**Install Helmet (Security Headers):**
```bash
npm install helmet
```

**Add to `app.js`:**
```javascript
const helmet = require('helmet');
app.use(helmet());
```

### 4. CORS Configuration 🌐

Update CORS in production:
```javascript
app.use(cors({
  origin: process.env.CORS_ORIGIN, // Your frontend domain
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

### 5. HTTPS/SSL 🔒

- [ ] Obtain SSL certificate (Let's Encrypt, Cloudflare, etc.)
- [ ] Configure reverse proxy (Nginx, Apache)
- [ ] Force HTTPS redirect
- [ ] Update all URLs to https://

### 6. Admin Setup 👑

**First Deploy:**
1. Deploy application
2. Call `/api/setup/check` to verify no admin exists
3. Create first admin with setup key
4. **IMMEDIATELY after:**
   - Change `ADMIN_SETUP_KEY` in environment
   - Optionally disable setup endpoint

**Disable Setup Endpoint (Optional):**

In `app.js`:
```javascript
// Only enable setup in development or on first run
if (process.env.NODE_ENV !== 'production' || process.env.ENABLE_SETUP === 'true') {
  app.use('/api/setup', setupRoutes);
}
```

---

## 📊 Database Optimization

### 1. Create Indexes

```javascript
// Add to a migration or run once
const db = getDB();

// Users collection
await db.collection('users').createIndex({ email: 1 }, { unique: true });
await db.collection('users').createIndex({ role: 1 });
await db.collection('users').createIndex({ 'ngoDetails.verificationStatus': 1 });

// Donations collection
await db.collection('donations').createIndex({ donorId: 1 });
await db.collection('donations').createIndex({ status: 1 });
await db.collection('donations').createIndex({ category: 1 });
await db.collection('donations').createIndex({ claimedBy: 1 });
await db.collection('donations').createIndex({ createdAt: -1 });

// Requests collection
await db.collection('requests').createIndex({ ngoId: 1 });
await db.collection('requests').createIndex({ donationId: 1 });
await db.collection('requests').createIndex({ status: 1 });

// Notifications collection
await db.collection('notifications').createIndex({ userId: 1, createdAt: -1 });
await db.collection('notifications').createIndex({ read: 1 });

// Refresh tokens collection
await db.collection('refresh_tokens').createIndex({ token: 1 }, { unique: true });
await db.collection('refresh_tokens').createIndex({ userId: 1 });
await db.collection('refresh_tokens').createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
```

### 2. Set Up Cleanup Jobs

**Create `jobs/cleanup.js`:**
```javascript
const { getDB } = require('../config/db');
const RefreshToken = require('../models/RefreshToken');
const Notification = require('../models/Notification');

async function cleanupExpiredTokens() {
  const db = getDB();
  const count = await RefreshToken.deleteExpired(db);
  console.log(`Cleaned up ${count} expired refresh tokens`);
}

async function cleanupOldNotifications() {
  const db = getDB();
  const count = await Notification.deleteOld(db, 30); // 30 days old
  console.log(`Cleaned up ${count} old notifications`);
}

async function runCleanup() {
  try {
    await cleanupExpiredTokens();
    await cleanupOldNotifications();
  } catch (error) {
    console.error('Cleanup error:', error);
  }
}

// Run cleanup daily
setInterval(runCleanup, 24 * 60 * 60 * 1000);

module.exports = { runCleanup };
```

**Add to `app.js`:**
```javascript
const { runCleanup } = require('./jobs/cleanup');

// Start cleanup job in production
if (process.env.NODE_ENV === 'production') {
  runCleanup(); // Run once on startup
}
```

---

## 🚀 Performance Optimization

### 1. Enable Compression

```bash
npm install compression
```

```javascript
const compression = require('compression');
app.use(compression());
```

### 2. Connection Pooling

MongoDB driver already uses connection pooling. Verify settings in `config/db.js`:

```javascript
client = new MongoClient(uri, {
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  maxPoolSize: 10, // Adjust based on load
  minPoolSize: 2
});
```

### 3. Caching (Optional)

For high-traffic endpoints, consider Redis caching:

```bash
npm install redis
```

---

## 📝 Logging & Monitoring

### 1. Production Logging

```bash
npm install winston
```

**Create `utils/logger.js`:**
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

module.exports = logger;
```

### 2. Error Tracking

**Options:**
- Sentry
- LogRocket
- New Relic
- DataDog

### 3. Uptime Monitoring

**Options:**
- UptimeRobot (free)
- Pingdom
- StatusCake

---

## 🧪 Pre-Deployment Testing

### 1. Test All Scenarios

- [ ] User registration (donor, NGO)
- [ ] Login flow
- [ ] Token refresh
- [ ] NGO verification process
- [ ] Donation CRUD operations
- [ ] Donation claiming
- [ ] Request system
- [ ] Notifications
- [ ] Admin operations
- [ ] Logout flow

### 2. Load Testing

```bash
npm install -g artillery
```

Create `load-test.yml`:
```yaml
config:
  target: 'https://your-api-domain.com'
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - name: "Health Check"
    flow:
      - get:
          url: "/health"
```

Run: `artillery run load-test.yml`

### 3. Security Audit

```bash
npm audit
npm audit fix
```

---

## 📦 Deployment Steps

### Heroku

```bash
# Install Heroku CLI
# Login
heroku login

# Create app
heroku create daansetu-api

# Set environment variables
heroku config:set MONGODB_URI="..."
heroku config:set JWT_SECRET="..."
# ... set all environment variables

# Deploy
git push heroku main

# Scale
heroku ps:scale web=1

# View logs
heroku logs --tail
```

### DigitalOcean / VPS

```bash
# SSH into server
ssh root@your-server-ip

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2

# Clone repo
git clone your-repo-url
cd DAANSETU_BACKEND

# Install dependencies
npm install --production

# Create .env file
nano .env
# Add all environment variables

# Start with PM2
pm2 start app.js --name daansetu-api
pm2 save
pm2 startup

# Set up Nginx (reverse proxy)
sudo apt-get install nginx

# Configure Nginx
sudo nano /etc/nginx/sites-available/daansetu

# Add:
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/daansetu /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Set up SSL with Let's Encrypt
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

---

## ✅ Post-Deployment Checklist

### Immediate (Day 1)

- [ ] Verify server is running
- [ ] Test health endpoint
- [ ] Create first admin account
- [ ] Change admin setup key
- [ ] Test all critical endpoints
- [ ] Set up monitoring
- [ ] Configure alerts

### Week 1

- [ ] Monitor error logs
- [ ] Check performance metrics
- [ ] Verify backup system
- [ ] Test token refresh flow
- [ ] Verify NGO verification process
- [ ] Check notification delivery

### Ongoing

- [ ] Weekly security audits
- [ ] Monthly dependency updates
- [ ] Regular backup verification
- [ ] Performance monitoring
- [ ] User feedback review

---

## 🚨 Incident Response

### Server Down

1. Check server logs
2. Verify database connection
3. Check resource usage (CPU, memory)
4. Restart application
5. Check external dependencies

### Database Issues

1. Check MongoDB Atlas status
2. Verify connection string
3. Check IP whitelist
4. Review slow queries
5. Check disk space

### Security Breach

1. Immediately revoke all tokens
2. Change all secrets
3. Review access logs
4. Notify users if necessary
5. Implement additional security measures

---

## 📞 Support & Monitoring

### Set Up Alerts For:

- [ ] Server downtime
- [ ] High error rate (>5%)
- [ ] Slow response times (>2s)
- [ ] Database connection failures
- [ ] High CPU/memory usage (>80%)
- [ ] Failed login attempts (potential attack)

### Health Check URLs:

- Main: `https://your-api.com/`
- Health: `https://your-api.com/health`
- Docs: `https://your-api.com/api-docs`

---

## 🎯 Final Verification

Before marking deployment complete:

✅ All environment variables set  
✅ HTTPS enabled  
✅ CORS configured correctly  
✅ Rate limiting active  
✅ Security headers in place  
✅ Database indexes created  
✅ Backup system working  
✅ Monitoring configured  
✅ Logging working  
✅ Admin account created  
✅ Documentation updated  
✅ Team trained  

---

**Your DAANSETU API is production-ready! 🚀**

