# Pre-Flight Checklist ✈️

Complete these steps before starting the labs (10-15 minutes):

## ✅ Step 1: GCP Account Setup

### Create GCP Account (if new)
1. Go to: https://cloud.google.com/free
2. Click **Get started for free**
3. Sign in with Google account
4. Enter billing info (required for $300 credit, won't auto-charge)
5. Accept terms

**You get:**
- ✅ $300 credit (90 days)
- ✅ Always Free tier (no expiration)
- ✅ No auto-charge after trial (must manually upgrade)

### Create a Project
1. Go to: https://console.cloud.google.com/
2. Click **Select a project** (top bar) → **NEW PROJECT**
3. Project name: `devops-labs` (or your choice)
4. Click **Create**
5. **Important:** Note your Project ID (e.g., `devops-labs-123456`)

## ✅ Step 2: Enable Required APIs

```bash
# In Cloud Console, enable these APIs:
# Or use gcloud (after Step 3):

gcloud services enable run.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable logging.googleapis.com
```

**Via Console:**
1. Go to: https://console.cloud.google.com/apis/library
2. Search and enable:
   - Cloud Run API
   - Cloud Scheduler API
   - Cloud Build API
   - Cloud Logging API

## ✅ Step 3: Install gcloud CLI

### Windows (PowerShell):
```powershell
# Download installer
$url = "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe"
$installer = "$env:TEMP\GoogleCloudSDKInstaller.exe"
Invoke-WebRequest -Uri $url -OutFile $installer
Start-Process $installer -Wait

# Restart PowerShell, then:
gcloud --version
```

### macOS:
```bash
# Using Homebrew
brew install --cask google-cloud-sdk

# Or download installer:
# https://cloud.google.com/sdk/docs/install#mac
```

### Linux:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud --version
```

### Verify Installation:
```bash
gcloud --version
# Should show: Google Cloud SDK 4xx.x.x
```

## ✅ Step 4: Authenticate & Configure

```bash
# 1. Login to GCP
gcloud auth login
# Opens browser, sign in with your Google account

# 2. Set default project
gcloud config set project YOUR_PROJECT_ID
# Replace YOUR_PROJECT_ID with your project ID from Step 1

# 3. Set default region (for free tier)
gcloud config set run/region us-central1

# 4. Verify configuration
gcloud config list
```

**Expected output:**
```
[core]
account = you@gmail.com
project = devops-labs-123456

[run]
region = us-central1
```

## ✅ Step 5: Enable Billing (Required)

1. Go to: https://console.cloud.google.com/billing
2. Link your project to the billing account
3. **Don't worry:** You won't be charged with $300 credit + free tier
4. You'll need this for Cloud Run and Scheduler

### Set Up Billing Alerts (CRITICAL!)

1. Go to: https://console.cloud.google.com/billing/alerts
2. Click **CREATE BUDGET**
3. Budget name: `Free Tier Warning`
4. Set amount: **$10/month**
5. Add alert thresholds:
   - 50% ($5)
   - 90% ($9)
   - 100% ($10)
6. Add your email
7. Click **FINISH**

**Why $10?** Free tier should cost $0. If you hit $10, something's wrong!

## ✅ Step 6: Install Docker (Optional but Recommended)

**Only needed if you want to test containers locally.**

### Windows:
- Docker Desktop: https://www.docker.com/products/docker-desktop/

### macOS:
```bash
brew install --cask docker
```

### Linux:
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Verify:
```bash
docker --version
# Should show: Docker version 20.x.x or later
```

**Note:** Cloud Run can build from source WITHOUT Docker locally!

## ✅ Step 7: Test Your Setup

Run this quick test to verify everything works:

```bash
# Should work if setup is correct:
gcloud projects describe $(gcloud config get-value project)

# Expected: Shows your project details
```

If you see your project info, **you're ready to go!** 🎉

## ✅ Step 8: Understand Free Tier Limits

### Cloud Run (Always Free):
- ✅ 2 million requests/month
- ✅ 360,000 GB-seconds compute time
- ✅ 180,000 vCPU-seconds
- ✅ 1GB egress/month

### Cloud Scheduler (Always Free):
- ✅ 3 jobs (free)
- ❌ Job 4+ costs $0.10/month each

### Cloud Build (Always Free):
- ✅ 120 build-minutes/day

### For This Lab:
**Streamlit health checker = 2 Cloud Run invocations/day = ~60/month**

**Well within free tier!** ✅

## ✅ You're Ready! 🚀

**Checklist:**
- ✅ GCP account created ($300 credit)
- ✅ Project created (note Project ID)
- ✅ Required APIs enabled
- ✅ gcloud CLI installed & authenticated
- ✅ Default project & region set
- ✅ Billing enabled
- ✅ Billing alerts configured ($10 threshold)
- ✅ (Optional) Docker installed

**Next step:** Open `README.md` and start **Lab 1**!

---

## 🆘 Troubleshooting

### "gcloud: command not found"
- Restart terminal/PowerShell after installation
- Add to PATH manually if needed

### "API not enabled" errors
- Run: `gcloud services enable SERVICE_NAME.googleapis.com`
- Or enable via Console: https://console.cloud.google.com/apis/library

### Billing not enabled
- Must link billing account even with $300 credit
- Go to: https://console.cloud.google.com/billing

### Region not free tier
- Use: `us-central1`, `us-east1`, or `us-west1`
- Avoid: `europe-west1`, `asia-east1` (not free tier)

### Docker issues (optional)
- Cloud Run can build from source without Docker locally
- Skip Docker if you have issues - we'll use Cloud Build instead

---

**Remember:** Set up billing alerts! This is your safety net. 🛡️

**Ready to deploy?** Go to `README.md` and start Lab 1! 🚀
