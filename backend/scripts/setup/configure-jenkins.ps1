# Jenkins Configuration Script
# This script helps configure Jenkins for DAANSETU backend

Write-Host "🔧 Configuring Jenkins for DAANSETU Backend..." -ForegroundColor Green

# Check if Jenkins is running
Write-Host "🔍 Checking Jenkins status..." -ForegroundColor Yellow
try {
    $jenkinsStatus = Get-Service -Name "Jenkins" -ErrorAction SilentlyContinue
    if ($jenkinsStatus -and $jenkinsStatus.Status -eq "Running") {
        Write-Host "✅ Jenkins is running" -ForegroundColor Green
    } else {
        Write-Host "❌ Jenkins is not running. Please start it first:" -ForegroundColor Red
        Write-Host "   Start-Service Jenkins" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ Jenkins service not found. Please install Jenkins first:" -ForegroundColor Red
    Write-Host "   .\scripts\setup\install-jenkins.ps1" -ForegroundColor Yellow
    exit 1
}

# Wait for Jenkins to be ready
Write-Host "⏳ Waiting for Jenkins to be ready..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0

do {
    Start-Sleep -Seconds 2
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Jenkins is ready!" -ForegroundColor Green
            break
        }
    } catch {
        if ($attempt -eq $maxAttempts) {
            Write-Host "❌ Jenkins is not responding after $($maxAttempts * 2) seconds" -ForegroundColor Red
            exit 1
        }
    }
} while ($attempt -lt $maxAttempts)

Write-Host ""
Write-Host "🎯 Jenkins Configuration Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 🌐 Open Jenkins in your browser:" -ForegroundColor White
Write-Host "   http://localhost:8080" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. 🔑 Get initial admin password:" -ForegroundColor White
Write-Host "   Get-Content 'C:\Program Files (x86)\Jenkins\secrets\initialAdminPassword'" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. 📦 Install suggested plugins:" -ForegroundColor White
Write-Host "   - Git" -ForegroundColor Gray
Write-Host "   - Docker Pipeline" -ForegroundColor Gray
Write-Host "   - AWS Steps" -ForegroundColor Gray
Write-Host "   - Blue Ocean" -ForegroundColor Gray
Write-Host ""
Write-Host "4. 👤 Create admin user:" -ForegroundColor White
Write-Host "   - Username: admin" -ForegroundColor Gray
Write-Host "   - Password: [your choice]" -ForegroundColor Gray
Write-Host "   - Email: [your email]" -ForegroundColor Gray
Write-Host ""
Write-Host "5. 🔐 Add AWS credentials:" -ForegroundColor White
Write-Host "   - Go to: Manage Jenkins → Manage Credentials" -ForegroundColor Gray
Write-Host "   - Add: AWS Credentials" -ForegroundColor Gray
Write-Host "   - ID: aws-credentials" -ForegroundColor Gray
Write-Host "   - Access Key: [your access key]" -ForegroundColor Gray
Write-Host "   - Secret Key: [your secret key]" -ForegroundColor Gray
Write-Host ""
Write-Host "6. 🔐 Add other credentials:" -ForegroundColor White
Write-Host "   - mongodb-uri: mongodb+srv://[username]:[password]@[cluster].mongodb.net/?retryWrites=true&w=majority&appName=Cluster0" -ForegroundColor Gray
Write-Host "   - jwt-secret: 7fa4999230ab91a0051f3f84eb271e97f63427a8f90540b7a38c3549edfd62ed" -ForegroundColor Gray
Write-Host "   - jwt-refresh-secret: 1db9aefc2f697b1c651be41344ee2d04820fa85b84f1d3f87d84be007e8a433e" -ForegroundColor Gray
Write-Host "   - admin-setup-key: 0e5a3b3af7298afe816b72196376c355" -ForegroundColor Gray
Write-Host ""
Write-Host "7. 🚀 Create pipeline job:" -ForegroundColor White
Write-Host "   - New Item → Pipeline" -ForegroundColor Gray
Write-Host "   - Name: daansetu-backend-pipeline" -ForegroundColor Gray
Write-Host "   - Pipeline script from SCM" -ForegroundColor Gray
Write-Host "   - SCM: Git" -ForegroundColor Gray
Write-Host "   - Repository URL: https://github.com/PHCoder05/DAANSETU_BACKEND_OPS.git" -ForegroundColor Gray
Write-Host "   - Branch: main" -ForegroundColor Gray
Write-Host "   - Script Path: Jenkinsfile" -ForegroundColor Gray
Write-Host ""
Write-Host "8. 🎯 Run pipeline:" -ForegroundColor White
Write-Host "   - Click 'Build Now' to run the pipeline" -ForegroundColor Gray
Write-Host "   - Monitor the build progress" -ForegroundColor Gray
Write-Host "   - Check console output for any issues" -ForegroundColor Gray
Write-Host ""

# Open Jenkins in browser
Write-Host "🌐 Opening Jenkins in browser..." -ForegroundColor Yellow
Start-Process "http://localhost:8080"

Write-Host "✅ Jenkins configuration guide completed!" -ForegroundColor Green
Write-Host "Follow the steps above to complete the setup." -ForegroundColor Cyan

