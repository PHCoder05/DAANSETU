#!/bin/bash

###############################################################################
# DAANSETU Backend - One-Click Deployment Script
# This script automates the entire deployment process
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
echo -e "${GREEN}║   🚀 DAANSETU ONE-CLICK DEPLOY 🚀    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
log_info "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi
log_success "Docker found"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log_warning "docker-compose not found, checking for docker compose..."
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed."
        exit 1
    fi
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi
log_success "Docker Compose found"

# Check if .env exists
if [ ! -f .env ]; then
    log_error ".env file not found!"
    log_info "Creating .env from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        log_warning "Please update .env with your actual values before deploying!"
        exit 1
    else
        log_error ".env.example not found. Cannot proceed."
        exit 1
    fi
fi
log_success ".env file found"

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Menu
echo ""
log_info "Select deployment option:"
echo "1) 🐳 Local Docker (Development)"
echo "2) 🏗️  Build & Test Docker Image"
echo "3) 🚀 Deploy to AWS (Production)"
echo "4) 🧹 Cleanup Docker Resources"
echo "5) 📊 View Logs"
echo "6) 🔄 Restart Services"
echo "7) 🛑 Stop Services"
echo "8) ❌ Exit"
echo ""
read -p "Enter choice [1-8]: " choice

case $choice in
    1)
        log_info "🐳 Starting local Docker deployment..."
        
        # Build image
        log_info "Building Docker image..."
        docker build -t daansetu-backend:latest .
        log_success "Docker image built"
        
        # Start services
        log_info "Starting services with Docker Compose..."
        $DOCKER_COMPOSE up -d
        
        # Wait for health check
        log_info "Waiting for services to be healthy..."
        sleep 10
        
        # Health check
        if curl -f http://localhost/health > /dev/null 2>&1; then
            log_success "Services are running and healthy!"
            echo ""
            log_success "🌐 API: http://localhost"
            log_success "📖 Swagger: http://localhost/api-docs"
            log_success "🏥 Health: http://localhost/health"
            echo ""
            log_info "View logs: docker-compose logs -f"
        else
            log_error "Health check failed!"
            log_info "Check logs: docker-compose logs"
            exit 1
        fi
        ;;
    
    2)
        log_info "🏗️  Building and testing Docker image..."
        
        # Build
        docker build -t daansetu-backend:test .
        log_success "Image built"
        
        # Test run
        log_info "Testing container..."
        docker run -d --name daansetu-test -p 5001:5000 \
            -e MONGODB_URI="$MONGODB_URI" \
            -e JWT_SECRET="test-secret" \
            daansetu-backend:test
        
        sleep 5
        
        # Health check
        if curl -f http://localhost:5001/health > /dev/null 2>&1; then
            log_success "Container test passed!"
        else
            log_error "Container test failed!"
            docker logs daansetu-test
        fi
        
        # Cleanup
        docker stop daansetu-test
        docker rm daansetu-test
        ;;
    
    3)
        log_info "🚀 Deploying to AWS..."
        
        # Check Terraform
        if ! command -v terraform &> /dev/null; then
            log_error "Terraform is not installed!"
            exit 1
        fi
        
        # Check AWS CLI
        if ! command -v aws &> /dev/null; then
            log_error "AWS CLI is not installed!"
            exit 1
        fi
        
        # Terraform deployment
        cd terraform
        
        log_info "Initializing Terraform..."
        terraform init
        
        log_info "Planning infrastructure..."
        terraform plan -out=tfplan
        
        read -p "Apply this plan? (yes/no): " confirm
        if [ "$confirm" == "yes" ]; then
            log_info "Applying Terraform changes..."
            terraform apply tfplan
            
            log_success "Infrastructure deployed!"
            
            # Get EC2 IP
            EC2_IP=$(terraform output -raw ec2_public_ip)
            log_success "EC2 Instance: $EC2_IP"
            log_success "API URL: http://$EC2_IP"
            log_success "Swagger: http://$EC2_IP/api-docs"
        else
            log_warning "Deployment cancelled"
        fi
        
        cd ..
        ;;
    
    4)
        log_info "🧹 Cleaning up Docker resources..."
        docker system prune -a -f --volumes
        log_success "Cleanup completed"
        ;;
    
    5)
        log_info "📊 Viewing logs..."
        $DOCKER_COMPOSE logs -f
        ;;
    
    6)
        log_info "🔄 Restarting services..."
        $DOCKER_COMPOSE restart
        log_success "Services restarted"
        ;;
    
    7)
        log_info "🛑 Stopping services..."
        $DOCKER_COMPOSE down
        log_success "Services stopped"
        ;;
    
    8)
        log_info "Exiting..."
        exit 0
        ;;
    
    *)
        log_error "Invalid choice!"
        exit 1
        ;;
esac

echo ""
log_success "🎉 Operation completed successfully!"
echo ""

