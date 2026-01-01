# DAANSETU Backend - GitHub Repository Setup
# This script helps you set up GitHub repository for automated deployment

Write-Host "🐙 DAANSETU GitHub Repository Setup" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Steps to set up GitHub deployment:" -ForegroundColor Blue
Write-Host ""

Write-Host "1️⃣ Create GitHub Repository:" -ForegroundColor Yellow
Write-Host "   • Go to: https://github.com/new" -ForegroundColor White
Write-Host "   • Repository name: daansetu-backend" -ForegroundColor White
Write-Host "   • Make it PRIVATE (recommended)" -ForegroundColor White
Write-Host "   • Don't initialize with README" -ForegroundColor White
Write-Host ""

Write-Host "2️⃣ Push your code to GitHub:" -ForegroundColor Yellow
Write-Host "   git init" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor White
Write-Host "   git commit -m 'Initial commit'" -ForegroundColor White
Write-Host "   git branch -M main" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/daansetu-backend.git" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ Set up GitHub Secrets:" -ForegroundColor Yellow
Write-Host "   • Go to: https://github.com/YOUR_USERNAME/daansetu-backend/settings/secrets/actions" -ForegroundColor White
Write-Host "   • Add these secrets:" -ForegroundColor White
Write-Host "     - EC2_HOST: 54.209.219.220" -ForegroundColor White
Write-Host "     - EC2_USER: ubuntu" -ForegroundColor White
Write-Host "     - SSH_PRIVATE_KEY: (paste your private key)" -ForegroundColor White
Write-Host "     - MONGODB_URI: mongodb+srv://root:root@cluster0.rxcp0.mongodb.net/..." -ForegroundColor White
Write-Host "     - JWT_SECRET: 7fa4999230ab91a0051f3f84eb271e97f63427a8f90540b7a38c3549edfd62ed" -ForegroundColor White
Write-Host "     - JWT_REFRESH_SECRET: 1db9aefc2f697b1c651be41344ee2d04820fa85b84f1d3f87d84be007e8a433e" -ForegroundColor White
Write-Host "     - ADMIN_SETUP_KEY: 0e5a3b3af7298afe816b72196376c355" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣ Create GitHub Actions workflow:" -ForegroundColor Yellow
Write-Host "   • Create: .github/workflows/deploy.yml" -ForegroundColor White
Write-Host "   • Copy the workflow from: docs/github-actions-workflow.yml" -ForegroundColor White
Write-Host ""

Write-Host "5️⃣ Test automated deployment:" -ForegroundColor Yellow
Write-Host "   • Make a small change to your code" -ForegroundColor White
Write-Host "   • Commit and push: git add . && git commit -m 'Test deployment' && git push" -ForegroundColor White
Write-Host "   • Check Actions tab in GitHub" -ForegroundColor White
Write-Host "   • Your EC2 will auto-deploy!" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Benefits of GitHub deployment:" -ForegroundColor Green
Write-Host "   ✅ Automatic deployment on code push" -ForegroundColor White
Write-Host "   ✅ No manual uploads needed" -ForegroundColor White
Write-Host "   ✅ Version control and rollback" -ForegroundColor White
Write-Host "   ✅ Team collaboration" -ForegroundColor White
Write-Host "   ✅ Free for public repos" -ForegroundColor White
Write-Host ""

Write-Host "🚀 Quick Start Commands:" -ForegroundColor Blue
Write-Host "   # Initialize git (if not already done)" -ForegroundColor White
Write-Host "   git init" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor White
Write-Host "   git commit -m 'Initial commit'" -ForegroundColor White
Write-Host ""
Write-Host "   # Add your GitHub repository" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/daansetu-backend.git" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor White
