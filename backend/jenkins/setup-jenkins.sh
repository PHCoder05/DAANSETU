#!/bin/bash

###############################################################################
# Jenkins Setup Script for DAANSETU
# This script installs and configures Jenkins with required plugins
###############################################################################

set -e

echo "🔧 Installing Jenkins..."

# Update system
sudo apt-get update

# Install Java (Jenkins requirement)
sudo apt-get install -y openjdk-11-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt-get update
sudo apt-get install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "✅ Jenkins installed and started"

# Install required tools
echo "📦 Installing required tools..."

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

echo "✅ All tools installed"

# Get Jenkins initial password
echo ""
echo "🔑 Jenkins Initial Setup:"
echo "================================"
echo "1. Access Jenkins at: http://localhost:8080"
echo ""
echo "2. Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "3. Install suggested plugins"
echo ""
echo "4. Required additional plugins:"
echo "   - GitHub plugin"
echo "   - Docker plugin"
echo "   - AWS Steps plugin"
echo "   - Pipeline plugin"
echo "   - Blue Ocean (optional, for better UI)"
echo ""
echo "================================"

# Create Jenkins job configuration
cat > daansetu-job.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>DAANSETU Backend CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.93">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.11.3">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/your-username/daansetu-backend.git</url>
          <credentialsId>github-credentials</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

echo "📝 Jenkins job configuration created: daansetu-job.xml"
echo ""
echo "🎉 Jenkins setup complete!"
echo "Next steps:"
echo "1. Access Jenkins at http://localhost:8080"
echo "2. Complete the initial setup wizard"
echo "3. Add your credentials (GitHub, AWS, Docker Hub)"
echo "4. Create a new Pipeline job using daansetu-job.xml"
echo "5. Configure GitHub webhook"

