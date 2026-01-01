#!/bin/bash

###############################################################################
# DAANSETU Rollback Script
# Rolls back to previous version
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 DAANSETU Rollback Script${NC}"
echo ""

# List available backup tags
echo "Available backup versions:"
docker images daansetu-backend --format "{{.Tag}}" | grep backup | nl

echo ""
read -p "Enter backup number to rollback to (or 'cancel'): " choice

if [ "$choice" == "cancel" ]; then
    echo "Rollback cancelled"
    exit 0
fi

# Get selected backup
BACKUP_TAG=$(docker images daansetu-backend --format "{{.Tag}}" | grep backup | sed -n "${choice}p")

if [ -z "$BACKUP_TAG" ]; then
    echo -e "${RED}❌ Invalid selection${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Rolling back to: $BACKUP_TAG${NC}"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Rollback cancelled"
    exit 0
fi

# Tag backup as latest
docker tag daansetu-backend:$BACKUP_TAG daansetu-backend:latest

# Restart services
echo -e "${BLUE}🔄 Restarting services...${NC}"
docker-compose up -d

# Wait for services
sleep 10

# Health check
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo ""
    echo -e "${GREEN}✅ Rollback successful!${NC}"
    echo "Current version: $BACKUP_TAG"
else
    echo -e "${RED}❌ Rollback failed health check!${NC}"
    exit 1
fi

