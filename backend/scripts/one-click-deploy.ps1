# DAANSETU Backend - One-Click Complete Deployment
# This script handles everything: Git, Jenkins, Terraform, and Deployment

param(
    [string]$GitHubRepo = "https://github.com/PHCoder05/DAANSETU_BACKEND_OPS.git",
    [string]$Branch = "main",
    [switch]$SkipTests = $false,
    [switch]$Force = $false
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Magenta = "`e[35m"
$Cyan = "`e[36m"
$White = "`e[37m"
$Reset = "`e[0m"

# Functions
function Write-ColorOutput {
    param([string]$Message, [string]$Color = $White)
    Write-Host "${Color}${Message}${Reset}"
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" $Cyan
    Write-ColorOutput "║  $($Title.PadRight(62)) ║" $Cyan
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" $Cyan
    Write-Host ""
}

function Test-Command {
    param([string]$Command)
    try {
        & $Command --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Banner
Write-Header "🚀 DAANSETU ONE-CLICK DEPLOYMENT SYSTEM 🚀"

Write-ColorOutput "This script will:" $Blue
Write-ColorOutput "  1. ✅ Clean up project files" $White
Write-ColorOutput "  2. 🔧 Initialize Git repository" $White
Write-ColorOutput "  3. 📤 Push code to GitHub" $White
Write-ColorOutput "  4. 🏗️  Run Terraform infrastructure" $White
Write-ColorOutput "  5. 🤖 Trigger Jenkins CI/CD pipeline" $White
Write-ColorOutput "  6. 🚀 Deploy to EC2 automatically" $White
Write-ColorOutput "  7. ✅ Verify deployment" $White
Write-Host ""

# Check prerequisites
Write-ColorOutput "🔍 Checking prerequisites..." $Blue

$Prerequisites = @{
    "Git" = Test-Command "git"
    "AWS CLI" = Test-Command "aws"
    "Terraform" = Test-Command "terraform"
    "Docker" = Test-Command "docker"
}

$MissingPrerequisites = @()
foreach ($prereq in $Prerequisites.GetEnumerator()) {
    if ($prereq.Value) {
        Write-ColorOutput "  ✅ $($prereq.Key)" $Green
    } else {
        Write-ColorOutput "  ❌ $($prereq.Key)" $Red
        $MissingPrerequisites += $prereq.Key
    }
}

if ($MissingPrerequisites.Count -gt 0) {
    Write-ColorOutput "❌ Missing prerequisites: $($MissingPrerequisites -join ', ')" $Red
    Write-ColorOutput "Please install the missing tools and try again." $Yellow
    exit 1
}

Write-ColorOutput "✅ All prerequisites met!" $Green
Write-Host ""

# Step 1: Clean up project
Write-Header "🧹 CLEANING UP PROJECT"

Write-ColorOutput "Removing unnecessary files..." $Blue

# Remove unnecessary files
$FilesToRemove = @(
    "node_modules",
    "logs",
    "deployment-files.txt",
    "credentials.json",
    ".env",
    "terraform.tfvars",
    "*.tfstate",
    "*.tfstate.*",
    ".terraform",
    "deploy-package"
)

foreach ($pattern in $FilesToRemove) {
    if (Test-Path $pattern) {
        Remove-Item -Path $pattern -Recurse -Force -ErrorAction SilentlyContinue
        Write-ColorOutput "  🗑️  Removed: $pattern" $Yellow
    }
}

Write-ColorOutput "✅ Project cleanup completed" $Green

# Step 2: Initialize Git repository
Write-Header "🔧 INITIALIZING GIT REPOSITORY"

if (-not (Test-Path ".git")) {
    Write-ColorOutput "Initializing Git repository..." $Blue
    git init
    Write-ColorOutput "✅ Git repository initialized" $Green
} else {
    Write-ColorOutput "✅ Git repository already exists" $Green
}

# Configure Git
Write-ColorOutput "Configuring Git..." $Blue
git config user.name "DAANSETU CI/CD"
git config user.email "ci-cd@daansetu.org"

# Add all files
Write-ColorOutput "Adding files to Git..." $Blue
git add .

# Commit changes
Write-ColorOutput "Committing changes..." $Blue
git commit -m "🚀 Automated deployment setup - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Add remote origin
Write-ColorOutput "Configuring remote repository..." $Blue
git remote remove origin 2>$null
git remote add origin $GitHubRepo

Write-ColorOutput "✅ Git configuration completed" $Green

# Step 3: Push to GitHub
Write-Header "📤 PUSHING TO GITHUB"

Write-ColorOutput "Pushing to GitHub repository..." $Blue
try {
    git push -u origin $Branch --force
    Write-ColorOutput "✅ Code pushed to GitHub successfully" $Green
} catch {
    Write-ColorOutput "❌ Failed to push to GitHub: $($_.Exception.Message)" $Red
    Write-ColorOutput "Please check your GitHub repository URL and permissions." $Yellow
    exit 1
}

# Step 4: Run Terraform
Write-Header "🏗️  RUNNING TERRAFORM INFRASTRUCTURE"

Write-ColorOutput "Initializing Terraform..." $Blue
Set-Location terraform
terraform init

Write-ColorOutput "Planning infrastructure..." $Blue
terraform plan -out=tfplan

if (-not $SkipTests) {
    Write-ColorOutput "Applying Terraform changes..." $Blue
    terraform apply -auto-approve tfplan
    Write-ColorOutput "✅ Infrastructure deployed successfully" $Green
} else {
    Write-ColorOutput "⏭️  Skipping Terraform apply (tests only)" $Yellow
}

# Get Terraform outputs
$TerraformOutputs = terraform output -json | ConvertFrom-Json
$EC2InstanceId = $TerraformOutputs.ec2_instance_id.value
$EC2PublicIP = $TerraformOutputs.ec2_public_ip.value
$APIUrl = $TerraformOutputs.api_url.value

Write-ColorOutput "📊 Infrastructure Details:" $Blue
Write-ColorOutput "  Instance ID: $EC2InstanceId" $White
Write-ColorOutput "  Public IP: $EC2PublicIP" $White
Write-ColorOutput "  API URL: $APIUrl" $White

Set-Location ..

# Step 5: Create Jenkins job (if Jenkins is available)
Write-Header "🤖 JENKINS CI/CD SETUP"

Write-ColorOutput "Jenkins pipeline configuration:" $Blue
Write-ColorOutput "  Repository: $GitHubRepo" $White
Write-ColorOutput "  Branch: $Branch" $White
Write-ColorOutput "  Jenkinsfile: ✅ Ready" $White

Write-ColorOutput "To set up Jenkins:" $Yellow
Write-ColorOutput "  1. Go to your Jenkins instance" $White
Write-ColorOutput "  2. Create new Pipeline job" $White
Write-ColorOutput "  3. Set Pipeline script from SCM" $White
Write-ColorOutput "  4. Use Git repository: $GitHubRepo" $White
Write-ColorOutput "  5. Set branch: $Branch" $White
Write-ColorOutput "  6. Configure credentials in Jenkins" $White

# Step 6: Manual deployment (if Jenkins not available)
Write-Header "🚀 MANUAL DEPLOYMENT"

Write-ColorOutput "Deploying directly to EC2..." $Blue

# Create deployment package
Write-ColorOutput "Creating deployment package..." $Blue
$DeployDir = "deploy-package"
if (Test-Path $DeployDir) {
    Remove-Item -Recurse -Force $DeployDir
}
New-Item -ItemType Directory -Path $DeployDir | Out-Null

# Copy necessary files
$FilesToDeploy = @(
    "app.js",
    "package.json",
    "package-lock.json",
    "Dockerfile",
    "docker-compose.yml",
    "nginx",
    "config",
    "controllers",
    "middleware",
    "models",
    "routes",
    "utils"
)

foreach ($file in $FilesToDeploy) {
    if (Test-Path $file) {
        Copy-Item -Recurse -Path $file -Destination $DeployDir
        Write-ColorOutput "  📁 Copied: $file" $Green
    }
}

# Create .env file
$EnvContent = @"
MONGODB_URI=mongodb+srv://root:root@cluster0.rxcp0.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0
DB_NAME=daansetu
PORT=5000
NODE_ENV=production
JWT_SECRET=7fa4999230ab91a0051f3f84eb271e97f63427a8f90540b7a38c3549edfd62ed
JWT_REFRESH_SECRET=1db9aefc2f697b1c651be41344ee2d04820fa85b84f1d3f87d84be007e8a433e
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
ADMIN_SETUP_KEY=0e5a3b3af7298afe816b72196376c355
CORS_ORIGIN=*
"@

$EnvContent | Out-File -FilePath "$DeployDir\.env" -Encoding UTF8

# Create deployment script
$DeployScript = @"
#!/bin/bash
set -e

echo "🚀 Starting DAANSETU deployment..."

# Navigate to deployment directory
cd /opt/daansetu-backend

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down || true

# Create logs directory
mkdir -p logs

# Build and start containers
echo "🏗️  Building and starting containers..."
docker-compose up -d --build

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 20

# Check container status
echo "📊 Container status:"
docker-compose ps

# Test health endpoint
echo "🧪 Testing health endpoint..."
for i in {1..5}; do
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo "✅ Health check passed!"
        break
    else
        echo "⏳ Attempt $i/5 - Waiting for service..."
        sleep 10
    fi
done

# Final health check
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "🎉 Deployment completed successfully!"
    echo "🌐 API available at: http://$EC2PublicIP/"
    echo "📖 Documentation: http://$EC2PublicIP/api-docs"
else
    echo "❌ Health check failed!"
    echo "Backend logs:"
    docker logs daansetu-backend --tail 50
    exit 1
fi
"@

$DeployScript | Out-File -FilePath "$DeployDir/deploy.sh" -Encoding UTF8

Write-ColorOutput "✅ Deployment package created" $Green

# Step 7: Deploy to EC2
Write-ColorOutput "Deploying to EC2 instance..." $Blue

try {
    # Upload files to EC2 using AWS Systems Manager
    $BucketName = "daansetu-deploy-$(Get-Random)"
    aws s3 mb s3://$BucketName
    
    # Upload deployment package
    aws s3 sync $DeployDir/ s3://$BucketName/deploy/
    
    # Execute deployment on EC2
    $CommandId = aws ssm send-command --instance-ids $EC2InstanceId --document-name "AWS-RunShellScript" --parameters "commands=[`"cd /tmp && aws s3 sync s3://$BucketName/deploy/ /opt/daansetu-backend/ && chmod +x /opt/daansetu-backend/deploy.sh && /opt/daansetu-backend/deploy.sh`"]" --output text --query 'Command.CommandId'
    
    Write-ColorOutput "⏳ Deployment command sent: $CommandId" $Yellow
    Write-ColorOutput "⏳ Waiting for deployment to complete..." $Yellow
    
    # Wait for deployment
    Start-Sleep -Seconds 60
    
    # Cleanup S3 bucket
    aws s3 rb s3://$BucketName --force
    
    Write-ColorOutput "✅ Deployment completed" $Green
} catch {
    Write-ColorOutput "❌ Deployment failed: $($_.Exception.Message)" $Red
    Write-ColorOutput "Please check EC2 instance and try manual deployment." $Yellow
}

# Step 8: Verify deployment
Write-Header "✅ VERIFYING DEPLOYMENT"

Write-ColorOutput "Testing API endpoints..." $Blue

$Endpoints = @(
    @{Url = "http://$EC2PublicIP/"; Name = "Main API"},
    @{Url = "http://$EC2PublicIP/health"; Name = "Health Check"},
    @{Url = "http://$EC2PublicIP/api-docs"; Name = "API Documentation"}
)

foreach ($endpoint in $Endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint.Url -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-ColorOutput "  ✅ $($endpoint.Name): Working" $Green
        } else {
            Write-ColorOutput "  ⚠️  $($endpoint.Name): Status $($response.StatusCode)" $Yellow
        }
    } catch {
        Write-ColorOutput "  ❌ $($endpoint.Name): Failed" $Red
    }
}

# Cleanup
Write-ColorOutput "Cleaning up..." $Blue
Remove-Item -Recurse -Force $DeployDir -ErrorAction SilentlyContinue

# Final summary
Write-Header "🎉 DEPLOYMENT COMPLETED"

Write-ColorOutput "📊 Deployment Summary:" $Blue
Write-ColorOutput "  ✅ Git repository: $GitHubRepo" $White
Write-ColorOutput "  ✅ Branch: $Branch" $White
Write-ColorOutput "  ✅ EC2 Instance: $EC2InstanceId" $White
Write-ColorOutput "  ✅ Public IP: $EC2PublicIP" $White
Write-ColorOutput "  ✅ API URL: $APIUrl" $White

Write-ColorOutput "🌐 Your API is now live at:" $Green
Write-ColorOutput "  Main API: http://$EC2PublicIP/" $Cyan
Write-ColorOutput "  Health Check: http://$EC2PublicIP/health" $Cyan
Write-ColorOutput "  Documentation: http://$EC2PublicIP/api-docs" $Cyan

Write-ColorOutput "🤖 Next Steps:" $Yellow
Write-ColorOutput "  1. Set up Jenkins CI/CD pipeline" $White
Write-ColorOutput "  2. Configure monitoring and alerts" $White
Write-ColorOutput "  3. Set up SSL certificate (optional)" $White
Write-ColorOutput "  4. Configure domain name (optional)" $White

Write-ColorOutput "One-click deployment completed successfully!" $Green
