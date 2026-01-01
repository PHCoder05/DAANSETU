# 🚀 DAANSETU - Complete CI/CD Setup Guide

## 🎯 **One-Click Automated Deployment**

This guide sets up a **complete automated deployment pipeline** with:

✅ **Jenkins** - CI/CD automation  
✅ **GitHub Webhooks** - Auto-trigger on push  
✅ **Docker** - Containerization  
✅ **Nginx** - Reverse proxy & load balancer  
✅ **Terraform** - Infrastructure as Code  
✅ **AWS EC2** - Cloud hosting  

---

## 🏗️ **Architecture Overview**

```
GitHub Push
    ↓
GitHub Webhook Triggers
    ↓
Jenkins Pipeline
    ↓
├─ Code Quality Check
├─ Run Tests
├─ Build Docker Image
├─ Security Scan (Trivy)
├─ Push to Registry
├─ Terraform Plan
├─ Terraform Apply (AWS EC2)
└─ Deploy to EC2
    ↓
EC2 Instance
├─ Pull Docker Image
├─ Docker Compose Up
└─ Nginx Reverse Proxy
    ↓
✅ Live Production API
```

---

## ✅ **Why Nginx?**

### **Essential Benefits:**

1. **Reverse Proxy** 🔄
   - Forwards requests to Docker container
   - Hides internal architecture
   - Single entry point

2. **SSL/TLS Termination** 🔒
   - Handles HTTPS
   - Automatic certificate management
   - Secure connections

3. **Load Balancing** ⚖️
   - Distribute traffic (if multiple containers)
   - High availability
   - Zero-downtime deployments

4. **Performance** 🚀
   - Caching static content
   - Gzip compression
   - Connection pooling

5. **Security** 🛡️
   - Rate limiting
   - DDoS protection
   - Security headers
   - Hide app server details

6. **Monitoring** 📊
   - Access logs
   - Error logs
   - Request metrics

### **What Nginx Does:**

```
Internet Traffic (Port 80/443)
         ↓
    Nginx (Reverse Proxy)
    ├─ SSL Termination
    ├─ Rate Limiting
    ├─ Gzip Compression
    ├─ Security Headers
    └─ Access Logs
         ↓
    Docker Container (Port 5000)
         ↓
    Your API Application
```

**Without Nginx:** Direct exposure, no SSL, no rate limiting  
**With Nginx:** Professional, secure, production-grade ✅

---

## 📋 **Complete Setup Steps**

### **Phase 1: Local Development (Docker + Nginx)**

#### **Step 1: Test Locally**

```bash
# Build and start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Access API
# Through Nginx: http://localhost
# Direct: http://localhost:5000
```

**What Happens:**
- ✅ Builds Docker image
- ✅ Starts backend container
- ✅ Starts Nginx container
- ✅ Nginx proxies to backend
- ✅ Health checks running

#### **Step 2: Test Nginx**

```bash
# Via Nginx (port 80)
curl http://localhost/health

# Via Swagger
curl http://localhost/api-docs

# Direct to container (port 5000)
curl http://localhost:5000/health
```

---

### **Phase 2: Jenkins Setup**

#### **Step 1: Install Jenkins**

```bash
# Run installation script
cd jenkins
chmod +x setup-jenkins.sh
./setup-jenkins.sh
```

**What Installs:**
- ✅ Jenkins
- ✅ Docker
- ✅ Terraform
- ✅ AWS CLI

#### **Step 2: Configure Jenkins**

1. **Access Jenkins:**
   ```
   http://localhost:8080
   ```

2. **Get Initial Password:**
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

3. **Install Plugins:**
   - GitHub plugin
   - Docker plugin
   - Docker Pipeline plugin
   - AWS Steps plugin
   - Pipeline plugin
   - Blue Ocean (optional)
   - Slack Notification (optional)

4. **Add Credentials:**

   **GitHub Credentials:**
   - Go to: Manage Jenkins → Credentials
   - Add → Username with password
   - ID: `github-credentials`
   - Username: Your GitHub username
   - Password: Personal Access Token

   **AWS Credentials:**
   - Add → AWS Credentials
   - ID: `aws-credentials`
   - Access Key ID: Your AWS key
   - Secret Access Key: Your AWS secret

   **Docker Hub:**
   - Add → Username with password
   - ID: `docker-credentials`
   - Username: Docker Hub username
   - Password: Docker Hub token

   **EC2 SSH:**
   - Add → SSH Username with private key
   - ID: `ec2-host`
   - Username: ubuntu
   - Private Key: Your EC2 SSH key

#### **Step 3: Create Jenkins Job**

1. **New Item** → Enter name: `DAANSETU-Backend`
2. **Type:** Pipeline
3. **Configuration:**
   - Enable "GitHub hook trigger for GITScm polling"
   - Pipeline → Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repo
   - Credentials: github-credentials
   - Branch: */main
   - Script Path: Jenkinsfile

4. **Save**

---

### **Phase 3: GitHub Webhook**

#### **Step 1: Configure Webhook**

1. **Go to GitHub Repository:**
   - Settings → Webhooks → Add webhook

2. **Configure:**
   ```
   Payload URL: http://your-jenkins-server:8080/github-webhook/
   Content type: application/json
   Events: Just the push event
   Active: ✅
   ```

3. **Jenkins URL Must Be Public:**
   - Use ngrok for testing: `ngrok http 8080`
   - Or make Jenkins server publicly accessible
   - Or use Jenkins on cloud (recommended)

#### **Step 2: Test Webhook**

```bash
# Make a change
git add .
git commit -m "test: trigger Jenkins"
git push origin main

# Check Jenkins:
# - Job should auto-trigger
# - Build should start
# - Pipeline should run
```

---

### **Phase 4: AWS Infrastructure (Terraform)**

#### **Step 1: Configure AWS**

```bash
# Configure AWS CLI
aws configure
# Enter: Access Key ID, Secret Key, Region, Output format

# Create S3 bucket for Terraform state
aws s3 mb s3://daansetu-terraform-state --region us-east-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name daansetu-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

#### **Step 2: Configure Terraform Variables**

```bash
cd terraform

# Copy example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Update these values:**
```hcl
aws_region     = "us-east-1"
project_name   = "daansetu-backend"
instance_type  = "t3.small"

# Your IP for SSH access
allowed_ssh_ips = ["YOUR_IP/32"]

# Generate SSH key
ssh_public_key = "your-ssh-public-key"

# Secrets (generate secure values)
mongodb_uri        = "mongodb+srv://..."
jwt_secret         = "64-char-random-string"
jwt_refresh_secret = "different-64-char-string"
admin_setup_key    = "secure-setup-key"

# Your frontend domain
cors_origin = "https://yourdomain.com"
```

#### **Step 3: Generate SSH Key**

```bash
# Generate new key for EC2
ssh-keygen -t rsa -b 4096 -f ~/.ssh/daansetu-ec2-key

# Get public key
cat ~/.ssh/daansetu-ec2-key.pub
# Copy this to terraform.tfvars
```

#### **Step 4: Deploy Infrastructure**

```bash
cd terraform

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

**Output:**
```
Outputs:
ec2_public_ip = "54.123.45.67"
api_url = "http://54.123.45.67"
swagger_url = "http://54.123.45.67/api-docs"
ssh_command = "ssh -i ~/.ssh/daansetu-key.pem ubuntu@54.123.45.67"
```

---

### **Phase 5: Complete Deployment**

#### **Option 1: Using One-Click Script**

```bash
# Make script executable (Linux/Mac)
chmod +x scripts/deploy.sh

# Run
./scripts/deploy.sh
```

**Menu Options:**
1. Local Docker deployment
2. Build & test image
3. Deploy to AWS
4. Cleanup
5. View logs
6. Restart services
7. Stop services

#### **Option 2: Manual Deployment**

```bash
# Build locally
docker build -t daansetu-backend .

# Test locally
docker-compose up -d

# Check
curl http://localhost/health
curl http://localhost/api-docs
```

#### **Option 3: Jenkins Auto-Deploy**

```bash
# Just push to GitHub
git add .
git commit -m "feat: new feature"
git push origin main

# Jenkins automatically:
# ✅ Detects push (webhook)
# ✅ Runs pipeline
# ✅ Builds Docker image
# ✅ Deploys to AWS
# ✅ Runs health checks
```

---

## 🔧 **Nginx Configuration**

### **Why Nginx is Essential:**

**Development:**
```
localhost:80 (Nginx) → localhost:5000 (Docker)
```

**Production:**
```
yourdomain.com:443 (Nginx/SSL) → EC2:5000 (Docker)
```

### **Features Configured:**

✅ **Reverse Proxy** - Forwards to backend  
✅ **Gzip Compression** - Faster responses  
✅ **Rate Limiting** - DDoS protection  
✅ **Security Headers** - XSS, Clickjacking protection  
✅ **SSL Ready** - HTTPS configuration included  
✅ **Health Check Bypass** - No rate limiting on /health  
✅ **Access Logs** - Request monitoring  
✅ **Error Logs** - Error tracking  

### **Nginx Files Created:**

1. `nginx/nginx.conf` - Main configuration
2. `nginx/conf.d/daansetu.conf` - Virtual host config
3. `docker-compose.yml` - Nginx container setup

---

## 🔐 **SSL Certificate Setup (Production)**

### **Option 1: Let's Encrypt (Free)**

```bash
# SSH to EC2
ssh ubuntu@your-ec2-ip

# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d api.yourdomain.com

# Auto-renewal
sudo certbot renew --dry-run
```

### **Option 2: AWS Certificate Manager**

1. Request certificate in ACM
2. Validate domain
3. Use with Application Load Balancer
4. Point ALB to EC2

---

## 📊 **Monitoring & Logs**

### **View Nginx Logs:**

```bash
# Access logs
docker-compose exec nginx tail -f /var/log/nginx/access.log

# Error logs
docker-compose exec nginx tail -f /var/log/nginx/error.log
```

### **View Application Logs:**

```bash
# All logs
docker-compose logs -f app

# Specific service
docker-compose logs -f nginx
```

### **On EC2:**

```bash
ssh ubuntu@your-ec2-ip

# View all logs
cd /opt/daansetu-backend
docker-compose logs -f

# Application logs
docker-compose exec app tail -f logs/combined.log

# Nginx logs
docker-compose exec nginx tail -f /var/log/nginx/access.log
```

---

## 🔄 **Complete Deployment Flow**

### **Automatic (One Push):**

```bash
# Developer pushes code
git push origin main
    ↓
# GitHub webhook triggers Jenkins
    ↓
# Jenkins Pipeline runs:
✅ Checkout code
✅ Quality checks
✅ Run tests
✅ Build Docker image
✅ Security scan
✅ Push to registry
✅ Terraform plan & apply
✅ Deploy to EC2
✅ Health check
✅ Notify team
    ↓
# Live on production! 🎉
```

**Time: ~5-10 minutes** (fully automated!)

---

## 📝 **Jenkins Pipeline Stages**

1. **📋 Checkout** - Get latest code
2. **🔍 Code Quality** - Linting & audit
3. **🧪 Tests** - Run test suite
4. **🐳 Docker Build** - Build image
5. **🔒 Security Scan** - Trivy scan
6. **📤 Push to Registry** - Docker Hub
7. **🏗️ Terraform Plan** - Infrastructure changes
8. **🚀 Deploy to AWS** - Update EC2
9. **✅ Health Check** - Verify deployment
10. **📢 Notify** - Slack/Email notification

---

## 🔐 **Required Secrets**

### **Jenkins Credentials:**

1. **github-credentials**
   - Type: Username with password
   - Username: GitHub username
   - Password: Personal Access Token

2. **aws-credentials**
   - Type: AWS Credentials
   - Access Key ID
   - Secret Access Key

3. **docker-credentials**
   - Type: Username with password
   - Docker Hub username
   - Docker Hub token

4. **ec2-host**
   - Type: Secret text
   - Value: EC2 public IP

5. **SSH Private Key**
   - Type: SSH Username with private key
   - For EC2 access

### **GitHub Secrets** (for GitHub Actions):

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
DOCKER_USERNAME
DOCKER_PASSWORD
EC2_HOST
SSH_PRIVATE_KEY
```

---

## 🐳 **Docker Setup**

### **What's Included:**

**`Dockerfile`:**
- Multi-stage build (optimization)
- Alpine Linux (small image)
- Non-root user (security)
- Health check
- Production-ready

**`docker-compose.yml`:**
- Backend service
- Nginx service
- Network configuration
- Volume management
- Auto-restart

**`.dockerignore`:**
- Excludes unnecessary files
- Smaller image size

### **Build & Run:**

```bash
# Build image
docker build -t daansetu-backend .

# Run with compose
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

---

## 🏗️ **Terraform Infrastructure**

### **What's Created:**

✅ **VPC** - Virtual Private Cloud  
✅ **Subnets** - Public subnets (2 AZs)  
✅ **Internet Gateway** - Internet access  
✅ **Security Groups** - Firewall rules  
✅ **EC2 Instance** - t3.small server  
✅ **Elastic IP** - Static public IP  
✅ **CloudWatch Alarms** - Monitoring  

### **Files:**

1. `terraform/main.tf` - Main infrastructure
2. `terraform/variables.tf` - Input variables
3. `terraform/outputs.tf` - Output values
4. `terraform/user-data.sh` - EC2 startup script
5. `terraform/terraform.tfvars` - Your values

### **Commands:**

```bash
cd terraform

# Initialize
terraform init

# Plan (preview changes)
terraform plan

# Apply (create infrastructure)
terraform apply

# Destroy (delete everything)
terraform destroy

# Show current state
terraform show

# Get outputs
terraform output
```

---

## 🎯 **One-Click Deployment Options**

### **Option 1: Local Docker (Development)**

```bash
./scripts/deploy.sh
# Choose: 1
```

**Result:** Running locally with Nginx!

### **Option 2: AWS Deployment (Production)**

```bash
./scripts/deploy.sh
# Choose: 3
```

**Result:** Complete AWS infrastructure deployed!

### **Option 3: GitHub Push (Fully Automated)**

```bash
git push origin main
```

**Result:** Jenkins auto-deploys to AWS!

---

## 📊 **What You Get**

### **Infrastructure:**

```
AWS Account
├── VPC (10.0.0.0/16)
├── Public Subnets (2 AZs)
├── Internet Gateway
├── Security Groups
│   ├── Port 22 (SSH)
│   ├── Port 80 (HTTP)
│   ├── Port 443 (HTTPS)
│   └── Port 5000 (App - optional)
├── EC2 Instance (t3.small)
│   ├── Ubuntu 22.04
│   ├── Docker installed
│   ├── Nginx installed
│   ├── Auto-start on boot
│   └── CloudWatch monitoring
└── Elastic IP (static)
```

### **Services on EC2:**

```
EC2 Instance
├── Nginx (Port 80/443)
│   ├── Reverse proxy
│   ├── SSL termination
│   ├── Rate limiting
│   └── Compression
├── Docker Container (Port 5000)
│   ├── DAANSETU Backend
│   ├── Health checks
│   └── Auto-restart
└── Logs
    ├── Nginx logs
    └── Application logs
```

---

## 🔒 **Security Features**

### **Network Security:**
- ✅ VPC isolation
- ✅ Security groups (firewall)
- ✅ SSH key authentication
- ✅ Restricted SSH access (your IP only)

### **Application Security:**
- ✅ Non-root container user
- ✅ Security headers (Nginx)
- ✅ Rate limiting (Nginx)
- ✅ Encrypted EBS volumes
- ✅ SSL/TLS (production)

### **CI/CD Security:**
- ✅ Credentials management
- ✅ Docker image scanning (Trivy)
- ✅ Security audits (npm audit)
- ✅ Secrets not in code

---

## 📈 **Scaling Options**

### **Current Setup (Single Instance):**
- t3.small EC2 instance
- Handles moderate traffic
- ~$15/month

### **Scale Up (Vertical):**
```hcl
# In terraform/variables.tf
instance_type = "t3.medium" # 2 vCPU, 4GB RAM
instance_type = "t3.large"  # 2 vCPU, 8GB RAM
```

### **Scale Out (Horizontal):**

**Add Load Balancer:**
- Multiple EC2 instances
- Application Load Balancer
- Auto Scaling Group
- Zero-downtime deployments

---

## 🧪 **Testing the Pipeline**

### **1. Test Locally:**

```bash
# Start services
docker-compose up -d

# Test through Nginx
curl http://localhost/health
curl http://localhost/api-docs

# Check logs
docker-compose logs -f
```

### **2. Test Jenkins Pipeline:**

```bash
# Trigger manually in Jenkins
# Or push to GitHub

# Monitor in Jenkins:
# - Blue Ocean UI (recommended)
# - Classic UI
# - Console output
```

### **3. Test AWS Deployment:**

```bash
# After Terraform apply
EC2_IP=$(cd terraform && terraform output -raw ec2_public_ip)

# Test API
curl http://$EC2_IP/health
curl http://$EC2_IP/api-docs

# SSH to instance
ssh -i ~/.ssh/daansetu-ec2-key.pem ubuntu@$EC2_IP

# Check Docker
docker ps
docker-compose logs
```

---

## 📋 **Pre-Deployment Checklist**

### **Local Testing:**
- [ ] Code runs locally
- [ ] Docker builds successfully
- [ ] docker-compose works
- [ ] Nginx proxies correctly
- [ ] All endpoints work

### **AWS Prerequisites:**
- [ ] AWS account created
- [ ] AWS CLI configured
- [ ] IAM user with permissions
- [ ] SSH key pair generated
- [ ] S3 bucket for Terraform state
- [ ] DynamoDB table for locks

### **Jenkins Prerequisites:**
- [ ] Jenkins installed
- [ ] Required plugins installed
- [ ] Credentials configured
- [ ] Job created
- [ ] Webhook configured

### **Terraform:**
- [ ] terraform.tfvars configured
- [ ] Variables updated
- [ ] SSH key added
- [ ] Secrets secured
- [ ] Plan reviewed

### **Production:**
- [ ] Domain name purchased
- [ ] DNS configured
- [ ] SSL certificate obtained
- [ ] MongoDB production cluster
- [ ] Secrets rotated
- [ ] CORS configured
- [ ] Monitoring setup

---

## 🎯 **Cost Estimate (AWS)**

### **Monthly Costs:**

- **EC2 t3.small:** ~$15/month
- **Elastic IP:** Free (if attached)
- **EBS Storage (30GB):** ~$3/month
- **Data Transfer:** ~$1-5/month
- **CloudWatch:** Free tier

**Total: ~$20-25/month**

**Cost Optimization:**
- Use Reserved Instances (-40%)
- Use Spot Instances (-70%, not recommended for production)
- Right-size instance based on traffic

---

## 🚨 **Troubleshooting**

### **Nginx Issues:**

```bash
# Check Nginx status
docker-compose ps nginx

# View Nginx config
docker-compose exec nginx nginx -t

# Restart Nginx
docker-compose restart nginx

# Check logs
docker-compose logs nginx
```

### **Docker Issues:**

```bash
# Rebuild image
docker-compose build --no-cache

# Remove all containers
docker-compose down -v

# Clean system
docker system prune -a
```

### **Jenkins Issues:**

```bash
# Restart Jenkins
sudo systemctl restart jenkins

# Check status
sudo systemctl status jenkins

# View logs
sudo journalctl -u jenkins -f
```

### **AWS/Terraform Issues:**

```bash
# Check Terraform state
terraform show

# Refresh state
terraform refresh

# Check EC2
aws ec2 describe-instances --instance-ids i-xxxxx

# SSH to EC2
ssh -i ~/.ssh/daansetu-ec2-key.pem ubuntu@your-ec2-ip
```

---

## ✅ **Success Criteria**

After deployment, verify:

- [ ] EC2 instance running
- [ ] Docker containers running
- [ ] Nginx serving requests
- [ ] API responds: `curl http://your-ip/health`
- [ ] Swagger accessible: `http://your-ip/api-docs`
- [ ] SSL working (production)
- [ ] Logs accessible
- [ ] Monitoring active
- [ ] Jenkins job succeeds
- [ ] Webhook triggers correctly

---

## 📞 **Quick Commands**

### **Local Development:**
```bash
docker-compose up -d          # Start
docker-compose logs -f        # Logs
docker-compose down           # Stop
docker-compose restart        # Restart
```

### **Production (EC2):**
```bash
ssh ubuntu@your-ec2-ip                    # Connect
cd /opt/daansetu-backend                  # Navigate
docker-compose logs -f                    # View logs
docker-compose restart                    # Restart
curl http://localhost/health              # Health check
```

### **Jenkins:**
```bash
sudo systemctl status jenkins     # Status
sudo systemctl restart jenkins    # Restart
sudo journalctl -u jenkins -f     # Logs
```

---

## 🎉 **What You Achieved**

✅ **Complete CI/CD Pipeline** - Fully automated  
✅ **Docker Containerization** - Portable & consistent  
✅ **Nginx Reverse Proxy** - Production-grade  
✅ **Terraform IaC** - Reproducible infrastructure  
✅ **AWS Deployment** - Cloud hosting  
✅ **GitHub Integration** - Auto-deploy on push  
✅ **One-Click Deployment** - Simple script  
✅ **Security Scanning** - Automated checks  
✅ **Health Monitoring** - CloudWatch alarms  
✅ **SSL Ready** - HTTPS support  

---

## 📖 **Related Documentation**

- `Dockerfile` - Container definition
- `docker-compose.yml` - Multi-container setup
- `Jenkinsfile` - CI/CD pipeline
- `terraform/` - Infrastructure code
- `nginx/` - Nginx configuration
- `scripts/deploy.sh` - One-click deployment

---

**Your DAANSETU backend has enterprise-grade deployment automation! 🚀**

**Next:** Run `./scripts/deploy.sh` and choose option 1 to test locally!

