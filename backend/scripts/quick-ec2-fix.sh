#!/bin/bash

# Quick EC2 Fix - Run these commands on your EC2 instance

echo "🔧 Quick EC2 Deployment Fix"
echo "=========================="

# 1. Stop containers
echo "🛑 Stopping containers..."
docker-compose down

# 2. Update app.js port (if not already updated)
echo "🔧 Updating app.js port configuration..."
sed -i 's/const PORT = process.env.PORT || 3000;/const PORT = process.env.PORT || 5000;/' app.js

# 3. Rebuild and start
echo "🏗️  Rebuilding and starting containers..."
docker-compose up -d --build

# 4. Wait and test
echo "⏳ Waiting for services..."
sleep 10

echo "🧪 Testing API..."
curl http://localhost/health
echo ""
curl http://localhost/
echo ""

echo "✅ Fix completed! Check your EC2 IP now."
