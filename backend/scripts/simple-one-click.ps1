# DAANSETU Backend - Simple One-Click Deployment
param(
    [string]$GitHubRepo = "https://github.com/PHCoder05/DAANSETU_BACKEND_OPS.git",
    [string]$Branch = "main"
)

Write-Host "DAANSETU One-Click Deployment" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Blue

$Prerequisites = @{
    "Git" = (Get-Command git -ErrorAction SilentlyContinue) -ne $null
    "AWS CLI" = (Get-Command aws -ErrorAction SilentlyContinue) -ne $null
    "Terraform" = (Get-Command terraform -ErrorAction SilentlyContinue) -ne $null
    "Docker" = (Get-Command docker -ErrorAction SilentlyContinue) -ne $null
}

$MissingPrerequisites = @()
foreach ($prereq in $Prerequisites.GetEnumerator()) {
    if ($prereq.Value) {
        Write-Host "  OK: $($prereq.Key)" -ForegroundColor Green
    } else {
        Write-Host "  MISSING: $($prereq.Key)" -ForegroundColor Red
        $MissingPrerequisites += $prereq.Key
    }
}

if ($MissingPrerequisites.Count -gt 0) {
    Write-Host "Missing prerequisites: $($MissingPrerequisites -join ', ')" -ForegroundColor Red
    Write-Host "Please install the missing tools and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "All prerequisites met!" -ForegroundColor Green
Write-Host ""

# Step 1: Push to GitHub
Write-Host "Pushing to GitHub..." -ForegroundColor Blue
git add .
git commit -m "Automated deployment - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git push origin $Branch
Write-Host "Code pushed to GitHub successfully" -ForegroundColor Green

# Step 2: Run Terraform
Write-Host "Running Terraform..." -ForegroundColor Blue
Set-Location terraform
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Get Terraform outputs
$TerraformOutputs = terraform output -json | ConvertFrom-Json
$EC2InstanceId = $TerraformOutputs.ec2_instance_id.value
$EC2PublicIP = $TerraformOutputs.ec2_public_ip.value
$APIUrl = $TerraformOutputs.api_url.value

Write-Host "Infrastructure deployed successfully" -ForegroundColor Green
Write-Host "Instance ID: $EC2InstanceId" -ForegroundColor White
Write-Host "Public IP: $EC2PublicIP" -ForegroundColor White
Write-Host "API URL: $APIUrl" -ForegroundColor White

Set-Location ..

# Step 3: Deploy application
Write-Host "Deploying application..." -ForegroundColor Blue

# Create deployment package
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
        Write-Host "  Copied: $file" -ForegroundColor Green
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

# Deploy to EC2 using S3
Write-Host "Uploading to EC2..." -ForegroundColor Blue
$BucketName = "daansetu-deploy-$(Get-Random)"
aws s3 mb s3://$BucketName
aws s3 sync $DeployDir/ s3://$BucketName/deploy/

# Execute deployment on EC2
$CommandId = aws ssm send-command --instance-ids $EC2InstanceId --document-name "AWS-RunShellScript" --parameters "commands=[`"cd /tmp && aws s3 sync s3://$BucketName/deploy/ /opt/daansetu-backend/ && cd /opt/daansetu-backend && docker-compose up -d --build`"]" --output text --query 'Command.CommandId'

Write-Host "Deployment command sent: $CommandId" -ForegroundColor Yellow
Write-Host "Waiting for deployment to complete..." -ForegroundColor Yellow

# Wait for deployment
Start-Sleep -Seconds 60

# Cleanup S3 bucket
aws s3 rb s3://$BucketName --force

# Cleanup local files
Remove-Item -Recurse -Force $DeployDir

# Step 4: Test deployment
Write-Host "Testing deployment..." -ForegroundColor Blue

$Endpoints = @(
    @{Url = "http://$EC2PublicIP/"; Name = "Main API"},
    @{Url = "http://$EC2PublicIP/health"; Name = "Health Check"},
    @{Url = "http://$EC2PublicIP/api-docs"; Name = "API Documentation"}
)

foreach ($endpoint in $Endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint.Url -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "  OK: $($endpoint.Name)" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: $($endpoint.Name) - Status $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  FAILED: $($endpoint.Name)" -ForegroundColor Red
    }
}

# Final summary
Write-Host ""
Write-Host "Deployment Summary:" -ForegroundColor Blue
Write-Host "  Repository: $GitHubRepo" -ForegroundColor White
Write-Host "  Branch: $Branch" -ForegroundColor White
Write-Host "  EC2 Instance: $EC2InstanceId" -ForegroundColor White
Write-Host "  Public IP: $EC2PublicIP" -ForegroundColor White
Write-Host "  API URL: $APIUrl" -ForegroundColor White

Write-Host ""
Write-Host "Your API is now live at:" -ForegroundColor Green
Write-Host "  Main API: http://$EC2PublicIP/" -ForegroundColor Cyan
Write-Host "  Health Check: http://$EC2PublicIP/health" -ForegroundColor Cyan
Write-Host "  Documentation: http://$EC2PublicIP/api-docs" -ForegroundColor Cyan

Write-Host ""
Write-Host "One-click deployment completed successfully!" -ForegroundColor Green
