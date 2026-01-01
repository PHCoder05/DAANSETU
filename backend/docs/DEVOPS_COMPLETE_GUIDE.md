# 🔧 DAANSETU DevOps - Complete Guide

## 🎉 **Everything You Need for Production**

---

## 📚 **What's Included**

### **✅ Complete Infrastructure:**

1. **🐳 Docker** - Containerization
2. **🌐 Nginx** - Reverse proxy + SSL
3. **🔧 Jenkins** - CI/CD automation
4. **🏗️ Terraform** - Infrastructure as Code
5. **📦 GitHub Actions** - Alternative CI/CD
6. **🔄 GitHub Webhooks** - Auto-trigger
7. **📝 Scripts** - Automation helpers

---

## 🚀 **Quick Start Options**

### **Option 1: Test Locally (30 seconds)**

```bash
# Start everything
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Access
http://localhost           # Via Nginx
http://localhost/api-docs  # Swagger UI
```

**What Runs:**
- ✅ Backend container (port 5000)
- ✅ Nginx container (port 80)
- ✅ Network between them
- ✅ Health checks active

---

### **Option 2: Deploy to AWS (Automated)**

```bash
# 1. Configure Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Update with your values

# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 3. Get your EC2 IP
terraform output ec2_public_ip

# 4. Access your API
curl http://YOUR_EC2_IP/health
open http://YOUR_EC2_IP/api-docs
```

**What Gets Created:**
- ✅ VPC with subnets
- ✅ Security groups
- ✅ EC2 instance
- ✅ Elastic IP
- ✅ CloudWatch monitoring
- ✅ Docker installed
- ✅ Nginx installed
- ✅ App auto-started

---

### **Option 3: Full CI/CD (One-time setup, then automatic)**

#### **Using Jenkins:**

```bash
# 1. Install Jenkins
cd jenkins
chmod +x setup-jenkins.sh
./setup-jenkins.sh

# 2. Configure in UI
# - Access: http://localhost:8080
# - Add credentials
# - Create pipeline job

# 3. Setup webhook in GitHub
# - Settings → Webhooks
# - URL: http://your-jenkins:8080/github-webhook/

# 4. Done! Now just:
git push origin main
# ✅ Auto-deploys!
```

#### **Using GitHub Actions (Easier!):**

```bash
# 1. Add secrets to GitHub:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - DOCKER_USERNAME
# - DOCKER_PASSWORD
# - EC2_HOST
# - SSH_PRIVATE_KEY

# 2. Push code
git push origin main

# 3. That's it! ✅
# GitHub Actions automatically deploys
```

---

## 🌐 **Nginx Setup - Detailed**

### **Why Nginx is Essential:**

```
❌ WITHOUT NGINX:
Internet → Your App (Port 5000)
- No SSL
- No rate limiting
- No load balancing
- Vulnerable to DDoS
- No caching
- Amateur setup

✅ WITH NGINX:
Internet → Nginx (80/443) → Your App (5000)
- SSL/HTTPS ✅
- Rate limiting ✅
- Load balancing ✅
- DDoS protection ✅
- Gzip compression ✅
- Professional ✅
```

### **What Nginx Does:**

**1. Reverse Proxy:**
```nginx
location / {
    proxy_pass http://app:5000;
    # Nginx forwards to your app
}
```

**2. SSL Termination:**
```nginx
listen 443 ssl http2;
ssl_certificate /etc/nginx/ssl/fullchain.pem;
# Nginx handles HTTPS, app stays HTTP
```

**3. Rate Limiting:**
```nginx
limit_req zone=auth_limit burst=5;
# Protects against brute force
```

**4. Compression:**
```nginx
gzip on;
gzip_comp_level 6;
# 70% smaller responses
```

**5. Security Headers:**
```nginx
add_header X-Frame-Options "SAMEORIGIN";
add_header X-XSS-Protection "1; mode=block";
# Protects against XSS, clickjacking
```

### **Nginx Configuration Files:**

```
nginx/
├── nginx.conf              # Main config
│   ├── Worker processes
│   ├── Gzip settings
│   ├── Rate limit zones
│   └── Security headers
│
└── conf.d/daansetu.conf    # Virtual host
    ├── HTTP server (port 80)
    ├── HTTPS server (port 443)
    ├── Upstream to app
    ├── Location blocks
    └── Proxy settings
```

---

## 🐳 **Docker Setup**

### **Multi-Stage Dockerfile:**

```dockerfile
# Stage 1: Builder (dependencies)
FROM node:18-alpine AS builder
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime (optimized)
FROM node:18-alpine
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER nodejs  # Non-root user
CMD ["node", "app.js"]
```

**Benefits:**
- ✅ Smaller image size
- ✅ Security (non-root)
- ✅ Layer caching
- ✅ Health checks

### **Docker Compose:**

```yaml
services:
  app:           # Your API
  nginx:         # Reverse proxy
networks:
  daansetu-network
volumes:
  logs
```

**Features:**
- ✅ Multi-container setup
- ✅ Automatic restart
- ✅ Health checks
- ✅ Volume persistence
- ✅ Network isolation

---

## 🔧 **Jenkins Pipeline**

### **10-Stage Pipeline:**

```
1. 📋 Checkout
2. 🔍 Code Quality
3. 🧪 Run Tests
4. 🐳 Build Docker
5. 🔒 Security Scan
6. 📤 Push to Registry
7. 🏗️ Terraform Plan
8. 🚀 Deploy to AWS
9. ✅ Health Check
10. 📢 Notify Team
```

### **Jenkinsfile Features:**

- ✅ Environment variables
- ✅ Parallel execution
- ✅ Error handling
- ✅ Rollback on failure
- ✅ Notifications
- ✅ Build history

---

## 🏗️ **Terraform Infrastructure**

### **What Gets Provisioned:**

```hcl
# Network
- VPC (10.0.0.0/16)
- Internet Gateway
- Public Subnets (2 AZs)
- Route Tables

# Compute
- EC2 Instance (t3.small)
- Elastic IP (static)
- SSH Key Pair

# Security
- Security Group
  - Port 22 (SSH)
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
  - Port 5000 (App)

# Monitoring
- CloudWatch Alarms
- CPU monitoring
- Memory monitoring

# Storage
- 30GB EBS (encrypted)
```

### **Terraform Commands:**

```bash
# Initialize
terraform init

# Validate
terraform validate

# Plan (preview)
terraform plan

# Apply (create)
terraform apply

# Destroy (delete all)
terraform destroy

# Show state
terraform show

# Outputs
terraform output
```

---

## 🔄 **CI/CD Workflows**

### **Workflow 1: GitHub Actions (Recommended)**

**Trigger:** Push to main branch

**Steps:**
1. Checkout code
2. Run tests
3. Build Docker image
4. Security scan
5. Push to registry
6. Deploy to AWS
7. Health check
8. Notify

**Time:** ~5-8 minutes

### **Workflow 2: Jenkins**

**Trigger:** GitHub webhook

**Same steps** as GitHub Actions

**Advantage:** More control, custom plugins

---

## 📝 **Helper Scripts**

### **1. Deploy Script** (`scripts/deploy.sh`)

**Interactive menu:**
```bash
./scripts/deploy.sh

1) Local Docker
2) Build & Test
3) Deploy to AWS
4) Cleanup
5) View Logs
6) Restart
7) Stop
```

### **2. Production Setup** (`scripts/setup-production.sh`)

**Complete EC2 setup:**
- Installs Docker
- Installs Nginx
- Configures SSL
- Sets up firewall
- Creates directories
- Starts services

### **3. Health Check** (`scripts/health-check.sh`)

**Monitors:**
- API endpoints
- Docker containers
- Disk space
- Memory usage
- Database connection
- Sends alerts

### **4. Update App** (`scripts/update-app.sh`)

**Zero-downtime update:**
- Pulls latest code
- Creates backup
- Builds new image
- Scales up
- Health check
- Removes old
- Rollback on failure

### **5. Backup Database** (`scripts/backup-db.sh`)

**Features:**
- MongoDB backup
- Compression
- S3 upload (optional)
- Auto-cleanup old backups
- Restore instructions

### **6. Rollback** (`scripts/rollback.sh`)

**Quick rollback:**
- Lists backup versions
- Select version
- Rollback
- Health check

### **7. Monitor** (`scripts/monitor.sh`)

**Real-time dashboard:**
- CPU/Memory usage
- Response times
- Error count
- Service status
- Auto-refresh

---

## 🔒 **Security Features**

### **Application Level:**
- ✅ JWT authentication
- ✅ Password hashing
- ✅ Input validation
- ✅ CORS protection

### **Network Level:**
- ✅ Security groups (firewall)
- ✅ Rate limiting (Nginx)
- ✅ SSL/HTTPS
- ✅ Security headers

### **Container Level:**
- ✅ Non-root user
- ✅ Minimal base image
- ✅ Security scanning
- ✅ No secrets in image

### **Infrastructure Level:**
- ✅ Encrypted storage
- ✅ Private VPC
- ✅ SSH key auth
- ✅ Monitoring & alerts

---

## 📊 **Monitoring & Logging**

### **Logs Available:**

**Application Logs:**
```bash
# Winston logs
tail -f logs/combined.log
tail -f logs/error.log

# Docker logs
docker-compose logs -f app
```

**Nginx Logs:**
```bash
# Access logs
docker-compose exec nginx tail -f /var/log/nginx/access.log

# Error logs
docker-compose exec nginx tail -f /var/log/nginx/error.log
```

**System Logs:**
```bash
# On EC2
sudo journalctl -u docker -f
sudo journalctl -u nginx -f
```

### **Health Monitoring:**

**Automated:**
- Docker health checks (every 30s)
- CloudWatch alarms
- Log monitoring

**Manual:**
```bash
# Run health check script
./scripts/health-check.sh

# Or check manually
curl http://localhost/health
docker ps
docker stats
```

---

## 🎯 **Common Operations**

### **Update Application:**

```bash
# Automated
./scripts/update-app.sh

# Manual
git pull
docker-compose build
docker-compose up -d
```

### **View Logs:**

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f nginx

# Last 100 lines
docker-compose logs --tail=100 app
```

### **Restart Services:**

```bash
# All services
docker-compose restart

# Specific service
docker-compose restart app
docker-compose restart nginx

# Full restart
docker-compose down
docker-compose up -d
```

### **Backup Database:**

```bash
./scripts/backup-db.sh
```

### **Rollback:**

```bash
./scripts/rollback.sh
```

### **Monitor:**

```bash
./scripts/monitor.sh
```

---

## 🚨 **Troubleshooting**

### **Container Won't Start:**

```bash
# Check logs
docker-compose logs app

# Check environment
docker-compose config

# Rebuild
docker-compose build --no-cache
docker-compose up -d
```

### **Nginx Issues:**

```bash
# Test config
docker-compose exec nginx nginx -t

# Reload config
docker-compose exec nginx nginx -s reload

# Check logs
docker-compose logs nginx
```

### **Database Connection:**

```bash
# Test MongoDB URI
docker-compose exec app node -e "const {connectDB} = require('./config/db'); connectDB().then(() => console.log('Connected!')).catch(console.error)"

# Check environment variables
docker-compose exec app env | grep MONGODB
```

### **Health Check Failing:**

```bash
# Check container health
docker inspect daansetu-backend | grep Health -A 10

# Test health endpoint
curl -v http://localhost/health

# Check application logs
docker-compose logs app | tail -50
```

---

## 📦 **File Structure**

```
DAANSETU_BACKEND/
├── 🐳 Docker
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── .dockerignore
│
├── 🌐 Nginx
│   ├── nginx.conf
│   ├── conf.d/daansetu.conf
│   ├── ssl/ (certificates)
│   └── logs/
│
├── 🔧 Jenkins
│   ├── Jenkinsfile
│   └── setup-jenkins.sh
│
├── 🏗️ Terraform
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── user-data.sh
│   └── terraform.tfvars.example
│
├── 🔄 GitHub
│   └── .github/workflows/ci-cd.yml
│
└── 📝 Scripts
    ├── deploy.sh
    ├── setup-production.sh
    ├── health-check.sh
    ├── update-app.sh
    ├── backup-db.sh
    ├── rollback.sh
    └── monitor.sh
```

---

## 🎯 **Complete Automation**

### **What's Automated:**

✅ **Code Push** → GitHub webhook → Jenkins  
✅ **Build** → Docker image creation  
✅ **Test** → Quality & security checks  
✅ **Deploy** → AWS EC2 deployment  
✅ **Monitor** → Health checks  
✅ **Backup** → Database backups  
✅ **Logs** → Log rotation  
✅ **SSL** → Certificate renewal  
✅ **Restart** → Auto-restart on failure  

### **What's One-Click:**

✅ `./scripts/deploy.sh` - Interactive deployment  
✅ `docker-compose up -d` - Local start  
✅ `terraform apply` - AWS provisioning  
✅ `git push origin main` - Full deployment  

---

## 💰 **Cost Breakdown**

### **AWS Infrastructure:**

| Resource | Details | Monthly Cost |
|----------|---------|--------------|
| **EC2 t3.small** | 2 vCPU, 2GB RAM | $15 |
| **EBS 30GB** | SSD storage | $3 |
| **Elastic IP** | Static IP | $0 (when attached) |
| **Data Transfer** | ~10GB/month | $1 |
| **CloudWatch** | Basic monitoring | $0 (free tier) |
| **TOTAL** | | **~$20/month** |

### **Additional Services:**

| Service | Cost |
|---------|------|
| MongoDB Atlas | $0 (free) or $9 (shared) |
| Domain Name | $12/year (~$1/month) |
| SSL Certificate | $0 (Let's Encrypt) |
| Docker Hub | $0 (public images) |
| GitHub Actions | $0 (2000 min/month free) |

**Total: ~$30-35/month for complete production!**

---

## ✅ **Production Checklist**

### **Before First Deploy:**

**Infrastructure:**
- [ ] AWS account created
- [ ] AWS CLI configured
- [ ] Domain purchased (optional)
- [ ] SSH key generated
- [ ] Terraform configured

**Application:**
- [ ] Environment variables set
- [ ] MongoDB cluster created
- [ ] JWT secrets generated
- [ ] CORS origin updated
- [ ] Admin setup key set

**CI/CD:**
- [ ] Jenkins installed OR GitHub Actions configured
- [ ] Credentials added
- [ ] Webhook configured
- [ ] Pipeline tested

**Security:**
- [ ] Secrets not in code
- [ ] SSH IP restricted
- [ ] Firewall configured
- [ ] SSL certificate ready

---

## 🎊 **What You Have Now**

### **Complete DevOps Platform:**

✅ **Containerization** - Docker + Compose  
✅ **Reverse Proxy** - Nginx (essential!)  
✅ **CI/CD** - Jenkins + GitHub Actions  
✅ **Infrastructure** - Terraform (AWS)  
✅ **Automation** - One-click deploy  
✅ **Monitoring** - Scripts + CloudWatch  
✅ **Backups** - Automated  
✅ **Security** - Multi-layer  
✅ **Scaling** - Ready  
✅ **Zero-Downtime** - Update scripts  

### **Production-Ready Features:**

✅ SSL/HTTPS support  
✅ Auto-scaling ready  
✅ Load balancing ready  
✅ Database backups  
✅ Log rotation  
✅ Health monitoring  
✅ Rollback capability  
✅ Security scanning  
✅ Rate limiting  
✅ DDoS protection  

---

## 🚀 **Deploy Now!**

### **Quick Test:**
```bash
docker-compose up -d
open http://localhost/api-docs
```

### **Production:**
```bash
# Read the guide
cat docs/ONE_CLICK_DEPLOYMENT.md

# Deploy
cd terraform
terraform apply

# Or use script
./scripts/deploy.sh
```

---

## 📖 **Documentation Index**

| Guide | Purpose |
|-------|---------|
| **ONE_CLICK_DEPLOYMENT.md** | Complete deployment |
| **CI_CD_SETUP.md** | CI/CD setup |
| **NGINX_GUIDE.md** | Nginx explained |
| **DEVOPS_COMPLETE_GUIDE.md** | This file |

---

**Your DAANSETU backend has enterprise-grade DevOps! 🚀**

**Answer: YES, Nginx is essential and fully configured! ✅**

