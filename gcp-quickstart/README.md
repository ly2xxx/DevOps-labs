# GCP Serverless Quick Start Guide
**Time to complete: ~45 minutes | Cost: Free tier**

## 🎯 What You'll Build

A production-ready Streamlit health checker that:
- Runs as a containerized Cloud Run service
- Triggers on schedule via Cloud Scheduler  
- Logs to Cloud Logging
- Costs $0/month (free tier)
- Replaces your local cron jobs

## 📚 The Big Picture

```
┌─────────────────────────────────────────────────────────┐
│                    Cloud Scheduler                       │
│  (Cron jobs in the cloud)                               │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │ Morning    │  │ Evening    │  │ Daily      │       │
│  │ 8:55 AM    │  │ 11:05 PM   │  │ Health     │       │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘       │
│        │                │                │              │
│        └────────────────┴────────────────┘              │
│                         │                               │
└─────────────────────────┼───────────────────────────────┘
                          │ (HTTP POST)
                          ▼
            ┌──────────────────────────┐
            │   Cloud Run Service      │
            │  (Container)             │
            │                          │
            │  health_check.py         │
            │  ↓                       │
            │  Check Streamlit apps    │
            │  ↓                       │
            │  Wake sleeping apps      │
            │  ↓                       │
            │  Log results             │
            └──────────────────────────┘
                          │
                          ▼
            ┌──────────────────────────┐
            │   Cloud Logging          │
            │  (Centralized logs)      │
            └──────────────────────────┘
```

### Key Concepts

1. **Cloud Run**
   - Fully managed serverless container platform
   - Auto-scales from 0 to N
   - Pay only when handling requests
   - Deploy from Dockerfile OR source code

2. **Cloud Scheduler**
   - Fully managed cron job service
   - Triggers HTTP endpoints on schedule
   - Supports timezones
   - 3 jobs free/month

3. **Cloud Logging**
   - Centralized log aggregation
   - Query with filters
   - Set up alerts
   - 50GB/month free

## 🚀 Hands-On Labs (45 minutes)

### Lab 1: Deploy Hello World to Cloud Run (15 min)
**Goal:** Understand Cloud Run basics

### Lab 2: Add Cloud Scheduler (15 min)
**Goal:** Trigger Cloud Run on schedule

### Lab 3: Deploy Streamlit Health Checker (15 min)
**Goal:** Replace your cron jobs with production-ready solution

---

## Lab 1: Deploy Hello World to Cloud Run

### Step 1: Create a Simple Flask App

Create a new directory:
```bash
mkdir hello-world-cloudrun
cd hello-world-cloudrun
```

Create `app.py`:
```python
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    name = os.environ.get('NAME', 'World')
    return f'Hello {name}! 🚀\n'

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
```

Create `requirements.txt`:
```
Flask==3.0.0
```

### Step 2: Create Dockerfile

Create `Dockerfile`:
```dockerfile
# Use official Python runtime
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Set environment variable
ENV PORT=8080

# Run the application
CMD ["python", "app.py"]
```

### Step 3: Deploy to Cloud Run

**Option A: Deploy from source (easier, no Docker needed)**
```bash
gcloud run deploy hello-world \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars NAME=GCP
```

**Option B: Build and deploy manually (if you have Docker)**
```bash
# Build container
docker build -t gcr.io/YOUR_PROJECT_ID/hello-world .

# Push to Google Container Registry
docker push gcr.io/YOUR_PROJECT_ID/hello-world

# Deploy
gcloud run deploy hello-world \
  --image gcr.io/YOUR_PROJECT_ID/hello-world \
  --region us-central1 \
  --allow-unauthenticated
```

### Step 4: Test Your Deployment

Cloud Run will output a URL like:
```
Service URL: https://hello-world-xxx-uc.a.run.app
```

Test it:
```bash
curl https://hello-world-xxx-uc.a.run.app
# Returns: Hello GCP! 🚀
```

Or visit in browser!

### Step 5: View Logs

```bash
# Stream logs in real-time
gcloud run services logs read hello-world --region us-central1 --limit 50
```

Or via Console:
https://console.cloud.google.com/run → Select service → LOGS

### Step 6: Update and Redeploy

Change `app.py`:
```python
@app.route('/')
def hello():
    return f'Hello from Cloud Run v2! 🎉\n'
```

Redeploy (same command as before):
```bash
gcloud run deploy hello-world \
  --source . \
  --region us-central1 \
  --allow-unauthenticated
```

Cloud Run automatically creates a new revision!

### Step 7: Clean Up (Optional)

```bash
# Delete service (if you want to clean up)
gcloud run services delete hello-world --region us-central1
```

**Key Takeaways:**
- ✅ Cloud Run deploys containers from source or Dockerfile
- ✅ Auto-generates HTTPS URL
- ✅ Scales to zero when not in use (cost = $0)
- ✅ Easy to update (just redeploy)

---

## Lab 2: Add Cloud Scheduler

**Goal:** Trigger your Cloud Run service on a schedule

### Step 1: Create a Scheduled Job

```bash
# Create a Cloud Scheduler job that hits your Cloud Run service every hour
gcloud scheduler jobs create http hello-hourly \
  --location us-central1 \
  --schedule "0 * * * *" \
  --uri "https://hello-world-xxx-uc.a.run.app/" \
  --http-method GET \
  --time-zone "Europe/London"
```

**Replace:** `https://hello-world-xxx-uc.a.run.app/` with YOUR Cloud Run URL

**Schedule format:** Standard cron format
- `0 * * * *` = Every hour at minute 0
- `*/5 * * * *` = Every 5 minutes
- `0 9 * * *` = Every day at 9:00 AM
- `0 9 * * 1-5` = Every weekday at 9:00 AM

### Step 2: Test the Job Manually

```bash
# Trigger immediately (don't wait for schedule)
gcloud scheduler jobs run hello-hourly --location us-central1
```

### Step 3: View Job History

Via Console:
1. Go to: https://console.cloud.google.com/cloudscheduler
2. Click on `hello-hourly`
3. See execution history and logs

Via gcloud:
```bash
# List all jobs
gcloud scheduler jobs list --location us-central1

# Describe specific job
gcloud scheduler jobs describe hello-hourly --location us-central1
```

### Step 4: Update Schedule

```bash
# Change to run every 30 minutes
gcloud scheduler jobs update http hello-hourly \
  --location us-central1 \
  --schedule "*/30 * * * *"
```

### Step 5: Pause/Resume

```bash
# Pause job
gcloud scheduler jobs pause hello-hourly --location us-central1

# Resume job
gcloud scheduler jobs resume hello-hourly --location us-central1
```

### Step 6: Add More Jobs (Remember: 3 free!)

```bash
# Morning check
gcloud scheduler jobs create http hello-morning \
  --location us-central1 \
  --schedule "0 9 * * *" \
  --uri "https://hello-world-xxx-uc.a.run.app/?time=morning" \
  --http-method GET \
  --time-zone "Europe/London"

# Evening check
gcloud scheduler jobs create http hello-evening \
  --location us-central1 \
  --schedule "0 21 * * *" \
  --uri "https://hello-world-xxx-uc.a.run.app/?time=evening" \
  --http-method GET \
  --time-zone "Europe/London"
```

**Free tier:** 3 jobs = FREE, 4th+ = $0.10/month each

### Step 7: Clean Up

```bash
# Delete jobs
gcloud scheduler jobs delete hello-hourly --location us-central1
gcloud scheduler jobs delete hello-morning --location us-central1
gcloud scheduler jobs delete hello-evening --location us-central1
```

**Key Takeaways:**
- ✅ Cloud Scheduler = managed cron jobs
- ✅ Triggers via HTTP (perfect for Cloud Run)
- ✅ Supports any timezone
- ✅ First 3 jobs are free!

---

## Lab 3: Deploy Streamlit Health Checker

**Goal:** Build production-ready health checker for your Streamlit apps

### Step 1: Project Structure

```bash
cd C:\code\DevOps-labs\gcp-quickstart\streamlit-health-checker
```

Files already created:
- `health_check.py` - Main application
- `Dockerfile` - Container definition
- `requirements.txt` - Python dependencies
- `README.md` - Deployment guide

### Step 2: Review the Code

**health_check.py** (already created):
```python
from flask import Flask, jsonify
import requests
import logging
import os
from datetime import datetime

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Streamlit apps to monitor
STREAMLIT_APPS = [
    "https://qr-greeting.streamlit.app",
    "https://web-player.streamlit.app",
    "https://net-test.streamlit.app"
]

@app.route('/health-check', methods=['GET', 'POST'])
def check_streamlit_health():
    """Check all Streamlit apps and wake sleeping ones"""
    timestamp = datetime.utcnow().isoformat()
    results = []
    
    for app_url in STREAMLIT_APPS:
        try:
            logger.info(f"Checking {app_url}...")
            response = requests.get(app_url, timeout=15)
            
            status = {
                'url': app_url,
                'status_code': response.status_code,
                'response_time_ms': int(response.elapsed.total_seconds() * 1000),
                'timestamp': timestamp
            }
            
            if response.status_code == 200:
                logger.info(f"✅ {app_url} is UP ({status['response_time_ms']}ms)")
                status['health'] = 'healthy'
            else:
                logger.warning(f"⚠️ {app_url} returned {response.status_code}")
                status['health'] = 'degraded'
            
            results.append(status)
            
        except requests.exceptions.Timeout:
            logger.error(f"❌ {app_url} - Timeout after 15s")
            results.append({
                'url': app_url,
                'health': 'timeout',
                'error': 'Request timeout after 15 seconds',
                'timestamp': timestamp
            })
        except Exception as e:
            logger.error(f"❌ {app_url} - Error: {str(e)}")
            results.append({
                'url': app_url,
                'health': 'error',
                'error': str(e),
                'timestamp': timestamp
            })
    
    # Summary
    healthy_count = sum(1 for r in results if r.get('health') == 'healthy')
    total_count = len(results)
    
    summary = {
        'timestamp': timestamp,
        'total_apps': total_count,
        'healthy_apps': healthy_count,
        'results': results
    }
    
    logger.info(f"Health check complete: {healthy_count}/{total_count} apps healthy")
    
    return jsonify(summary), 200

@app.route('/')
def home():
    """Root endpoint for health checks"""
    return "Streamlit Health Checker - Use POST /health-check to run checks\n"

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
```

### Step 3: Deploy to Cloud Run

```bash
cd streamlit-health-checker

gcloud run deploy streamlit-health-checker \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --max-instances 1 \
  --memory 256Mi \
  --timeout 60
```

**Flags explained:**
- `--max-instances 1` = Limit to 1 instance (cost control)
- `--memory 256Mi` = Minimal memory (this is lightweight)
- `--timeout 60` = 60 second timeout (health checks can take time)

### Step 4: Test Manually

Get your Cloud Run URL, then:

```bash
# Test the health check endpoint
curl -X POST https://streamlit-health-checker-xxx-uc.a.run.app/health-check
```

You should see JSON response with health check results!

### Step 5: Schedule Health Checks

```bash
# Morning health check (8:55 AM)
gcloud scheduler jobs create http streamlit-morning-check \
  --location us-central1 \
  --schedule "55 8 * * *" \
  --uri "https://streamlit-health-checker-xxx-uc.a.run.app/health-check" \
  --http-method POST \
  --time-zone "Europe/London"

# Evening health check (11:05 PM)
gcloud scheduler jobs create http streamlit-evening-check \
  --location us-central1 \
  --schedule "5 23 * * *" \
  --uri "https://streamlit-health-checker-xxx-uc.a.run.app/health-check" \
  --http-method POST \
  --time-zone "Europe/London"
```

**That's it! You've replaced your cron jobs!** 🎉

### Step 6: View Logs

**Real-time logs:**
```bash
gcloud run services logs tail streamlit-health-checker --region us-central1
```

**Query specific logs:**
```bash
# Show only errors
gcloud logging read "resource.type=cloud_run_revision AND severity>=ERROR" --limit 50

# Show health check results
gcloud logging read "resource.type=cloud_run_revision AND textPayload:\"Health check\"" --limit 20
```

**Via Console:**
https://console.cloud.google.com/run → streamlit-health-checker → LOGS

### Step 7: Monitor Costs

```bash
# Check Cloud Run usage
gcloud run services describe streamlit-health-checker --region us-central1
```

Via Console:
https://console.cloud.google.com/billing

**Expected cost:** $0/month (well within free tier)

---

## 🎓 What You've Accomplished

✅ Deployed containerized apps to Cloud Run  
✅ Scheduled tasks with Cloud Scheduler  
✅ Centralized logging with Cloud Logging  
✅ Replaced local cron jobs with cloud solution  
✅ Built production-ready health monitoring  

## 📊 Cost Breakdown

Your Streamlit health checker:

| Resource | Usage | Free Tier | Your Cost |
|----------|-------|-----------|-----------|
| Cloud Run | 2 requests/day × 30 = 60/month | 2M requests/month | $0 |
| Cloud Scheduler | 2 jobs | 3 jobs | $0 |
| Cloud Logging | ~1MB logs/month | 50GB/month | $0 |
| **Total** | | | **$0/month** ✅ |

## 🚀 Next Steps

### Enhance Your Health Checker

1. **Add alerting:**
```bash
# Create log-based metric and alert
gcloud logging metrics create unhealthy_streamlit_apps \
  --description="Count of unhealthy Streamlit apps" \
  --log-filter='resource.type="cloud_run_revision" AND textPayload:"❌"'
```

2. **Add WhatsApp notifications:**
- Integrate with your OpenClaw message API
- Send alert when app is down

3. **Monitor more apps:**
- Add more URLs to `STREAMLIT_APPS` list
- Redeploy

4. **Add a dashboard:**
- Store results in Firestore
- Build Streamlit dashboard showing uptime

### Explore More GCP

- **Cloud Functions:** Simpler than Cloud Run for single functions
- **Cloud Build:** CI/CD pipelines (auto-deploy on git push)
- **Firestore:** NoSQL database (1GB free!)
- **Secret Manager:** Store API keys securely

---

## 🆘 Troubleshooting

**Deploy fails:**
```bash
# Check build logs
gcloud builds list --limit 5
gcloud builds log BUILD_ID
```

**Scheduler not triggering:**
```bash
# Manually trigger to test
gcloud scheduler jobs run JOB_NAME --location us-central1

# Check job status
gcloud scheduler jobs describe JOB_NAME --location us-central1
```

**High costs:**
```bash
# Check billing
gcloud billing accounts list
gcloud billing projects describe PROJECT_ID
```

---

**Congratulations! You've mastered GCP serverless deployment! 🎉**

Check out `cheatsheet.md` for quick reference commands.
