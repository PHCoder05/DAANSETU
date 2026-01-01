#!/bin/bash

###############################################################################
# MongoDB Backup Script for DAANSETU
# Backs up MongoDB database to local storage and optionally to S3
###############################################################################

set -e

# Configuration
BACKUP_DIR="/opt/daansetu-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="daansetu_backup_$DATE"
RETENTION_DAYS=7

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🗄️  Starting MongoDB backup...${NC}"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${YELLOW}⚠️  .env file not found, using environment variables${NC}"
fi

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup MongoDB
echo -e "${BLUE}📦 Creating backup...${NC}"

# Using mongodump (requires MongoDB tools)
if command -v mongodump &> /dev/null; then
    mongodump --uri="$MONGODB_URI" --out="$BACKUP_DIR/$BACKUP_NAME"
else
    echo -e "${YELLOW}⚠️  mongodump not found, using alternative method${NC}"
    
    # Alternative: Use MongoDB container
    docker run --rm \
        -v $BACKUP_DIR:/backup \
        mongo:6 \
        mongodump --uri="$MONGODB_URI" --out="/backup/$BACKUP_NAME"
fi

# Compress backup
echo -e "${BLUE}🗜️  Compressing backup...${NC}"
cd $BACKUP_DIR
tar -czf "${BACKUP_NAME}.tar.gz" $BACKUP_NAME
rm -rf $BACKUP_NAME

# Calculate size
BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${GREEN}✅ Backup created: ${BACKUP_NAME}.tar.gz ($BACKUP_SIZE)${NC}"

# Upload to S3 (optional)
if [ ! -z "$AWS_S3_BACKUP_BUCKET" ]; then
    echo -e "${BLUE}☁️  Uploading to S3...${NC}"
    aws s3 cp "${BACKUP_NAME}.tar.gz" "s3://$AWS_S3_BACKUP_BUCKET/backups/"
    echo -e "${GREEN}✅ Uploaded to S3${NC}"
fi

# Clean old backups
echo -e "${BLUE}🧹 Cleaning old backups...${NC}"
find $BACKUP_DIR -name "daansetu_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
DELETED_COUNT=$(find $BACKUP_DIR -name "daansetu_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS | wc -l)
echo -e "${GREEN}✅ Deleted $DELETED_COUNT old backups (older than $RETENTION_DAYS days)${NC}"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Backup completed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Backup: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo "Size: $BACKUP_SIZE"
echo "Date: $(date)"
echo ""

# To restore:
echo -e "${YELLOW}💡 To restore this backup:${NC}"
echo "   tar -xzf ${BACKUP_NAME}.tar.gz"
echo "   mongorestore --uri=\"\$MONGODB_URI\" $BACKUP_NAME/"
echo ""

