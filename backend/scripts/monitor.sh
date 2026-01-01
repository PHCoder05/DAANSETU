#!/bin/bash

###############################################################################
# DAANSETU Monitoring Script
# Real-time monitoring of services
###############################################################################

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to get container stats
get_stats() {
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Function to check endpoint
check_endpoint() {
    local url=$1
    local response_time=$(curl -o /dev/null -s -w '%{time_total}' $url 2>/dev/null || echo "999")
    local ms=$(echo "$response_time * 1000" | bc)
    
    if (( $(echo "$response_time < 0.5" | bc -l) )); then
        echo -e "${GREEN}${ms%.*}ms${NC}"
    elif (( $(echo "$response_time < 1.0" | bc -l) )); then
        echo -e "${YELLOW}${ms%.*}ms${NC}"
    else
        echo -e "${RED}${ms%.*}ms${NC}"
    fi
}

# Clear screen and show header
clear
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    🖥️  DAANSETU REAL-TIME MONITOR${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Main monitoring loop
while true; do
    # System info
    echo -e "${YELLOW}📊 System Info:${NC}"
    echo "Date: $(date)"
    echo "Uptime: $(uptime -p)"
    echo ""
    
    # Docker containers
    echo -e "${YELLOW}🐳 Docker Containers:${NC}"
    get_stats
    echo ""
    
    # Service status
    echo -e "${YELLOW}🏥 Service Health:${NC}"
    printf "%-30s %s\n" "Main API:" "$(check_endpoint http://localhost/)"
    printf "%-30s %s\n" "Health Check:" "$(check_endpoint http://localhost/health)"
    printf "%-30s %s\n" "Swagger Docs:" "$(check_endpoint http://localhost/api-docs)"
    echo ""
    
    # Recent logs (last 5 lines)
    echo -e "${YELLOW}📝 Recent Logs:${NC}"
    docker-compose logs --tail=5 app 2>/dev/null || echo "No logs available"
    echo ""
    
    # Error count
    echo -e "${YELLOW}🔴 Recent Errors:${NC}"
    ERROR_COUNT=$(docker-compose logs app | grep -i error | tail -10 | wc -l)
    if [ $ERROR_COUNT -gt 0 ]; then
        echo -e "${RED}⚠️  $ERROR_COUNT errors in recent logs${NC}"
        docker-compose logs app | grep -i error | tail -5
    else
        echo -e "${GREEN}✅ No recent errors${NC}"
    fi
    echo ""
    
    # Footer
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo "Press Ctrl+C to exit | Refreshing in 10 seconds..."
    echo ""
    
    # Wait
    sleep 10
    
    # Clear for next iteration
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}    🖥️  DAANSETU REAL-TIME MONITOR${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
done

