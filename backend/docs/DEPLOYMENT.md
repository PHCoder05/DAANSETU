# 🚀 DAANSETU Backend - Deployment Guide

## 📋 Pre-Deployment Checklist

Before deploying to production, ensure you have:

- [ ] MongoDB Atlas cluster set up (or production MongoDB instance)
- [ ] Secure JWT secret key generated
- [ ] Domain name (if applicable)
- [ ] SSL certificate configured
- [ ] Hosting platform account (Heroku, Railway, DigitalOcean, etc.)

## 🌍 Deployment Options

### Option 1: Heroku

1. **Install Heroku CLI**
```bash
npm install -g heroku
```

2. **Login to Heroku**
```bash
heroku login
```

3. **Create Heroku App**
```bash
heroku create daansetu-backend
```

4. **Set Environment Variables**
```bash
heroku config:set MONGODB_URI="your_mongodb_uri"
heroku config:set DB_NAME="daansetu"
heroku config:set JWT_SECRET="your_secure_secret_key"
heroku config:set JWT_EXPIRES_IN="7d"
heroku config:set NODE_ENV="production"
heroku config:set CORS_ORIGIN="https://your-frontend-domain.com"
```

5. **Deploy**
```bash
git push heroku main
```

6. **Open App**
```bash
heroku open
```

### Option 2: Railway

1. **Install Railway CLI**
```bash
npm install -g @railway/cli
```

2. **Login and Initialize**
```bash
railway login
railway init
```

3. **Add Environment Variables** (via Railway Dashboard or CLI)
```bash
railway variables set MONGODB_URI="your_mongodb_uri"
railway variables set JWT_SECRET="your_secure_secret_key"
railway variables set NODE_ENV="production"
```

4. **Deploy**
```bash
railway up
```

### Option 3: DigitalOcean App Platform

1. **Connect GitHub Repository**
   - Go to DigitalOcean App Platform
   - Click "Create App"
   - Connect your GitHub repository

2. **Configure Build Settings**
   - Build Command: `npm install`
   - Run Command: `npm start`

3. **Add Environment Variables** (in App Platform dashboard)
   - All variables from `.env`

4. **Deploy**
   - Click "Deploy"

### Option 4: AWS EC2 / VPS

1. **SSH into your server**
```bash
ssh user@your-server-ip
```

2. **Install Node.js and npm**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

3. **Install PM2 (Process Manager)**
```bash
sudo npm install -g pm2
```

4. **Clone Repository**
```bash
git clone your-repo-url
cd DAANSETU_BACKEND
npm install
```

5. **Create .env file**
```bash
nano .env
# Add all environment variables
```

6. **Start with PM2**
```bash
pm2 start app.js --name daansetu-backend
pm2 save
pm2 startup
```

7. **Set up Nginx (Optional)**
```bash
sudo apt-get install nginx
# Configure reverse proxy
```

### Option 5: Docker

1. **Create Dockerfile**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
```

2. **Create .dockerignore**
```
node_modules
npm-debug.log
.env
.git
```

3. **Build Image**
```bash
docker build -t daansetu-backend .
```

4. **Run Container**
```bash
docker run -d \
  --name daansetu-backend \
  -p 3000:3000 \
  -e MONGODB_URI="your_mongodb_uri" \
  -e JWT_SECRET="your_secret" \
  -e NODE_ENV="production" \
  daansetu-backend
```

## 🔒 Production Environment Variables

**Required Variables:**
```env
# MongoDB
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/
DB_NAME=daansetu_production

# Server
PORT=3000
NODE_ENV=production

# Security
JWT_SECRET=generate-a-very-secure-random-key-here
JWT_EXPIRES_IN=7d

# CORS
CORS_ORIGIN=https://your-frontend-domain.com
```

**Generate Secure JWT Secret:**
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## 🔐 Security Best Practices

### 1. Environment Variables
- ✅ Never commit `.env` to version control
- ✅ Use strong, random JWT secret (64+ characters)
- ✅ Rotate secrets periodically
- ✅ Use different secrets for dev/staging/production

### 2. MongoDB Security
- ✅ Use MongoDB Atlas with IP whitelist
- ✅ Create database user with minimal permissions
- ✅ Enable authentication
- ✅ Use strong passwords
- ✅ Regular backups

### 3. CORS Configuration
- ✅ Set specific origin(s) instead of `*`
- ✅ Use HTTPS in production
- ✅ Configure allowed methods and headers

### 4. Rate Limiting (Recommended)
Install express-rate-limit:
```bash
npm install express-rate-limit
```

Add to app.js:
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

### 5. Helmet (Security Headers)
```bash
npm install helmet
```

```javascript
const helmet = require('helmet');
app.use(helmet());
```

## 📊 Monitoring

### Health Checks
The API includes health check endpoints:
- `GET /` - Basic server info
- `GET /health` - Health status

### Recommended Monitoring Tools
- **Uptime Monitoring**: UptimeRobot, Pingdom
- **Error Tracking**: Sentry, LogRocket
- **Performance**: New Relic, DataDog
- **Logs**: Papertrail, Loggly

### PM2 Monitoring (If using PM2)
```bash
pm2 monit
pm2 logs daansetu-backend
```

## 🔄 CI/CD Pipeline

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '18'
    
    - name: Install dependencies
      run: npm install
    
    - name: Run tests
      run: npm test
    
    - name: Deploy to Heroku
      uses: akhileshns/heroku-deploy@v3.12.12
      with:
        heroku_api_key: ${{secrets.HEROKU_API_KEY}}
        heroku_app_name: "daansetu-backend"
        heroku_email: "your-email@example.com"
```

## 🗄️ Database Backup

### MongoDB Atlas Backup
- Enable automatic backups in Atlas dashboard
- Configure backup frequency and retention

### Manual Backup Script
```bash
#!/bin/bash
mongodump --uri="your_mongodb_uri" --out=/backup/$(date +%Y%m%d)
```

## 📈 Scaling Considerations

### Horizontal Scaling
- Deploy multiple instances behind a load balancer
- Use session storage (Redis) for JWT blacklist if needed
- Implement caching (Redis/Memcached)

### Database Optimization
- Add indexes on frequently queried fields
- Use aggregation pipelines efficiently
- Monitor slow queries

### CDN for Static Assets
- Use Cloudflare or AWS CloudFront
- Serve images from cloud storage (S3, Cloudinary)

## 🧪 Pre-Production Testing

1. **Test all endpoints** with production-like data
2. **Load testing** with tools like Apache Bench or Artillery
3. **Security audit** with tools like npm audit
4. **Check error handling** for edge cases
5. **Verify CORS** with actual frontend domain
6. **Test authentication** flow thoroughly

## 📝 Post-Deployment

### 1. Create Admin User
Either:
- Manually create in MongoDB
- Use seed endpoint (then disable it)
- Create via API and promote to admin in database

### 2. Verify NGO Accounts
- Login as admin
- Review and verify NGO registrations

### 3. Monitor Logs
```bash
# Heroku
heroku logs --tail

# PM2
pm2 logs

# Docker
docker logs -f container_name
```

### 4. Set up Alerts
- Database connection failures
- High error rates
- Server downtime

## 🔧 Troubleshooting

### Common Issues

**MongoDB Connection Timeout**
- Check IP whitelist in MongoDB Atlas
- Verify connection string
- Check network/firewall settings

**JWT Errors**
- Ensure JWT_SECRET is set correctly
- Check token expiration settings
- Verify Authorization header format

**CORS Errors**
- Set correct CORS_ORIGIN
- Check frontend domain configuration
- Verify protocol (http vs https)

**Port Already in Use**
- Change PORT in environment variables
- Kill process using the port
- Use process manager (PM2)

## 📞 Support

For deployment issues:
1. Check logs first
2. Verify all environment variables
3. Test connectivity to MongoDB
4. Review deployment platform documentation

## ✅ Deployment Checklist

- [ ] Environment variables configured
- [ ] MongoDB connection tested
- [ ] JWT secret generated (secure)
- [ ] CORS configured for frontend domain
- [ ] Health checks working
- [ ] Admin user created
- [ ] Monitoring set up
- [ ] Backup strategy in place
- [ ] SSL/HTTPS configured
- [ ] Rate limiting enabled
- [ ] Error tracking configured
- [ ] Documentation updated with API URL

---

**Your DAANSETU backend is now ready for production! 🚀**

For questions or issues, refer to README.md or create an issue on GitHub.

