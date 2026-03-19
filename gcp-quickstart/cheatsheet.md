# GCP Cloud Run & Scheduler Cheatsheet

## 🚀 gcloud CLI Quick Reference

### Initial Setup

```bash
# Login
gcloud auth login

# Set project
gcloud config set project PROJECT_ID

# Set default region
gcloud config set run/region us-central1

# List current configuration
gcloud config list

# Switch projects
gcloud config set project another-project-id
```

---

## ☁️ Cloud Run Commands

### Deploy

```bash
# Deploy from source (recommended - no Docker needed)
gcloud run deploy SERVICE_NAME \
  --source . \
  --region us-central1 \
  --allow-unauthenticated

# Deploy from container image
gcloud run deploy SERVICE_NAME \
  --image gcr.io/PROJECT_ID/IMAGE_NAME \
  --region us-central1

# Deploy with options
gcloud run deploy SERVICE_NAME \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --max-instances 5 \
  --memory 512Mi \
  --timeout 300 \
  --set-env-vars "KEY1=value1,KEY2=value2"

# Deploy with secrets
gcloud run deploy SERVICE_NAME \
  --source . \
  --set-secrets "DB_PASSWORD=db-password:latest"
```

### List & Describe

```bash
# List all services
gcloud run services list

# Describe service
gcloud run services describe SERVICE_NAME --region us-central1

# Get service URL
gcloud run services describe SERVICE_NAME \
  --region us-central1 \
  --format='value(status.url)'
```

### Update

```bash
# Update environment variables
gcloud run services update SERVICE_NAME \
  --region us-central1 \
  --update-env-vars "KEY=new_value"

# Update memory/CPU
gcloud run services update SERVICE_NAME \
  --region us-central1 \
  --memory 1Gi \
  --cpu 2

# Update max instances
gcloud run services update SERVICE_NAME \
  --region us-central1 \
  --max-instances 10

# Update to require authentication
gcloud run services update SERVICE_NAME \
  --region us-central1 \
  --no-allow-unauthenticated
```

### Delete

```bash
# Delete service
gcloud run services delete SERVICE_NAME --region us-central1

# Delete without confirmation
gcloud run services delete SERVICE_NAME --region us-central1 --quiet
```

### Logs

```bash
# Stream logs in real-time
gcloud run services logs tail SERVICE_NAME --region us-central1

# Read recent logs
gcloud run services logs read SERVICE_NAME --region us-central1 --limit 50

# Filter logs by severity
gcloud run services logs read SERVICE_NAME \
  --region us-central1 \
  --log-filter="severity>=WARNING"
```

---

## ⏰ Cloud Scheduler Commands

### Create Jobs

```bash
# HTTP job (most common for Cloud Run)
gcloud scheduler jobs create http JOB_NAME \
  --location us-central1 \
  --schedule "0 9 * * *" \
  --uri "https://service-url.run.app/endpoint" \
  --http-method GET \
  --time-zone "Europe/London"

# HTTP with POST and body
gcloud scheduler jobs create http JOB_NAME \
  --location us-central1 \
  --schedule "*/5 * * * *" \
  --uri "https://service-url.run.app/endpoint" \
  --http-method POST \
  --message-body '{"key":"value"}' \
  --headers "Content-Type=application/json"

# HTTP with authentication
gcloud scheduler jobs create http JOB_NAME \
  --location us-central1 \
  --schedule "0 * * * *" \
  --uri "https://service-url.run.app/endpoint" \
  --oidc-service-account-email SERVICE_ACCOUNT@PROJECT.iam.gserviceaccount.com
```

### List & Describe

```bash
# List all jobs
gcloud scheduler jobs list --location us-central1

# Describe specific job
gcloud scheduler jobs describe JOB_NAME --location us-central1
```

### Update Jobs

```bash
# Update schedule
gcloud scheduler jobs update http JOB_NAME \
  --location us-central1 \
  --schedule "0 */2 * * *"

# Update URI
gcloud scheduler jobs update http JOB_NAME \
  --location us-central1 \
  --uri "https://new-url.run.app/endpoint"

# Update timezone
gcloud scheduler jobs update http JOB_NAME \
  --location us-central1 \
  --time-zone "America/New_York"
```

### Run & Control

```bash
# Manually trigger job
gcloud scheduler jobs run JOB_NAME --location us-central1

# Pause job
gcloud scheduler jobs pause JOB_NAME --location us-central1

# Resume job
gcloud scheduler jobs resume JOB_NAME --location us-central1
```

### Delete

```bash
# Delete job
gcloud scheduler jobs delete JOB_NAME --location us-central1
```

---

## 📝 Cloud Logging Commands

### Query Logs

```bash
# All logs for a service
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=SERVICE_NAME" --limit 50

# Logs by severity
gcloud logging read "resource.type=cloud_run_revision AND severity>=ERROR" --limit 20

# Logs in time range
gcloud logging read "resource.type=cloud_run_revision" \
  --format json \
  --freshness=1d

# Logs containing text
gcloud logging read "resource.type=cloud_run_revision AND textPayload:\"error\"" --limit 20

# JSON structured logs
gcloud logging read "resource.type=cloud_run_revision AND jsonPayload.level=\"ERROR\"" --limit 20
```

### Stream Logs

```bash
# Tail logs (like tail -f)
gcloud logging tail "resource.type=cloud_run_revision"

# Tail with filter
gcloud logging tail "resource.type=cloud_run_revision AND severity>=WARNING"
```

---

## 🏗️ Cloud Build Commands

### Build Container

```bash
# Build and push to Container Registry
gcloud builds submit --tag gcr.io/PROJECT_ID/IMAGE_NAME

# Build from specific directory
gcloud builds submit --tag gcr.io/PROJECT_ID/IMAGE_NAME ./app

# Build with custom Dockerfile
gcloud builds submit --tag gcr.io/PROJECT_ID/IMAGE_NAME --file=Dockerfile.prod
```

### List Builds

```bash
# List recent builds
gcloud builds list --limit 10

# Describe build
gcloud builds describe BUILD_ID

# View build logs
gcloud builds log BUILD_ID
```

---

## 🔐 IAM & Service Accounts

### Create Service Account

```bash
# Create service account
gcloud iam service-accounts create SA_NAME \
  --display-name "Service Account Display Name"

# Grant permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_NAME@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

### Invoke Service with Auth

```bash
# Get ID token
gcloud auth print-identity-token

# Invoke Cloud Run with auth
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://service-url.run.app/endpoint
```

---

## 🎛️ Project Management

```bash
# List projects
gcloud projects list

# Get current project
gcloud config get-value project

# Set project
gcloud config set project PROJECT_ID

# Create new project
gcloud projects create PROJECT_ID --name="Project Name"
```

---

## 💰 Billing & Cost

```bash
# List billing accounts
gcloud billing accounts list

# Link project to billing
gcloud billing projects link PROJECT_ID \
  --billing-account BILLING_ACCOUNT_ID

# View project billing info
gcloud billing projects describe PROJECT_ID
```

---

## 📊 Cron Schedule Syntax

Standard cron format: `minute hour day month day-of-week`

```bash
# Every minute
"* * * * *"

# Every 5 minutes
"*/5 * * * *"

# Every hour at minute 0
"0 * * * *"

# Every day at 9:00 AM
"0 9 * * *"

# Every weekday at 9:00 AM
"0 9 * * 1-5"

# Every Monday at 9:00 AM
"0 9 * * 1"

# First day of month at midnight
"0 0 1 * *"

# Every 2 hours
"0 */2 * * *"

# Twice a day (9 AM and 5 PM)
"0 9,17 * * *"
```

---

## 🌍 Regions

### Free Tier Regions (Always Free):
- `us-central1` (Iowa)
- `us-east1` (South Carolina)
- `us-west1` (Oregon)

### Other Popular Regions:
- `europe-west1` (Belgium)
- `asia-east1` (Taiwan)
- `australia-southeast1` (Sydney)

**Tip:** Stick to free tier regions (us-central1) for personal projects!

---

## 🔧 Common Patterns

### Deploy & Schedule Pattern

```bash
# 1. Deploy Cloud Run service
gcloud run deploy my-service \
  --source . \
  --region us-central1 \
  --allow-unauthenticated

# 2. Get service URL
SERVICE_URL=$(gcloud run services describe my-service \
  --region us-central1 \
  --format='value(status.url)')

# 3. Create scheduler job
gcloud scheduler jobs create http my-daily-job \
  --location us-central1 \
  --schedule "0 9 * * *" \
  --uri "${SERVICE_URL}/endpoint" \
  --http-method POST \
  --time-zone "Europe/London"

# 4. Test it
gcloud scheduler jobs run my-daily-job --location us-central1
```

### Update & Verify Pattern

```bash
# 1. Update code
# (edit your files)

# 2. Redeploy
gcloud run deploy my-service --source . --region us-central1

# 3. View logs to verify
gcloud run services logs tail my-service --region us-central1

# 4. Test endpoint
curl https://my-service-xxx.run.app/endpoint
```

### Cleanup Pattern

```bash
# Delete everything (saves costs)
gcloud scheduler jobs delete JOB_NAME --location us-central1 --quiet
gcloud run services delete SERVICE_NAME --region us-central1 --quiet
```

---

## 🆘 Troubleshooting Commands

```bash
# Check current configuration
gcloud config list

# Verify authentication
gcloud auth list

# Check enabled APIs
gcloud services list --enabled

# Enable API
gcloud services enable SERVICE_NAME.googleapis.com

# View recent errors
gcloud logging read "severity>=ERROR" --limit 20 --format json

# Check quotas
gcloud compute project-info describe --project PROJECT_ID
```

---

## 📚 Documentation Links

- Cloud Run: https://cloud.google.com/run/docs
- Cloud Scheduler: https://cloud.google.com/scheduler/docs
- gcloud CLI: https://cloud.google.com/sdk/gcloud/reference
- Cloud Logging: https://cloud.google.com/logging/docs
- Free Tier: https://cloud.google.com/free

---

**Pro Tip:** Use `gcloud --help` or `gcloud COMMAND --help` for detailed help on any command!

**Aliases to save typing:**
```bash
alias gcr='gcloud run'
alias gcs='gcloud scheduler'
alias gcl='gcloud logging'
```
