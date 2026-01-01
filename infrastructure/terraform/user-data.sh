#!/bin/bash
set -e

# Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose
echo "📦 Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Nginx
echo "🌐 Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx

# Install Git
apt-get install -y git

# Install Node.js (for running scripts if needed)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Create deployment directory
echo "📁 Creating deployment directory..."
mkdir -p ${deploy_path}
chown -R ubuntu:ubuntu ${deploy_path}

# Clone repository (you'll need to add deploy key)
# cd ${deploy_path}
# git clone your-repo-url .

# Create .env file
cat > ${deploy_path}/.env << 'ENVEOF'
MONGODB_URI=${mongodb_uri}
DB_NAME=daansetu
PORT=${app_port}
NODE_ENV=production
JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
ADMIN_SETUP_KEY=${admin_setup_key}
CORS_ORIGIN=${cors_origin}
ENVEOF

# Set up log rotation
cat > /etc/logrotate.d/daansetu << EOF
${deploy_path}/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0644 ubuntu ubuntu
    sharedscripts
}
EOF

# Install CloudWatch agent (optional)
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
# dpkg -i -E ./amazon-cloudwatch-agent.deb

# Start services
echo "🚀 Starting services..."
cd ${deploy_path}
# docker-compose up -d

echo "✅ User data script completed!"
echo "🎉 Server setup complete!"

