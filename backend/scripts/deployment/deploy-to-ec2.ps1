# Deploy DAANSETU Backend to EC2 Instance
param(
    [string]$EC2IP = "3.110.37.146"
)

Write-Host "🚀 Deploying DAANSETU Backend to EC2..." -ForegroundColor Green
Write-Host "📍 Target EC2: $EC2IP" -ForegroundColor Cyan

# Create deployment script for EC2
$deployScript = @"
#!/bin/bash
set -e

echo "🚀 Starting DAANSETU Backend deployment..."

# Update system
echo "📦 Updating system packages..."
sudo apt-get update -y

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    sudo apt-get install -y docker.io docker-compose
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu
fi

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/daansetu-backend
cd /opt/daansetu-backend

# Clone repository
echo "📥 Cloning repository..."
sudo rm -rf * .* 2>/dev/null || true
sudo git clone https://github.com/PHCoder05/DAANSETU_BACKEND_OPS.git .

# Create .env file
echo "⚙️ Creating environment file..."
sudo tee .env > /dev/null << 'EOF'
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

# Set permissions
echo "🔐 Setting permissions..."
sudo chown -R ubuntu:ubuntu /opt/daansetu-backend

# Stop existing containers
echo "🛑 Stopping existing containers..."
sudo docker-compose down 2>/dev/null || true

# Build and start containers
echo "🐳 Building and starting containers..."
sudo docker-compose up -d --build

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 15

# Check container status
echo "📊 Container status:"
sudo docker-compose ps

# Test endpoints
echo "🧪 Testing endpoints..."
echo "Testing main API..."
curl -f http://localhost/ || echo "Main API not responding"
echo "Testing health check..."
curl -f http://localhost/health || echo "Health check not responding"
echo "Testing API docs..."
curl -f http://localhost/api-docs || echo "API docs not responding"

echo "✅ Deployment completed!"
echo "🌐 Your API is now live at: http://$EC2IP/"
echo "📚 API Documentation: http://$EC2IP/api-docs"
echo "🏥 Health Check: http://$EC2IP/health"
"@

# Save deployment script
$deployScript | Out-File -FilePath "deployment-commands.sh" -Encoding UTF8

Write-Host "📝 Deployment script created: deployment-commands.sh" -ForegroundColor Green
Write-Host ""
Write-Host "🔧 To deploy to EC2, copy and run these commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Copy the deployment-commands.sh file to EC2:" -ForegroundColor White
Write-Host "   scp deployment-commands.sh ubuntu@$EC2IP:/tmp/" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. SSH into EC2 and run the script:" -ForegroundColor White
Write-Host "   ssh ubuntu@$EC2IP" -ForegroundColor Yellow
Write-Host "   chmod +x /tmp/deployment-commands.sh" -ForegroundColor Yellow
Write-Host "   /tmp/deployment-commands.sh" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Or use EC2 Instance Connect in AWS Console:" -ForegroundColor White
Write-Host "   - Go to EC2 Console" -ForegroundColor Gray
Write-Host "   - Select instance $EC2IP" -ForegroundColor Gray
Write-Host "   - Click 'Connect' → 'EC2 Instance Connect'" -ForegroundColor Gray
Write-Host "   - Copy and paste the commands from deployment-commands.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 After deployment, your API will be available at:" -ForegroundColor Green
Write-Host "   http://$EC2IP/" -ForegroundColor Cyan
Write-Host "   http://$EC2IP/api-docs" -ForegroundColor Cyan
Write-Host "   http://$EC2IP/health" -ForegroundColor Cyan
