#!/bin/bash

###############################################################################
# DAANSETU Production Setup Script
# This script sets up the EC2 instance for production deployment
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════╗
║   🚀 DAANSETU PRODUCTION SETUP 🚀        ║
╚═══════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ Don't run this as root!${NC}"
   exit 1
fi

# Update system
echo -e "${BLUE}📦 Updating system...${NC}"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl git wget unzip

# Install Docker
echo -e "${BLUE}🐳 Installing Docker...${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Docker Compose
echo -e "${BLUE}📦 Installing Docker Compose...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Nginx
echo -e "${BLUE}🌐 Installing Nginx...${NC}"
sudo apt-get install -y nginx
sudo systemctl enable nginx

# Install Certbot for SSL
echo -e "${BLUE}🔒 Installing Certbot...${NC}"
sudo apt-get install -y certbot python3-certbot-nginx

# Create application directory
echo -e "${BLUE}📁 Creating application directory...${NC}"
sudo mkdir -p /opt/daansetu-backend
sudo chown $USER:$USER /opt/daansetu-backend
cd /opt/daansetu-backend

# Clone repository
echo -e "${BLUE}📥 Cloning repository...${NC}"
read -p "Enter GitHub repository URL: " REPO_URL
git clone $REPO_URL .

# Setup environment variables
echo -e "${BLUE}⚙️  Setting up environment variables...${NC}"
cp .env.example .env

echo ""
echo -e "${YELLOW}📝 Please update the .env file with production values:${NC}"
echo "   - MongoDB URI"
echo "   - JWT Secrets"
echo "   - Admin Setup Key"
echo "   - CORS Origin"
echo ""
read -p "Press Enter when done editing .env..."
nano .env

# Create log directories
mkdir -p logs nginx/logs nginx/ssl

# Set up firewall
echo -e "${BLUE}🔥 Configuring firewall...${NC}"
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Configure Nginx
echo -e "${BLUE}🌐 Configuring Nginx...${NC}"
sudo cp nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp nginx/conf.d/daansetu.conf /etc/nginx/sites-available/daansetu
sudo ln -sf /etc/nginx/sites-available/daansetu /etc/nginx/sites-enabled/daansetu
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx config
sudo nginx -t

# Start services
echo -e "${BLUE}🚀 Starting services...${NC}"
docker-compose up -d

# Wait for services
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 15

# Reload Nginx
sudo systemctl reload nginx

# Health check
echo -e "${BLUE}🏥 Running health check...${NC}"
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Health check passed!${NC}"
else
    echo -e "${RED}❌ Health check failed!${NC}"
    echo "Check logs: docker-compose logs"
    exit 1
fi

# Setup SSL (optional)
echo ""
read -p "Do you want to setup SSL with Let's Encrypt? (y/n): " setup_ssl

if [ "$setup_ssl" == "y" ]; then
    read -p "Enter your domain name (e.g., api.daansetu.org): " DOMAIN
    sudo certbot --nginx -d $DOMAIN
    
    # Auto-renewal test
    sudo certbot renew --dry-run
    
    echo -e "${GREEN}✅ SSL certificate installed!${NC}"
    echo -e "${GREEN}🔒 Your API is now available at: https://$DOMAIN${NC}"
fi

# Setup log rotation
echo -e "${BLUE}📝 Setting up log rotation...${NC}"
sudo tee /etc/logrotate.d/daansetu > /dev/null << EOF
/opt/daansetu-backend/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
    sharedscripts
    postrotate
        docker-compose -f /opt/daansetu-backend/docker-compose.yml exec app kill -USR1 1
    endscript
}
EOF

# Setup cron for cleanup
echo -e "${BLUE}🧹 Setting up cleanup job...${NC}"
(crontab -l 2>/dev/null; echo "0 2 * * * cd /opt/daansetu-backend && docker system prune -f >> /var/log/docker-cleanup.log 2>&1") | crontab -

# Setup automatic updates (optional)
read -p "Enable automatic security updates? (y/n): " auto_update
if [ "$auto_update" == "y" ]; then
    sudo apt-get install -y unattended-upgrades
    sudo dpkg-reconfigure -plow unattended-upgrades
fi

# Final summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Production Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📊 Your API is running at:${NC}"
echo "   • Health: http://$(curl -s ifconfig.me)/health"
echo "   • Swagger: http://$(curl -s ifconfig.me)/api-docs"
if [ "$setup_ssl" == "y" ]; then
    echo "   • HTTPS: https://$DOMAIN"
fi
echo ""
echo -e "${YELLOW}🔧 Useful commands:${NC}"
echo "   • View logs: docker-compose logs -f"
echo "   • Restart: docker-compose restart"
echo "   • Stop: docker-compose down"
echo "   • Update: git pull && docker-compose up -d --build"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "   1. Test API endpoints"
echo "   2. Create first admin account"
echo "   3. Configure monitoring"
echo "   4. Setup backups"
echo "   5. Configure DNS"
echo ""
echo -e "${GREEN}✨ Your DAANSETU backend is live!${NC}"
echo ""

