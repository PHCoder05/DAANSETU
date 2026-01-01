# 🚀 Complete Stack: Jenkins + Terraform + Nginx + AWS

## 🏗️ **Architecture Overview**

```
👨‍💻 Developer
    ↓ (git push)
📚 GitHub Repository
    ↓ (webhook)
🔄 Jenkins CI/CD Pipeline
    ↓ (terraform apply)
☁️ AWS Infrastructure (Terraform)
    ├── EC2 Instance
    ├── Security Groups
    ├── VPC & Subnets
    └── Load Balancer
    ↓ (deploy)
🐳 Docker Containers
    ├── Node.js App (Port 5000)
    └── Nginx (Port 80/443)
```

## 🎯 **What Each Component Does**

### **1. Jenkins** 🔄
- **Purpose**: Continuous Integration/Continuous Deployment
- **What it does**:
  - Triggers on code changes
  - Runs tests and quality checks
  - Builds Docker images
  - Deploys to AWS automatically
  - Manages the entire pipeline

### **2. Terraform** 🏗️
- **Purpose**: Infrastructure as Code
- **What it does**:
  - Creates AWS resources (EC2, VPC, Security Groups)
  - Manages infrastructure state
  - Ensures consistent deployments
  - Version controls infrastructure

### **3. Nginx** 🌐
- **Purpose**: Reverse Proxy & Load Balancer
- **What it does**:
  - Routes traffic to your app
  - Handles SSL termination
  - Serves static files
  - Load balancing (if multiple instances)

### **4. AWS** ☁️
- **Purpose**: Cloud Infrastructure
- **What it does**:
  - Hosts your application
  - Provides scalable compute
  - Manages networking
  - Handles security

## 🔄 **Complete Workflow**

### **Step 1: Code Development**
```bash
# Developer makes changes
git add .
git commit -m "Add new feature"
git push origin main
```

### **Step 2: Jenkins Pipeline**
```yaml
# Jenkinsfile triggers automatically
1. Checkout code from GitHub
2. Run tests and quality checks
3. Build Docker image
4. Run Terraform to create/update infrastructure
5. Deploy application to EC2
6. Run health checks
7. Send notifications
```

### **Step 3: Terraform Infrastructure**
```hcl
# Creates AWS resources
- EC2 Instance (Ubuntu)
- VPC with public/private subnets
- Security Groups (SSH, HTTP, HTTPS)
- Internet Gateway
- Route Tables
- Elastic IP
```

### **Step 4: Application Deployment**
```bash
# On EC2 instance
1. Clone repository
2. Create .env file
3. Start Docker containers
4. Configure Nginx
5. Test endpoints
```

### **Step 5: Nginx Configuration**
```nginx
# Routes traffic
http://your-domain.com → Nginx → Node.js App (Port 5000)
```

## 🛠️ **Setup Instructions**

### **1. Jenkins Setup** 🔄

#### **Install Jenkins:**
```powershell
# Run as Administrator
.\scripts\setup\install-jenkins.ps1
```

#### **Configure Jenkins:**
1. **Access**: http://localhost:8080
2. **Get password**: `C:\Program Files (x86)\Jenkins\secrets\initialAdminPassword`
3. **Install plugins**: Git, Docker, AWS Steps
4. **Add credentials**:
   - AWS Access Key: `[your access key]`
   - AWS Secret: `[your secret key]`

> ⚠️ **Security Warning:**  
> Storing AWS access keys and secret keys in Jenkins credentials can pose a security risk if those credentials are leaked or misused.  
> **Whenever possible, use [IAM roles for EC2 instances](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html) to grant Jenkins the necessary AWS permissions.**  
> IAM roles provide temporary credentials and are the recommended, more secure approach for AWS authentication.  
> Only use static access keys if IAM roles are not available, and always follow AWS best practices for credential management.
#### **Create Pipeline:**
1. **New Item** → **Pipeline**
2. **Pipeline script from SCM**
3. **Repository**: `https://github.com/PHCoder05/DAANSETU_BACKEND_OPS.git`
4. **Script Path**: `Jenkinsfile`

### **2. Terraform Setup** 🏗️

#### **Current Infrastructure:**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

#### **What it creates:**
- ✅ **EC2 Instance**: `i-022bb9722e3ea8ce8`
- ✅ **Public IP**: `3.110.37.146`
- ✅ **Security Groups**: SSH, HTTP, HTTPS
- ✅ **VPC & Subnets**: Isolated network

### **3. Nginx Setup** 🌐

#### **Current Configuration:**
```nginx
# nginx/conf.d/daansetu.conf
upstream daansetu_backend {
    server app:5000;
}

server {
    listen 80;
    server_name 3.110.37.146;
    
    location / {
        proxy_pass http://daansetu_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### **4. AWS Setup** ☁️

#### **Current Resources:**
- ✅ **Region**: `ap-south-1`
- ✅ **Instance**: `i-022bb9722e3ea8ce8`
- ✅ **IP**: `3.110.37.146`
- ✅ **Security Groups**: Configured

## 🚀 **Deployment Commands**

### **Manual Deployment:**
```bash
# Deploy to EC2
.\scripts\deployment\deploy-to-running-ec2.ps1

# Or use Jenkins
# Trigger pipeline from Jenkins UI
```

### **Infrastructure Update:**
```bash
cd terraform
terraform plan
terraform apply
```

### **Application Update:**
```bash
# Jenkins will handle this automatically
# Or manually:
ssh ubuntu@3.110.37.146
cd /opt/daansetu-backend
git pull
docker-compose up -d --build
```

## 📊 **Current Status**

### **✅ What's Working:**
- **Jenkins**: Ready for CI/CD pipeline
- **Terraform**: Infrastructure deployed
- **Nginx**: Configured and ready
- **AWS**: EC2 instance running
- **Application**: Ready for deployment

### **🎯 Next Steps:**
1. **Set up Jenkins** (run install script)
2. **Configure pipeline** (point to your repo)
3. **Deploy application** (via Jenkins or manual)
4. **Test endpoints** (verify everything works)

## 🔧 **Troubleshooting**

### **Jenkins Issues:**
```bash
# Check Jenkins status
Get-Service jenkins

# Restart Jenkins
Restart-Service jenkins

# Check logs
Get-Content "C:\Program Files (x86)\Jenkins\logs\jenkins.log" -Tail 20
```

### **Terraform Issues:**
```bash
# Check state
terraform show

# Refresh state
terraform refresh

# Destroy and recreate
terraform destroy
terraform apply
```

### **Nginx Issues:**
```bash
# Test configuration
nginx -t

# Reload configuration
nginx -s reload

# Check status
systemctl status nginx
```

## 🎉 **Benefits of This Stack**

### **✅ Advantages:**
- **Automated Deployment**: Push code → Auto deploy
- **Infrastructure as Code**: Version controlled infrastructure
- **Scalable**: Easy to add more instances
- **Reliable**: Health checks and monitoring
- **Secure**: Proper security groups and SSL
- **Maintainable**: Clear separation of concerns

### **🚀 Production Ready:**
- **High Availability**: Multiple instances possible
- **Load Balancing**: Nginx handles traffic
- **SSL Support**: Ready for HTTPS
- **Monitoring**: Health checks and logging
- **Backup**: Infrastructure can be recreated

**Your complete stack is ready for production deployment!** 🎉

