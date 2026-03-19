# Streamlit Health Checker - Deployment Guide

Production-ready health monitoring for Streamlit apps using GCP Cloud Run + Scheduler.

## 🎯 What This Does

- Monitors multiple Streamlit apps
- Wakes sleeping instances by sending HTTP requests
- Logs results to Cloud Logging
- Runs on schedule (via Cloud Scheduler)
- Costs $0/month (free tier)

## 📋 Prerequisites

- GCP account with billing enabled
- gcloud CLI installed and authenticated
- Completed PREFLIGHT.md setup

## 🚀 Quick Deploy

```bash
# 1. Navigate to this directory
cd streamlit-health-checker

# 2. Customize your apps (edit health_check.py)
# Update the STREAMLIT_APPS list with your Streamlit app URLs

# 3. Deploy to Cloud Run
gcloud run deploy streamlit-health-checker \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --max-instances 1 \
  --memory 256Mi \
  --timeout 60

# 4. Note the Service URL (e.g., https://streamlit-health-checker-xxx-uc.a.run.app)

# 5. Test it manually
curl -X POST https://YOUR-SERVICE-URL/health-check

# 6. Create Cloud Scheduler jobs
gcloud scheduler jobs create http streamlit-morning-check \
  --location us-central1 \
  --schedule "55 8 * * *" \
  --uri "https://YOUR-SERVICE-URL/health-check" \
  --http-method POST \
  --time-zone "Europe/London"

gcloud scheduler jobs create http streamlit-evening-check \
  --location us-central1 \
  --schedule "5 23 * * *" \
  --uri "https://YOUR-SERVICE-URL/health-check" \
  --http-method POST \
  --time-zone "Europe/London"

# 7. Done! Your cron jobs are now in the cloud! 🎉
```

## 🔧 Customization

### Add More Apps

Edit `health_check.py`:

```python
STREAMLIT_APPS = [
    "https://qr-greeting.streamlit.app",
    "https://web-player.streamlit.app",
    "https://net-test.streamlit.app",
    "https://your-new-app.streamlit.app"  # Add here!
]
```

Redeploy:
```bash
gcloud run deploy streamlit-health-checker --source . --region us-central1
```

### Change Schedule

Update scheduler jobs:
```bash
# Every 2 hours
gcloud scheduler jobs update http streamlit-morning-check \
  --schedule "0 */2 * * *" \
  --location us-central1

# Every day at 3 PM
gcloud scheduler jobs update http streamlit-evening-check \
  --schedule "0 15 * * *" \
  --location us-central1
```

### Add More Schedule Jobs

```bash
# Midday check
gcloud scheduler jobs create http streamlit-midday-check \
  --location us-central1 \
  --schedule "0 12 * * *" \
  --uri "https://YOUR-SERVICE-URL/health-check" \
  --http-method POST \
  --time-zone "Europe/London"
```

**Remember:** First 3 jobs are free, 4th+ costs $0.10/month each

## 📊 Monitoring

### View Logs

Real-time:
```bash
gcloud run services logs tail streamlit-health-checker --region us-central1
```

Recent logs:
```bash
gcloud run services logs read streamlit-health-checker --region us-central1 --limit 50
```

Query specific patterns:
```bash
# Show only errors
gcloud logging read "resource.type=cloud_run_revision AND severity>=ERROR" --limit 20

# Show health check results
gcloud logging read "resource.type=cloud_run_revision AND textPayload:\"Health check complete\"" --limit 20
```

### Test Health Check

```bash
# Manual trigger
curl -X POST https://YOUR-SERVICE-URL/health-check | jq

# Expected response:
{
  "timestamp": "2026-03-19T23:00:00.000000",
  "total_apps": 3,
  "healthy_apps": 3,
  "unhealthy_apps": 0,
  "success_rate": "100.0%",
  "results": [...]
}
```

### Check Scheduler Jobs

```bash
# List all jobs
gcloud scheduler jobs list --location us-central1

# Manually trigger a job
gcloud scheduler jobs run streamlit-morning-check --location us-central1

# View job execution history (via Console)
# https://console.cloud.google.com/cloudscheduler
```

## 💰 Cost Monitoring

### Expected Usage

- **Cloud Run:** 2-3 requests/day = ~90/month (FREE - under 2M limit)
- **Cloud Scheduler:** 2 jobs (FREE - under 3 job limit)
- **Cloud Logging:** ~1MB/month (FREE - under 50GB limit)
- **Total:** $0/month ✅

### Check Current Usage

```bash
# Cloud Run metrics
gcloud run services describe streamlit-health-checker --region us-central1

# Billing dashboard
open https://console.cloud.google.com/billing
```

### Set Budget Alerts

Already done in PREFLIGHT.md, but verify:
```bash
# List budgets
gcloud billing budgets list --billing-account YOUR_BILLING_ACCOUNT_ID
```

## 🔧 Troubleshooting

### Deploy Fails

```bash
# Check build logs
gcloud builds list --limit 5
gcloud builds log BUILD_ID

# Common issues:
# - Requirements.txt missing/incorrect
# - Dockerfile syntax error
# - Region not free tier (use us-central1)
```

### Health Check Fails

```bash
# Test locally first
python health_check.py
# Visit http://localhost:8080/health-check

# Check Cloud Run logs
gcloud run services logs tail streamlit-health-checker --region us-central1

# Common issues:
# - Timeout (increase --timeout 60 to 120)
# - Streamlit app URL incorrect
# - Network issues (check Cloud Run egress limits)
```

### Scheduler Not Triggering

```bash
# Test manually
gcloud scheduler jobs run streamlit-morning-check --location us-central1

# Check job status
gcloud scheduler jobs describe streamlit-morning-check --location us-central1

# Common issues:
# - Wrong URI (must be full HTTPS URL)
# - Job paused (resume it)
# - Region mismatch (scheduler and Cloud Run should be same region)
```

## 🎓 Advanced Features

### Add WhatsApp Alerts

Integrate with OpenClaw to send alerts when apps are down:

```python
# In health_check.py, add this function:
def send_whatsapp_alert(unhealthy_apps):
    import subprocess
    message = f"⚠️ {len(unhealthy_apps)} Streamlit app(s) down: {', '.join(unhealthy_apps)}"
    subprocess.run([
        'openclaw', 'message', '--action', 'send', 
        '--channel', 'whatsapp', 
        '--target', '+447877585536',
        '--message', message
    ])

# Then in check_streamlit_health(), after results:
if summary['unhealthy_apps'] > 0:
    unhealthy = [r['url'] for r in results if r.get('health') != 'healthy']
    send_whatsapp_alert(unhealthy)
```

### Store Results in Firestore

Track uptime history:

```python
from google.cloud import firestore

db = firestore.Client()

# After each check:
db.collection('health_checks').add({
    'timestamp': firestore.SERVER_TIMESTAMP,
    'results': results,
    'healthy_count': healthy_count
})
```

### Create Uptime Dashboard

Build a Streamlit dashboard showing:
- Current status of all apps
- Uptime percentage (last 7/30 days)
- Response time trends
- Alert history

## 📚 Related Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Scheduler Documentation](https://cloud.google.com/scheduler/docs)
- [Cloud Logging Query Language](https://cloud.google.com/logging/docs/view/logging-query-language)
- [GCP Free Tier Limits](https://cloud.google.com/free/docs/free-cloud-features)

## 🆘 Need Help?

- Check main README: `../README.md`
- Review cheatsheet: `../cheatsheet.md`
- GCP Support: https://cloud.google.com/support

---

**You've replaced your local cron jobs with a production-ready cloud solution! 🎉**
