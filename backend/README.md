# 🚀 DAANSETU Backend - Complete CI/CD Pipeline

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/PHCoder05/DAANSETU_BACKEND_OPS)
[![Deployment](https://img.shields.io/badge/deployment-automated-blue)](https://github.com/PHCoder05/DAANSETU_BACKEND_OPS)
[![Infrastructure](https://img.shields.io/badge/infrastructure-terraform-orange)](https://github.com/PHCoder05/DAANSETU_BACKEND_OPS)
[![Docker](https://img.shields.io/badge/docker-containerized-blue)](https://github.com/PHCoder05/DAANSETU_BACKEND_OPS)

A complete backend API for DAANSETU with automated CI/CD pipeline, infrastructure as code, and one-click deployment.

## 🎯 Features

### ✅ **Complete Backend API**
- 52+ Production-ready endpoints
- JWT authentication & authorization
- Password reset flow
- Reviews & ratings system
- Advanced search functionality
- Admin dashboard & analytics
- Real-time notifications
- NGO verification system

### ✅ **DevOps & Infrastructure**
- **Terraform** - Infrastructure as Code
- **Docker** - Containerized deployment
- **Nginx** - Reverse proxy & load balancing
- **Jenkins** - CI/CD pipeline
- **AWS EC2** - Cloud hosting
- **MongoDB** - Database
- **Winston** - Logging system

### ✅ **One-Click Deployment**
- Automated Git operations
- Infrastructure provisioning
- Application deployment
- Health checks & validation
- Rollback capabilities

## 🚀 Quick Start

### **Option 1: One-Click Deployment (Recommended)**

```powershell
# Run the complete deployment script
.\scripts\one-click-deploy.ps1
```

This single command will:
1. ✅ Clean up project files
2. 🔧 Initialize Git repository
3. 📤 Push code to GitHub
4. 🏗️ Run Terraform infrastructure
5. 🤖 Trigger Jenkins CI/CD pipeline
6. 🚀 Deploy to EC2 automatically
7. ✅ Verify deployment

### **Option 2: Manual Steps**

```bash
# 1. Clone repository
git clone https://github.com/PHCoder05/DAANSETU_BACKEND_OPS.git
cd DAANSETU_BACKEND_OPS

# 2. Install dependencies
npm install

# 3. Configure environment
cp .env.example .env
# Edit .env with your values

# 4. Run locally
docker-compose up -d

# 5. Deploy to AWS
cd terraform
terraform init
terraform apply
```

## 📋 Prerequisites

- **Git** - Version control
- **Node.js** - Runtime environment
- **Docker** - Containerization
- **AWS CLI** - Cloud operations
- **Terraform** - Infrastructure management
- **Jenkins** - CI/CD (optional)

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│   Jenkins CI/CD │───▶│   AWS EC2       │
│                 │    │                 │    │                 │
│ • Source Code   │    │ • Build & Test  │    │ • Application   │
│ • Jenkinsfile   │    │ • Deploy        │    │ • Nginx Proxy   │
│ • Terraform     │    │ • Notify        │    │ • Docker        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Terraform     │
                       │                 │
                       │ • VPC & Subnets │
                       │ • Security Groups│
                       │ • EC2 Instance  │
                       │ • Load Balancer │
                       └─────────────────┘
```

## 🔧 Configuration

### **Environment Variables**

```bash
# Database
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/
DB_NAME=daansetu

# JWT Secrets
JWT_SECRET=your-jwt-secret
JWT_REFRESH_SECRET=your-refresh-secret

# Admin Setup
ADMIN_SETUP_KEY=your-admin-key

# CORS
CORS_ORIGIN=*
```

### **Terraform Variables**

```hcl
# terraform/terraform.tfvars
aws_region    = "us-east-1"
environment   = "production"
project_name  = "daansetu-backend"
instance_type = "t3.small"
```

## 🚀 Deployment Options

### **1. One-Click Deployment**
```powershell
.\scripts\one-click-deploy.ps1
```

### **2. Jenkins Pipeline**
1. Set up Jenkins instance
2. Create new Pipeline job
3. Configure Git repository
4. Add AWS credentials
5. Run pipeline

### **3. Manual Deployment**
```bash
# Deploy infrastructure
cd terraform
terraform apply

# Deploy application
docker-compose up -d --build
```

## 📊 API Endpoints

### **Authentication**
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/logout` - User logout

### **Donations**
- `GET /api/donations` - List donations
- `POST /api/donations` - Create donation
- `GET /api/donations/:id` - Get donation details
- `PUT /api/donations/:id` - Update donation
- `DELETE /api/donations/:id` - Delete donation

### **NGOs**
- `GET /api/ngos` - List NGOs
- `POST /api/ngos` - Create NGO
- `GET /api/ngos/:id` - Get NGO details
- `PUT /api/ngos/:id` - Update NGO
- `POST /api/ngos/:id/verify` - Verify NGO

### **Admin**
- `GET /api/admin/dashboard` - Admin dashboard
- `POST /api/admin/seed` - Seed test data
- `GET /api/admin/users` - List users
- `GET /api/admin/analytics` - Analytics data

### **Health & Documentation**
- `GET /` - API information
- `GET /health` - Health check
- `GET /api-docs` - Swagger documentation

## 🔍 Monitoring & Logs

### **Health Checks**
```bash
# Check API health
curl http://your-domain/health

# Check container status
docker ps

# View logs
docker-compose logs -f
```

### **Log Files**
- `logs/combined.log` - All logs
- `logs/error.log` - Error logs only
- `logs/exceptions.log` - Exception logs

## 🛠️ Development

### **Local Development**
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run with Docker
docker-compose up -d
```

### **Testing**
```bash
# Run tests
npm test

# Run with coverage
npm run test:coverage
```

## 📚 Documentation

- **API Documentation**: `/api-docs` (Swagger UI)
- **Postman Collection**: `DAANSETU.postman_collection.json`
- **Architecture Guide**: `docs/ARCHITECTURE.md`
- **Deployment Guide**: `docs/DEPLOYMENT.md`

## 🔒 Security

- JWT-based authentication
- Password hashing with bcrypt
- CORS configuration
- Input validation
- Rate limiting
- Security headers

## 📈 Performance

- Docker containerization
- Nginx reverse proxy
- Connection pooling
- Caching strategies
- Health checks
- Auto-scaling ready

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Run tests
5. Submit pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/PHCoder05/DAANSETU_BACKEND_OPS/issues)
- **Documentation**: [Wiki](https://github.com/PHCoder05/DAANSETU_BACKEND_OPS/wiki)
- **Email**: support@daansetu.org

## 🎉 Success Metrics

After successful deployment, you'll have:

- ✅ **Live API** at `http://your-domain/`
- ✅ **Health Check** at `http://your-domain/health`
- ✅ **API Docs** at `http://your-domain/api-docs`
- ✅ **Automated CI/CD** pipeline
- ✅ **Infrastructure as Code**
- ✅ **Monitoring & Logging**
- ✅ **Scalable Architecture**

---

**🚀 Ready to deploy? Run `.\scripts\one-click-deploy.ps1` and watch the magic happen!**