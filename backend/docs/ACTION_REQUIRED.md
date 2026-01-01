# 🎯 DAANSETU - Actions Required from You

## 📋 **What You Need to Do**

---

## ⚡ **OPTION 1: Quick Local Test (NO credentials needed!)**

### **Action: Just run this**

```bash
# 1. Start the server
docker-compose up -d

# 2. Open Swagger
open http://localhost/api-docs

# 3. Test endpoints!
```

**Required from you:** Nothing! Just run the command!

**Time:** 30 seconds

**Result:** API running locally with Nginx!

---

## 🚀 **OPTION 2: Deploy to AWS (Production)**

### **Step 1: Create AWS Account**

**Action Required:**
1. Go to https://aws.amazon.com
2. Click "Create an AWS Account"
3. Follow signup process
4. **Save:** Your AWS Account ID

**Cost:** Free tier for 12 months, then ~$20/month

---

### **Step 2: Create IAM User for Deployment**

**Actions:**

1. **Login to AWS Console** → https://console.aws.amazon.com

2. **Go to IAM** → Users → Create User

3. **User Details:**
   - Username: `daansetu-deployer`
   - Access type: ✅ Programmatic access

4. **Attach Policies:**
   - ✅ AmazonEC2FullAccess
   - ✅ AmazonVPCFullAccess
   - ✅ CloudWatchFullAccess
   - ✅ IAMFullAccess (for role creation)

5. **Download CSV** → **SAVE THIS!**
   - Contains: Access Key ID
   - Contains: Secret Access Key

**What I need from you:**
- ✅ AWS Access Key ID
- ✅ AWS Secret Access Key

---

### **Step 3: Configure AWS CLI**

**Action:**

```bash
# Install AWS CLI (if not installed)
# Windows: Download from https://aws.amazon.com/cli/

# Configure
aws configure

# Enter when prompted:
AWS Access Key ID: [YOUR_ACCESS_KEY_ID]
AWS Secret Access Key: [YOUR_SECRET_ACCESS_KEY]
Default region name: us-east-1
Default output format: json
```

**What I need:** Your input for the prompts above

---

### **Step 4: Generate SSH Key for EC2**

**Action:**

```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/daansetu-ec2-key

# When prompted:
# - Press Enter for default location
# - Press Enter for no passphrase (or set one)

# Get public key
cat ~/.ssh/daansetu-ec2-key.pub
```

**What I need from you:**
- ✅ Copy the public key output (starts with `ssh-rsa`)

---

### **Step 5: Create S3 Bucket for Terraform State**

**Action:**

```bash
# Create bucket (replace 'your-name' with something unique)
aws s3 mb s3://daansetu-terraform-state-your-name --region us-east-1

# Create DynamoDB table for locking
aws dynamodb create-table \
    --table-name daansetu-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

**What I need:** Just run these commands

---

### **Step 6: Configure Terraform Variables**

**Action:**

```bash
# Navigate to terraform folder
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit the file
code terraform.tfvars  # or nano/vim
```

**Update these values:**

```hcl
# AWS Configuration
aws_region    = "us-east-1"
environment   = "production"
project_name  = "daansetu-backend"

# Network
vpc_cidr = "10.0.0.0/16"

# EC2
instance_type = "t3.small"  # $15/month

# Security - UPDATE THESE!
allowed_ssh_ips = ["YOUR_IP_ADDRESS/32"]  # Your public IP
allowed_app_ips = ["0.0.0.0/0"]

# SSH Key - PASTE THE PUBLIC KEY FROM STEP 4
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... [YOUR PUBLIC KEY]"

# MongoDB - YOUR PRODUCTION URI
mongodb_uri = "mongodb+srv://prod_user:PASSWORD@cluster.mongodb.net/"

# JWT Secrets - GENERATE NEW SECURE ONES
jwt_secret         = "GENERATE_64_CHAR_STRING"
jwt_refresh_secret = "GENERATE_DIFFERENT_64_CHAR_STRING"

# Admin Setup Key - GENERATE SECURE KEY
admin_setup_key = "GENERATE_SECURE_SETUP_KEY"

# CORS - YOUR FRONTEND DOMAIN
cors_origin = "https://yourdomain.com"  # or "*" for development
```

**What I need from you:**

1. **Your IP Address:**
   ```bash
   # Find your IP
   curl ifconfig.me
   ```
   Copy this value for `allowed_ssh_ips`

2. **MongoDB Production URI:**
   - Your MongoDB Atlas connection string
   - Create production cluster if needed

3. **Generate Secure Secrets:**
   ```bash
   # JWT Secret
   node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
   
   # JWT Refresh Secret (run again for different value)
   node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
   
   # Admin Setup Key
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```
   Copy these values into terraform.tfvars

4. **Your Frontend Domain (if you have one):**
   - e.g., `https://daansetu.com`
   - Or use `*` for development

---

### **Step 7: Deploy with Terraform**

**Action:**

```bash
# Still in terraform folder
terraform init
terraform plan
terraform apply

# When prompted, type: yes
```

**What I need:** Just confirm with "yes" when prompted

**Result:** 
- AWS infrastructure created
- EC2 instance running
- You'll get output like:
  ```
  ec2_public_ip = "54.123.45.67"
  api_url = "http://54.123.45.67"
  swagger_url = "http://54.123.45.67/api-docs"
  ```

**Save these values!**

---

## 🔧 **OPTION 3: Setup CI/CD (Optional but Recommended)**

### **Method A: GitHub Actions (Easier)**

**Actions Required:**

1. **Go to GitHub Repository Settings** → Secrets and variables → Actions

2. **Add These Secrets:**

   Click "New repository secret" for each:

   | Name | Value | Where to Get |
   |------|-------|--------------|
   | `AWS_ACCESS_KEY_ID` | Your AWS key | From Step 2 CSV |
   | `AWS_SECRET_ACCESS_KEY` | Your AWS secret | From Step 2 CSV |
   | `DOCKER_USERNAME` | Docker Hub username | Create at hub.docker.com |
   | `DOCKER_PASSWORD` | Docker Hub token | hub.docker.com → Account Settings → Security |
   | `EC2_HOST` | EC2 public IP | From Terraform output |
   | `SSH_PRIVATE_KEY` | Private SSH key | `cat ~/.ssh/daansetu-ec2-key` |

3. **Done!** Now `git push origin main` will auto-deploy!

---

### **Method B: Jenkins (More Powerful)**

**Actions Required:**

1. **Install Jenkins:**
   ```bash
   cd jenkins
   chmod +x setup-jenkins.sh
   ./setup-jenkins.sh
   ```

2. **Access Jenkins:** http://localhost:8080

3. **Initial Password:**
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
   Copy and paste this into Jenkins

4. **Install Plugins:**
   - Select "Install suggested plugins"
   - Additionally install:
     - GitHub plugin
     - Docker plugin
     - AWS Steps plugin

5. **Add Credentials in Jenkins:**

   Go to: Manage Jenkins → Credentials → Global → Add Credentials

   **Add These:**

   a) **GitHub Credentials**
   - Type: Username with password
   - ID: `github-credentials`
   - Username: Your GitHub username
   - Password: Personal Access Token
     - Get token: GitHub → Settings → Developer settings → Personal access tokens
     - Scopes needed: `repo`, `admin:repo_hook`

   b) **AWS Credentials**
   - Type: AWS Credentials
   - ID: `aws-credentials`
   - Access Key ID: [From Step 2]
   - Secret Access Key: [From Step 2]

   c) **Docker Hub Credentials**
   - Type: Username with password
   - ID: `docker-credentials`
   - Username: Docker Hub username
   - Password: Docker Hub access token

   d) **EC2 Host**
   - Type: Secret text
   - ID: `ec2-host`
   - Secret: Your EC2 IP (from Terraform output)

   e) **SSH Private Key**
   - Type: SSH Username with private key
   - ID: `ec2-ssh-key`
   - Username: `ubuntu`
   - Private Key: Paste content of `~/.ssh/daansetu-ec2-key`

6. **Create Pipeline Job:**
   - New Item → Name: "DAANSETU-Backend"
   - Type: Pipeline
   - ✅ GitHub hook trigger for GITScm polling
   - Pipeline → SCM: Git
   - Repository URL: Your GitHub repo URL
   - Credentials: github-credentials
   - Branch: */main
   - Script Path: Jenkinsfile
   - Save

7. **Configure GitHub Webhook:**
   - Go to your GitHub repo
   - Settings → Webhooks → Add webhook
   - Payload URL: `http://your-jenkins-server:8080/github-webhook/`
   - Content type: application/json
   - Select: Just the push event
   - Active: ✅

---

## 📝 **CREDENTIALS CHECKLIST**

### **✅ Required for AWS Deployment:**

- [ ] AWS Account created
- [ ] AWS Access Key ID
- [ ] AWS Secret Access Key
- [ ] SSH public key generated
- [ ] Your public IP address
- [ ] MongoDB production URI
- [ ] JWT secret (generated)
- [ ] JWT refresh secret (generated)
- [ ] Admin setup key (generated)

### **✅ Optional for CI/CD (GitHub Actions):**

- [ ] Docker Hub account
- [ ] Docker Hub access token
- [ ] GitHub secrets added

### **✅ Optional for CI/CD (Jenkins):**

- [ ] Jenkins installed
- [ ] Jenkins credentials added
- [ ] Pipeline job created
- [ ] GitHub webhook configured

---

## 🎯 **WHAT TO DO NOW (Step by Step)**

### **Immediate (5 minutes):**

```bash
# 1. Test locally (no credentials needed!)
docker-compose up -d

# 2. Open Swagger
open http://localhost/api-docs

# 3. Test some endpoints
# - Try POST /api/setup/check
# - Try any endpoint you want!
```

---

### **This Week (If deploying to AWS):**

**Day 1: AWS Setup (30 minutes)**
- [ ] Create AWS account
- [ ] Create IAM user
- [ ] Configure AWS CLI
- [ ] Generate SSH key
- [ ] Create S3 bucket
- [ ] Create DynamoDB table

**Day 2: Configuration (15 minutes)**
- [ ] Find your public IP: `curl ifconfig.me`
- [ ] Generate JWT secrets (3 commands)
- [ ] Update `terraform/terraform.tfvars`
- [ ] Review configuration

**Day 3: Deploy (10 minutes)**
- [ ] `terraform init`
- [ ] `terraform plan` (review)
- [ ] `terraform apply` (type "yes")
- [ ] Save EC2 IP from output
- [ ] Test: `curl http://EC2_IP/health`

**Day 4: Setup SSL (Optional - 10 minutes)**
- [ ] SSH to EC2: `ssh -i ~/.ssh/daansetu-ec2-key.pem ubuntu@EC2_IP`
- [ ] Run: `sudo certbot --nginx -d api.yourdomain.com`
- [ ] Test: `curl https://api.yourdomain.com/health`

**Day 5: Setup CI/CD (Optional - 30 minutes)**
- [ ] Choose: GitHub Actions or Jenkins
- [ ] Add credentials
- [ ] Test auto-deploy

---

## 🔑 **HOW TO GET EACH CREDENTIAL**

### **1. AWS Access Keys**

```
1. Login to AWS Console
2. IAM → Users → Create User
3. Name: daansetu-deployer
4. Permissions: EC2, VPC, CloudWatch
5. Create → Download CSV
6. Save: Access Key ID + Secret Access Key
```

---

### **2. MongoDB URI**

**If you don't have MongoDB Atlas:**

```
1. Go to https://www.mongodb.com/cloud/atlas
2. Sign up (free)
3. Create Cluster → Free tier (M0)
4. Database Access → Add user
   - Username: daansetu_prod
   - Password: [Generate strong password]
5. Network Access → Add IP
   - Add your EC2 IP (after Terraform creates it)
   - Or: 0.0.0.0/0 (allow all - not recommended)
6. Connect → Get connection string
   - Format: mongodb+srv://username:password@cluster.mongodb.net/
```

**Save:** Complete connection string

---

### **3. SSH Key Pair**

```bash
# Generate
ssh-keygen -t rsa -b 4096 -f ~/.ssh/daansetu-ec2-key

# Get public key (for Terraform)
cat ~/.ssh/daansetu-ec2-key.pub

# Get private key (for Jenkins/GitHub Actions)
cat ~/.ssh/daansetu-ec2-key
```

**Save:** Both public and private keys

---

### **4. JWT Secrets**

```bash
# Run these 3 commands:

# 1. JWT Secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# 2. JWT Refresh Secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# 3. Admin Setup Key
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

**Save:** All 3 generated strings

---

### **5. Docker Hub (Optional - for CI/CD)**

**If you don't have Docker Hub:**

```
1. Go to https://hub.docker.com
2. Sign up (free)
3. Username: [choose username]
4. After signup:
   - Account Settings → Security
   - New Access Token
   - Description: "DAANSETU CI/CD"
   - Copy token
```

**Save:** Username + Access Token

---

### **6. Your Public IP**

```bash
# Find your IP
curl ifconfig.me

# Or visit
# https://whatismyipaddress.com/
```

**Save:** Your IP address (e.g., `123.45.67.89`)

---

### **7. Domain Name (Optional)**

**If you want custom domain (e.g., api.daansetu.org):**

```
1. Buy domain from:
   - Namecheap (~$12/year)
   - GoDaddy
   - Google Domains
   
2. After Terraform creates EC2:
   - Add A Record
   - Name: api
   - Value: [EC2 IP from Terraform]
   - TTL: 300
```

**Save:** Domain name

---

## 📝 **CONFIGURATION FILES TO UPDATE**

### **File 1: `terraform/terraform.tfvars`**

**Location:** `D:\EDI\DAANSETU_BACKEND\terraform\terraform.tfvars`

**Create from example:**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

**Edit and add:**

```hcl
# YOUR AWS REGION
aws_region = "us-east-1"

# YOUR IP FOR SSH ACCESS
allowed_ssh_ips = ["123.45.67.89/32"]  # ← Your IP from step 6

# YOUR SSH PUBLIC KEY
ssh_public_key = "ssh-rsa AAAAB3Nza..."  # ← From step 3

# YOUR MONGODB URI
mongodb_uri = "mongodb+srv://user:pass@cluster.mongodb.net/"  # ← From step 2

# YOUR JWT SECRETS (from step 4)
jwt_secret = "abc123..."  # ← Generated in step 4
jwt_refresh_secret = "def456..."  # ← Generated in step 4
admin_setup_key = "ghi789..."  # ← Generated in step 4

# YOUR DOMAIN (optional)
cors_origin = "https://yourdomain.com"  # or "*" for dev
```

---

### **File 2: `.env` (Already exists, but verify)**

**Location:** `D:\EDI\DAANSETU_BACKEND\.env`

**Should contain:**

```env
# Verify these values match your production setup
MONGODB_URI=mongodb+srv://root:root@cluster0.rxcp0.mongodb.net/...
PORT=5000
NODE_ENV=development
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
ADMIN_SETUP_KEY=change-this-setup-key-in-production
CORS_ORIGIN=*
```

**For production, generate new secrets!**

---

### **File 3: GitHub Secrets (if using GitHub Actions)**

**Location:** Your GitHub repo → Settings → Secrets and variables → Actions

**Add these secrets:**

| Secret Name | Value | From |
|-------------|-------|------|
| `AWS_ACCESS_KEY_ID` | [Your AWS key] | Step 2 |
| `AWS_SECRET_ACCESS_KEY` | [Your AWS secret] | Step 2 |
| `DOCKER_USERNAME` | [Docker username] | Step 5 |
| `DOCKER_PASSWORD` | [Docker token] | Step 5 |
| `EC2_HOST` | [EC2 IP] | After Terraform |
| `SSH_PRIVATE_KEY` | [Private key] | Step 3 |

---

## 🎯 **SUMMARY: What You Need to Provide**

### **Accounts to Create:**
1. ✅ AWS Account (free tier available)
2. ✅ MongoDB Atlas Account (free tier available)
3. ✅ Docker Hub Account (optional, free)
4. ✅ GitHub Account (you probably have this)

### **Credentials to Generate:**
1. ✅ AWS Access Key + Secret
2. ✅ SSH Key Pair
3. ✅ JWT Secrets (3 values)
4. ✅ Docker Hub token (optional)

### **Information to Find:**
1. ✅ Your public IP address
2. ✅ MongoDB connection string
3. ✅ Your domain name (optional)

### **Files to Update:**
1. ✅ `terraform/terraform.tfvars`
2. ✅ `.env` (for production values)
3. ✅ GitHub Secrets (if using GitHub Actions)

---

## ⚡ **EASIEST PATH (Recommended)**

### **Start with Local Testing (NO credentials!):**

```bash
# Just run this - works immediately!
docker-compose up -d
open http://localhost/api-docs
```

**You can test EVERYTHING without any credentials!**

---

### **When Ready for Production:**

**Week 1: Setup Accounts**
- Create AWS account
- Create MongoDB Atlas account
- Generate credentials

**Week 2: Deploy**
- Configure Terraform
- Run `terraform apply`
- Test production API

**Week 3: Automate**
- Setup GitHub Actions
- Configure webhook
- Test auto-deploy

---

## 📞 **WHAT I NEED FROM YOU - QUICK LIST**

### **For Local Testing:**
- ✅ Nothing! Just run `docker-compose up -d`

### **For AWS Deployment:**
1. AWS Access Key ID
2. AWS Secret Access Key
3. Your public IP address
4. SSH public key (I'll help generate)
5. MongoDB connection string
6. 3 generated secrets (I'll help generate)

### **For CI/CD:**
1. Docker Hub username + token (optional)
2. GitHub secrets added (I'll guide you)

---

## 🎯 **RECOMMENDED APPROACH**

### **Phase 1: Test Locally (Today - 5 minutes)**

```bash
docker-compose up -d
# Test everything locally
# NO credentials needed!
```

### **Phase 2: Setup AWS (This Week - 1 hour)**

```
1. Create AWS account
2. Create IAM user
3. Configure AWS CLI
4. Generate SSH keys
5. Get MongoDB URI
6. Generate JWT secrets
7. Update terraform.tfvars
8. Run terraform apply
```

### **Phase 3: Automate (Next Week - 30 minutes)**

```
1. Choose: GitHub Actions or Jenkins
2. Add credentials
3. Configure webhook
4. Test auto-deploy
```

---

## ✅ **QUICK ACTION CHECKLIST**

### **Right Now (No credentials):**
- [ ] Run: `docker-compose up -d`
- [ ] Open: http://localhost/api-docs
- [ ] Test endpoints
- [ ] Read documentation

### **Before AWS Deploy:**
- [ ] Create AWS account
- [ ] Get AWS access keys
- [ ] Generate SSH keys
- [ ] Find your IP
- [ ] Get MongoDB URI
- [ ] Generate JWT secrets
- [ ] Update terraform.tfvars

### **Before CI/CD:**
- [ ] Create Docker Hub account
- [ ] Get Docker token
- [ ] Add GitHub secrets
- [ ] Configure webhook

---

## 💡 **PRO TIP**

**Start simple, add complexity later:**

1. **Today:** Test locally (docker-compose)
2. **This week:** Deploy to AWS (terraform)
3. **Next week:** Add CI/CD (optional)
4. **Later:** Add SSL, monitoring, backups

**You can go to production without CI/CD!**
Just use Terraform, then manually deploy updates.

---

## 📞 **NEED HELP?**

### **Generating Credentials:**

```bash
# I can help! Just run:

# Find your IP
curl ifconfig.me

# Generate all secrets at once
node -e "
console.log('JWT_SECRET=', require('crypto').randomBytes(64).toString('hex'));
console.log('JWT_REFRESH_SECRET=', require('crypto').randomBytes(64).toString('hex'));
console.log('ADMIN_SETUP_KEY=', require('crypto').randomBytes(32).toString('hex'));
"

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/daansetu-ec2-key
```

### **Step-by-Step Guides:**

- AWS Setup: `docs/ONE_CLICK_DEPLOYMENT.md` → Phase 4
- Terraform: `docs/CI_CD_SETUP.md` → Phase 4
- CI/CD: `docs/CI_CD_SETUP.md` → Phase 2 & 3

---

## 🎉 **SUMMARY**

**To test locally:** Nothing needed!  
**To deploy to AWS:** 7 credentials/values  
**To automate CI/CD:** Additional 4 credentials (optional)  

**Easiest path:** Start with `docker-compose up -d` → no credentials needed!

---

**Ready to start? Run this now:**

```bash
docker-compose up -d
open http://localhost/api-docs
```

**No credentials required! ✅**

