# DAANSETU - Deploy to EC2 Script (Windows)

$EC2_IP = "54.209.219.220"
$SSH_KEY = "$env:USERPROFILE\.ssh\daansetu-ec2-key"
$DEPLOY_PATH = "/opt/daansetu-backend"

Write-Host "`n🚀 Deploying DAANSETU to AWS EC2...`n" -ForegroundColor Green

# Step 1: Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
$tempZip = "$env:TEMP\daansetu-deploy.zip"

# Compress current directory (excluding node_modules, logs, etc.)
Compress-Archive -Path @(
    "app.js",
    "config",
    "controllers",
    "models",
    "routes",
    "middleware",
    "utils",
    "package.json",
    "package-lock.json",
    "Dockerfile",
    "docker-compose.yml",
    "nginx"
) -DestinationPath $tempZip -Force

Write-Host "✅ Package created`n" -ForegroundColor Green

# Step 2: Upload to EC2
Write-Host "📤 Uploading to EC2..." -ForegroundColor Yellow
scp -i $SSH_KEY -o StrictHostKeyChecking=no $tempZip ubuntu@${EC2_IP}:/tmp/daansetu-deploy.zip

# Step 3: Extract and deploy on EC2
Write-Host "🔧 Deploying on EC2..." -ForegroundColor Yellow

$deployScript = @'
cd /opt/daansetu-backend
sudo unzip -o /tmp/daansetu-deploy.zip
sudo chown -R ubuntu:ubuntu /opt/daansetu-backend

# Create .env file
cat > .env << 'EOF'
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
EOF

# Start services
docker-compose up -d

# Wait and check health
sleep 10
curl http://localhost/health
'@

ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$EC2_IP $deployScript

Write-Host "`n✅ Deployment complete!`n" -ForegroundColor Green

# Step 4: Test
Write-Host "🏥 Testing API..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
$response = Invoke-WebRequest -Uri "http://$EC2_IP/health" -UseBasicParsing -ErrorAction SilentlyContinue

if ($response.StatusCode -eq 200) {
    Write-Host "✅ API is live and healthy!`n" -ForegroundColor Green
    Write-Host "🌐 Access your API at:" -ForegroundColor Cyan
    Write-Host "   http://$EC2_IP/api-docs`n" -ForegroundColor White
} else {
    Write-Host "⏳ Still initializing... Check in a few minutes`n" -ForegroundColor Yellow
}

# Cleanup
Remove-Item $tempZip -Force

Write-Host "Deploy complete!`n" -ForegroundColor Cyan

