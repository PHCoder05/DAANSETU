#!/bin/bash

###############################################################################
# Health Check Script
# Monitors all services and sends alerts if something is down
###############################################################################

set -e

# Configuration
API_URL="${API_URL:-http://localhost}"
ALERT_EMAIL="${ALERT_EMAIL:-admin@daansetu.org}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check counter
CHECKS_PASSED=0
CHECKS_FAILED=0

# Function to check service
check_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Checking $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" $url || echo "000")
    
    if [ "$response" == "$expected_code" ]; then
        echo -e "${GREEN}✅ OK${NC} (HTTP $response)"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC} (HTTP $response, expected $expected_code)"
        ((CHECKS_FAILED++))
        return 1
    fi
}

# Function to check Docker container
check_container() {
    local name=$1
    
    echo -n "Checking Docker container $name... "
    
    if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
        echo -e "${GREEN}✅ Running${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ Not running${NC}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

# Function to check disk space
check_disk() {
    echo -n "Checking disk space... "
    
    usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ $usage -lt 80 ]; then
        echo -e "${GREEN}✅ OK${NC} (${usage}% used)"
        ((CHECKS_PASSED++))
    elif [ $usage -lt 90 ]; then
        echo -e "${YELLOW}⚠️  WARNING${NC} (${usage}% used)"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ CRITICAL${NC} (${usage}% used)"
        ((CHECKS_FAILED++))
    fi
}

# Function to check memory
check_memory() {
    echo -n "Checking memory... "
    
    usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    
    if [ $usage -lt 80 ]; then
        echo -e "${GREEN}✅ OK${NC} (${usage}% used)"
        ((CHECKS_PASSED++))
    elif [ $usage -lt 90 ]; then
        echo -e "${YELLOW}⚠️  WARNING${NC} (${usage}% used)"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ CRITICAL${NC} (${usage}% used)"
        ((CHECKS_FAILED++))
    fi
}

# Function to send alert
send_alert() {
    local message=$1
    
    # Email alert
    if [ ! -z "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "DAANSETU Health Alert" $ALERT_EMAIL 2>/dev/null || true
    fi
    
    # Slack alert
    if [ ! -z "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 DAANSETU Alert: $message\"}" \
            $SLACK_WEBHOOK 2>/dev/null || true
    fi
}

# Start health checks
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}🏥 DAANSETU Health Check${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

# Check system resources
echo -e "${YELLOW}📊 System Resources:${NC}"
check_disk
check_memory
echo ""

# Check Docker containers
echo -e "${YELLOW}🐳 Docker Containers:${NC}"
check_container "daansetu-backend"
check_container "daansetu-nginx"
echo ""

# Check API endpoints
echo -e "${YELLOW}🌐 API Endpoints:${NC}"
check_service "Main Server" "$API_URL/"
check_service "Health Endpoint" "$API_URL/health"
check_service "Swagger Docs" "$API_URL/api-docs"
check_service "Auth Endpoint" "$API_URL/api/setup/check"
echo ""

# Check Nginx
echo -e "${YELLOW}🌐 Nginx:${NC}"
if sudo systemctl is-active --quiet nginx; then
    echo -e "Nginx service: ${GREEN}✅ Running${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "Nginx service: ${RED}❌ Stopped${NC}"
    ((CHECKS_FAILED++))
fi
echo ""

# Check MongoDB connection
echo -e "${YELLOW}🗄️  Database:${NC}"
echo -n "MongoDB connection... "
response=$(curl -s -X POST "$API_URL/api/setup/check" || echo "failed")
if [ "$response" != "failed" ]; then
    echo -e "${GREEN}✅ Connected${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ Failed${NC}"
    ((CHECKS_FAILED++))
fi
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}📊 Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Checks passed: ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Checks failed: ${RED}$CHECKS_FAILED${NC}"
echo ""

# Overall status
if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! System is healthy.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some checks failed! Please investigate.${NC}"
    send_alert "Health check failed: $CHECKS_FAILED checks failed, $CHECKS_PASSED passed"
    exit 1
fi

