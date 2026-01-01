#!/bin/bash

###############################################################################
# DAANSETU Backend - EC2 Deployment Fix Script
# This script fixes the nginx/backend port mismatch issue on EC2
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Banner
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🔧 EC2 DEPLOYMENT FIX SCRIPT 🔧    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    log_error "docker-compose.yml not found! Please run this script from your project root directory."
    exit 1
fi

log_info "Starting EC2 deployment fix..."

# Step 1: Check current status
log_info "📊 Checking current container status..."
docker ps -a
echo ""

# Step 2: Stop all containers
log_info "🛑 Stopping all containers..."
docker-compose down
log_success "Containers stopped"

# Step 3: Check if app.js has the correct port
log_info "🔍 Checking app.js port configuration..."
if grep -q "const PORT = process.env.PORT || 5000;" app.js; then
    log_success "app.js already configured for port 5000"
else
    log_warning "app.js needs to be updated for port 5000"
    log_info "Updating app.js..."
    sed -i 's/const PORT = process.env.PORT || 3000;/const PORT = process.env.PORT || 5000;/' app.js
    log_success "app.js updated"
fi

# Step 4: Clean up old images (optional)
log_info "🧹 Cleaning up old Docker images..."
docker system prune -f
log_success "Cleanup completed"

# Step 5: Rebuild and start containers
log_info "🏗️  Rebuilding containers with updated code..."
docker-compose up -d --build
log_success "Containers rebuilt and started"

# Step 6: Wait for health check
log_info "⏳ Waiting for services to be healthy..."
sleep 15

# Step 7: Check container status
log_info "📊 Checking container status..."
docker-compose ps
echo ""

# Step 8: Test API endpoints
log_info "🧪 Testing API endpoints..."

# Test health endpoint
if curl -f http://localhost/health > /dev/null 2>&1; then
    log_success "Health endpoint working"
    curl -s http://localhost/health | jq . 2>/dev/null || curl -s http://localhost/health
else
    log_error "Health endpoint failed"
fi

# Test main API
if curl -f http://localhost/ > /dev/null 2>&1; then
    log_success "Main API endpoint working"
    curl -s http://localhost/ | jq . 2>/dev/null || curl -s http://localhost/
else
    log_error "Main API endpoint failed"
fi

# Test API docs
if curl -f http://localhost/api-docs > /dev/null 2>&1; then
    log_success "API documentation accessible"
else
    log_error "API documentation failed"
fi

echo ""
log_info "📋 Container logs (last 10 lines):"
echo "--- Backend Logs ---"
docker logs daansetu-backend --tail 10
echo ""
echo "--- Nginx Logs ---"
docker logs daansetu-nginx --tail 10

echo ""
log_success "🎉 EC2 deployment fix completed!"
echo ""
log_info "🌐 Your API should now be accessible at:"
echo "   • Main API: http://your-ec2-ip/"
echo "   • Health Check: http://your-ec2-ip/health"
echo "   • API Docs: http://your-ec2-ip/api-docs"
echo ""
log_info "📊 To monitor logs: docker-compose logs -f"
log_info "🔄 To restart: docker-compose restart"
