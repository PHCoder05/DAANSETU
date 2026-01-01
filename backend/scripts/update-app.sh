#!/bin/bash

###############################################################################
# DAANSETU Application Update Script
# Updates the application with zero downtime
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔄 Starting application update...${NC}"

# Pull latest changes
echo -e "${BLUE}📥 Pulling latest code...${NC}"
git pull origin main

# Backup current version
echo -e "${BLUE}💾 Creating backup...${NC}"
BACKUP_TAG="backup-$(date +%Y%m%d_%H%M%S)"
docker tag daansetu-backend:latest daansetu-backend:$BACKUP_TAG
echo -e "${GREEN}✅ Backup tagged as: $BACKUP_TAG${NC}"

# Build new image
echo -e "${BLUE}🐳 Building new Docker image...${NC}"
docker-compose build --no-cache

# Pull latest images
echo -e "${BLUE}📥 Pulling latest images...${NC}"
docker-compose pull

# Update services with zero downtime
echo -e "${BLUE}🚀 Updating services (zero downtime)...${NC}"

# Scale up new instance
docker-compose up -d --scale app=2 --no-recreate

# Wait for new instance to be healthy
echo -e "${BLUE}⏳ Waiting for new instance to be healthy...${NC}"
sleep 15

# Check health
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ New instance is healthy${NC}"
    
    # Remove old instance
    docker-compose up -d --scale app=1 --no-recreate
    
    echo -e "${GREEN}✅ Old instance removed${NC}"
else
    echo -e "${YELLOW}⚠️  Health check failed, rolling back...${NC}"
    
    # Rollback
    docker tag daansetu-backend:$BACKUP_TAG daansetu-backend:latest
    docker-compose up -d
    
    echo -e "${YELLOW}⚠️  Rolled back to previous version${NC}"
    exit 1
fi

# Reload Nginx
echo -e "${BLUE}🌐 Reloading Nginx...${NC}"
docker-compose exec nginx nginx -s reload

# Cleanup old images
echo -e "${BLUE}🧹 Cleaning up old images...${NC}"
docker image prune -f

# Final health check
sleep 5
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}🎉 Update completed successfully!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    echo "Version: $(git rev-parse --short HEAD)"
    echo "Date: $(date)"
    echo "Backup: $BACKUP_TAG"
    echo ""
else
    echo -e "${YELLOW}⚠️  Update completed but health check failed${NC}"
    exit 1
fi

