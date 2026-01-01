# Deploy via AWS Systems Manager (No SSH needed)
param(
    [string]$EC2_IP = "3.110.37.146",
    [string]$InstanceId = "i-022bb9722e3ea8ce8"
)

Write-Host "DAANSETU EC2 Deployment via SSM" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green

Write-Host "Deployment Details:" -ForegroundColor Blue
Write-Host "   EC2 IP: $EC2_IP" -ForegroundColor White
Write-Host "   Instance ID: $InstanceId" -ForegroundColor White
Write-Host ""

# Step 1: Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Blue
$deployDir = "deploy-package"
if (Test-Path $deployDir) {
    Remove-Item -Recurse -Force $deployDir
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

# Copy necessary files
$filesToCopy = @(
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

foreach ($file in $filesToCopy) {
    if (Test-Path $file) {
        Copy-Item -Recurse -Path $file -Destination $deployDir
        Write-Host "   Copied: $file" -ForegroundColor Green
    } else {
        Write-Host "   Missing: $file" -ForegroundColor Yellow
    }
}

# Create .env file for production
$envContent = @"
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

$envContent | Out-File -FilePath "$deployDir\.env" -Encoding UTF8
Write-Host "   Created: .env" -ForegroundColor Green

# Step 2: Upload files to S3 (temporary)
Write-Host "Uploading to S3..." -ForegroundColor Blue
$bucketName = "daansetu-deploy-$(Get-Random)"
aws s3 mb s3://$bucketName
aws s3 sync $deployDir s3://$bucketName/deploy/

# Step 3: Download and deploy on EC2
Write-Host "Deploying on EC2..." -ForegroundColor Blue

$deployScript = @"
#!/bin/bash
set -e

echo 'Starting DAANSETU deployment...'

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
    echo 'Installing AWS CLI...'
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

# Create deployment directory
sudo mkdir -p /opt/daansetu-backend
sudo chown ubuntu:ubuntu /opt/daansetu-backend
cd /opt/daansetu-backend

# Download files from S3
aws s3 sync s3://$bucketName/deploy/ .

# Stop any running containers
echo 'Stopping existing containers...'
docker-compose down || true

# Create logs directory
mkdir -p logs

# Build and start containers
echo 'Building and starting containers...'
docker-compose up -d --build

# Wait for services to start
echo 'Waiting for services to start...'
sleep 15

# Check container status
echo 'Container status:'
docker-compose ps

# Test health endpoint
echo 'Testing health endpoint...'
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo 'Health check passed!'
else
    echo 'Health check failed!'
    echo 'Backend logs:'
    docker logs daansetu-backend
    exit 1
fi

echo 'Deployment completed successfully!'
echo 'API available at: http://$EC2_IP/'
echo 'Documentation: http://$EC2_IP/api-docs'
"@

# Write deploy script to file
$deployScript | Out-File -FilePath "$deployDir/deploy.sh" -Encoding UTF8
aws s3 cp "$deployDir/deploy.sh" s3://$bucketName/deploy/

# Execute deployment on EC2
Write-Host "Executing deployment on EC2..." -ForegroundColor Blue
aws ssm send-command --instance-ids $InstanceId --document-name "AWS-RunShellScript" --parameters 'commands=["cd /tmp && aws s3 cp s3://'$bucketName'/deploy/deploy.sh . && chmod +x deploy.sh && ./deploy.sh"]' --output text --query 'Command.CommandId'

# Wait for command to complete
Write-Host "Waiting for deployment to complete..." -ForegroundColor Blue
Start-Sleep -Seconds 30

# Step 4: Test deployment
Write-Host "Testing deployment..." -ForegroundColor Blue
$healthUrl = "http://$EC2_IP/health"
$apiUrl = "http://$EC2_IP/"

try {
    $healthResponse = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 10
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "Health check passed!" -ForegroundColor Green
        Write-Host "   Response: $($healthResponse.Content)" -ForegroundColor White
    }
} catch {
    Write-Host "Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $apiResponse = Invoke-WebRequest -Uri $apiUrl -TimeoutSec 10
    if ($apiResponse.StatusCode -eq 200) {
        Write-Host "API endpoint working!" -ForegroundColor Green
        Write-Host "   Response: $($apiResponse.Content)" -ForegroundColor White
    }
} catch {
    Write-Host "API endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Cleanup
Write-Host "Cleaning up..." -ForegroundColor Blue
aws s3 rb s3://$bucketName --force
Remove-Item -Recurse -Force $deployDir

Write-Host ""
Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "Your API is now available at:" -ForegroundColor Blue
Write-Host "   Main API: http://$EC2_IP/" -ForegroundColor White
Write-Host "   Health: http://$EC2_IP/health" -ForegroundColor White
Write-Host "   Docs: http://$EC2_IP/api-docs" -ForegroundColor White
