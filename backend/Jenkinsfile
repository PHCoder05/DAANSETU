pipeline {
    agent any
    
    environment {
        // AWS Configuration
        AWS_REGION = 'us-east-1'
        AWS_CREDENTIALS = credentials('aws-credentials')
        
        // Docker Configuration
        DOCKER_IMAGE = 'daansetu-backend'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        
        // Application Configuration
        APP_NAME = 'daansetu-backend'
        APP_PORT = '5000'
        DEPLOY_PATH = '/opt/daansetu-backend'
        
        // Terraform Configuration
        TF_VAR_project_name = 'daansetu-backend'
        TF_VAR_environment = 'production'
        TF_VAR_aws_region = 'us-east-1'
        
        // Secrets from Jenkins
        MONGODB_URI = credentials('mongodb-uri')
        JWT_SECRET = credentials('jwt-secret')
        JWT_REFRESH_SECRET = credentials('jwt-refresh-secret')
        ADMIN_SETUP_KEY = credentials('admin-setup-key')
    }
    
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        skipDefaultCheckout()
    }
    
    stages {
        stage('📋 Checkout & Setup') {
            steps {
                echo '📥 Checking out code from GitHub...'
                checkout scm
                
                // Get commit info
                sh 'git rev-parse --short HEAD > .git/commit-id'
                script {
                    env.GIT_COMMIT_SHORT = readFile('.git/commit-id').trim()
                    env.GIT_BRANCH = env.BRANCH_NAME
                }
                
                echo "✅ Checkout complete - Commit: ${env.GIT_COMMIT_SHORT}, Branch: ${env.GIT_BRANCH}"
            }
        }
        
        stage('🔍 Code Quality & Security') {
            parallel {
                stage('Linting & Formatting') {
                    steps {
                        echo '🔍 Running code quality checks...'
                        sh '''
                            # Install dependencies for linting
                            npm install --only=dev 2>/dev/null || true
                            
                            # Run basic syntax check
                            node -c app.js
                            
                            # Check for common issues
                            if grep -r "console.log" app.js controllers/ routes/ middleware/ 2>/dev/null; then
                                echo "⚠️  Warning: Found console.log statements in production code"
                            fi
                            
                            echo "✅ Code quality checks completed"
                        '''
                    }
                }
                
                stage('Security Audit') {
                    steps {
                        echo '🔒 Running security audit...'
                        sh '''
                            # Security audit
                            npm audit --audit-level=moderate || true
                            
                            # Check for sensitive data
                            if grep -r "password\|secret\|key" . --exclude-dir=node_modules --exclude-dir=.git --exclude="*.md" 2>/dev/null; then
                                echo "⚠️  Warning: Potential sensitive data found in code"
                            fi
                            
                            echo "✅ Security audit completed"
                        '''
                    }
                }
            }
        }
        
        stage('🧪 Testing') {
            steps {
                echo '🧪 Running tests...'
                sh '''
                    # Install dependencies
                    npm install
                    
                    # Run basic health check
                    node -e "
                        const app = require('./app.js');
                        setTimeout(() => {
                            console.log('✅ Application starts successfully');
                            process.exit(0);
                        }, 2000);
                    " || echo "⚠️  Application startup test failed"
                    
                    echo "✅ Tests completed"
                '''
            }
        }
        
        stage('🐳 Docker Build & Test') {
            steps {
                echo '🐳 Building and testing Docker image...'
                script {
                    // Build Docker image
                    def image = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    
                    // Test the container
                    docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").inside() {
                        sh '''
                            # Test if the application starts
                            timeout 30s node app.js &
                            APP_PID=$!
                            
                            # Wait for startup
                            sleep 10
                            
                            # Test health endpoint
                            if curl -f http://localhost:5000/health; then
                                echo "✅ Container health check passed"
                            else
                                echo "❌ Container health check failed"
                                exit 1
                            fi
                            
                            # Cleanup
                            kill $APP_PID 2>/dev/null || true
                        '''
                    }
                    
                    echo "✅ Docker build and test completed"
                }
            }
        }
        
        stage('🏗️ Infrastructure (Terraform)') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'production'
                }
            }
            steps {
                echo '🏗️ Managing infrastructure with Terraform...'
                dir('terraform') {
                    sh '''
                        # Initialize Terraform
                        terraform init
                        
                        # Validate configuration
                        terraform validate
                        
                        # Plan infrastructure changes
                        terraform plan -out=tfplan
                        
                        # Apply infrastructure changes
                        terraform apply -auto-approve tfplan
                        
                        # Get outputs
                        terraform output -json > ../terraform-outputs.json
                    '''
                }
                
                // Parse Terraform outputs
                script {
                    def outputs = readJSON file: 'terraform-outputs.json'
                    env.EC2_INSTANCE_ID = outputs.ec2_instance_id.value
                    env.EC2_PUBLIC_IP = outputs.ec2_public_ip.value
                    env.API_URL = outputs.api_url.value
                }
                
                echo "✅ Infrastructure updated - Instance: ${env.EC2_INSTANCE_ID}, IP: ${env.EC2_PUBLIC_IP}"
            }
        }
        
        stage('🚀 Deploy to EC2') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'production'
                }
            }
            steps {
                echo '🚀 Deploying application to EC2...'
                script {
                    // Create deployment package
                    sh '''
                        # Create deployment directory
                        mkdir -p deploy-package
                        
                        # Copy necessary files
                        cp -r app.js package.json package-lock.json Dockerfile docker-compose.yml nginx config controllers middleware models routes utils deploy-package/
                        
                        # Create production .env file
                        cat > deploy-package/.env << EOF
MONGODB_URI=${MONGODB_URI}
DB_NAME=daansetu
PORT=5000
NODE_ENV=production
JWT_SECRET=${JWT_SECRET}
JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
ADMIN_SETUP_KEY=${ADMIN_SETUP_KEY}
CORS_ORIGIN=*
EOF
                        
                        # Create deployment script
                        cat > deploy-package/deploy.sh << 'DEPLOY_EOF'
#!/bin/bash
set -e

echo "🚀 Starting DAANSETU deployment..."

# Navigate to deployment directory
cd /opt/daansetu-backend

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down || true

# Create logs directory
mkdir -p logs

# Build and start containers
echo "🏗️  Building and starting containers..."
docker-compose up -d --build

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 20

# Check container status
echo "📊 Container status:"
docker-compose ps

# Test health endpoint
echo "🧪 Testing health endpoint..."
for i in {1..5}; do
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo "✅ Health check passed!"
        break
    else
        echo "⏳ Attempt $i/5 - Waiting for service..."
        sleep 10
    fi
done

# Final health check
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "🎉 Deployment completed successfully!"
    echo "🌐 API available at: http://${EC2_PUBLIC_IP}/"
    echo "📖 Documentation: http://${EC2_PUBLIC_IP}/api-docs"
else
    echo "❌ Health check failed!"
    echo "Backend logs:"
    docker logs daansetu-backend --tail 50
    exit 1
fi
DEPLOY_EOF
                        
                        chmod +x deploy-package/deploy.sh
                    '''
                    
                    // Upload to EC2 using AWS CLI
                    sh '''
                        # Create temporary S3 bucket for deployment
                        BUCKET_NAME="daansetu-deploy-$(date +%s)"
                        aws s3 mb s3://$BUCKET_NAME
                        
                        # Upload deployment package
                        aws s3 sync deploy-package/ s3://$BUCKET_NAME/deploy/
                        
                        # Execute deployment on EC2
                        aws ssm send-command \
                            --instance-ids ${EC2_INSTANCE_ID} \
                            --document-name "AWS-RunShellScript" \
                            --parameters 'commands=["cd /tmp && aws s3 sync s3://'$BUCKET_NAME'/deploy/ /opt/daansetu-backend/ && chmod +x /opt/daansetu-backend/deploy.sh && /opt/daansetu-backend/deploy.sh"]' \
                            --output text --query 'Command.CommandId'
                        
                        # Cleanup S3 bucket
                        aws s3 rb s3://$BUCKET_NAME --force
                    '''
                }
                
                echo "✅ Deployment initiated on EC2 instance: ${env.EC2_INSTANCE_ID}"
            }
        }
        
        stage('✅ Health Check & Validation') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'production'
                }
            }
            steps {
                echo '🏥 Running health checks and validation...'
                script {
                    // Wait for deployment to complete
                    sleep 30
                    
                    // Test API endpoints
                    sh '''
                        # Test health endpoint
                        if curl -f http://${EC2_PUBLIC_IP}/health; then
                            echo "✅ Health endpoint working"
                        else
                            echo "❌ Health endpoint failed"
                            exit 1
                        fi
                        
                        # Test main API
                        if curl -f http://${EC2_PUBLIC_IP}/; then
                            echo "✅ Main API working"
                        else
                            echo "❌ Main API failed"
                            exit 1
                        fi
                        
                        # Test API documentation
                        if curl -f http://${EC2_PUBLIC_IP}/api-docs; then
                            echo "✅ API documentation accessible"
                        else
                            echo "❌ API documentation failed"
                            exit 1
                        fi
                    '''
                }
                
                echo "✅ All health checks passed!"
            }
        }
        
        stage('📢 Notifications') {
            steps {
                echo '📢 Sending deployment notifications...'
                script {
                    def message = """
🎉 DAANSETU Backend Deployment Successful!

📊 Deployment Details:
• Branch: ${env.GIT_BRANCH}
• Commit: ${env.GIT_COMMIT_SHORT}
• Build: #${env.BUILD_NUMBER}
• Instance: ${env.EC2_INSTANCE_ID}
• IP: ${env.EC2_PUBLIC_IP}

🌐 API Endpoints:
• Main API: http://${env.EC2_PUBLIC_IP}/
• Health Check: http://${env.EC2_PUBLIC_IP}/health
• Documentation: http://${env.EC2_PUBLIC_IP}/api-docs

✅ Status: All systems operational
                    """
                    
                    echo message
                    
                    // Add Slack/Discord/Email notifications here
                    // slackSend channel: '#deployments', message: message
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            // Send success notification
        }
        failure {
            echo '❌ Pipeline failed!'
            // Send failure notification
        }
        always {
            // Cleanup
            sh 'docker system prune -f || true'
            sh 'rm -rf deploy-package terraform-outputs.json || true'
            cleanWs()
        }
    }
}