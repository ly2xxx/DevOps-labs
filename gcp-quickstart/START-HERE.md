# 🚀 GCP Serverless Quick Start

**Welcome!** This guide will get you deploying containerized apps on GCP in under an hour.

## 📂 What's in This Folder?

```
gcp-quickstart/
├── START-HERE.md              ← You are here!
├── PREFLIGHT.md               ← Setup checklist (10 min)
├── README.md                  ← Main tutorial with 3 labs (45 min)
├── cheatsheet.md              ← Quick reference for gcloud commands
├── streamlit-health-checker/  ← Real-world project: Streamlit health checks
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── health_check.py
│   └── README.md
└── hello-world-cloudrun/      ← Starter: Simple Cloud Run app
    ├── Dockerfile
    ├── app.py
    └── requirements.txt
```

## 🎯 What You'll Learn

By the end of this guide:
1. **Deploy containerized apps** - Cloud Run serverless containers
2. **Schedule tasks** - Cloud Scheduler for cron jobs
3. **Monitor & log** - Cloud Logging and Monitoring
4. **Cost control** - Stay within free tier limits
5. **Build real projects** - Working Streamlit health checker

**Total time: ~1 hour** (includes 3 hands-on labs + real project)

## 🏁 Quick Start (3 Steps)

### Step 1: Pre-flight (10 minutes)
```bash
# Open and complete:
PREFLIGHT.md
```
This ensures you have:
- ✅ GCP account with $300 credit
- ✅ gcloud CLI installed
- ✅ Billing alerts configured (important!)

### Step 2: Main Tutorial (45 minutes)
```bash
# Open and follow:
README.md
```
Three progressive labs:
- **Lab 1:** Deploy Hello World to Cloud Run (15 min)
- **Lab 2:** Add Cloud Scheduler (15 min)
- **Lab 3:** Deploy Streamlit Health Checker (15 min)

### Step 3: Reference Material
```bash
# Keep open while working:
cheatsheet.md
```
Quick lookup for gcloud commands and common patterns.

## 💡 The Big Picture

**Problem:** Your Streamlit apps sleep after inactivity. You need to wake them up regularly.

**Old solution:**
```
Windows laptop cron jobs → Wake apps
```
❌ Laptop must be running  
❌ No centralized logging  
❌ Manual management  

**GCP solution:**
```
Cloud Scheduler (cron) → Cloud Run container → Wake apps
```
✅ Always available (serverless)  
✅ Centralized logging  
✅ Auto-scales to zero (free when idle)  
✅ Containerized (portable)  

## 🎓 Learning Path

```
Tonight's Focus:
┌─────────────────────────────────────────────────┐
│ 1. Cloud Run Basics                             │ ← Lab 1
│    - Containerization, deployment, URLs         │
│                                                  │
│ 2. Cloud Scheduler                              │ ← Lab 2
│    - Cron jobs, HTTP triggers, timezones        │
│                                                  │
│ 3. Real-World Project                           │ ← Lab 3
│    - Streamlit health checker                   │
│    - Logging, monitoring, debugging             │
└─────────────────────────────────────────────────┘

After Tonight:
┌─────────────────────────────────────────────────┐
│ • Cloud Functions (serverless functions)        │
│ • Cloud Build (CI/CD pipelines)                 │
│ • Firestore (NoSQL database)                    │
│ • Cloud Storage (object storage)                │
│ • Secret Manager (credentials management)       │
└─────────────────────────────────────────────────┘
```

## ⚡ Ultra-Quick 5-Minute Demo

Want to see Cloud Run in action RIGHT NOW?

```bash
# 1. Clone a sample
git clone https://github.com/GoogleCloudPlatform/python-docs-samples
cd python-docs-samples/run/helloworld

# 2. Deploy (gcloud does everything!)
gcloud run deploy hello --source . --region=us-central1 --allow-unauthenticated

# 3. Visit the URL it prints!
# You just deployed a containerized app to production! 🎉
```

Clean up:
```bash
gcloud run services delete hello --region=us-central1
```

## 💰 Cost Notes

**All labs are FREE TIER** if you:
- ✅ Stay within 2M Cloud Run requests/month
- ✅ Use 3 or fewer Cloud Scheduler jobs
- ✅ Deploy to free tier regions (us-central1, us-east1, us-west1)
- ✅ Clean up resources when done experimenting

**Plus $300 credit** for 90 days to explore beyond free tier!

## 📚 Recommended Reading Order

1. **PREFLIGHT.md** - Setup checklist
2. **README.md** - Main tutorial (do all 3 labs)
3. **streamlit-health-checker/README.md** - Deploy your real project
4. **cheatsheet.md** - Reference material

Or jump straight to the 5-minute demo above!

## 🤔 Common Questions

**Q: Cloud Run vs Cloud Functions vs App Engine?**
A: 
- **Cloud Run:** Containerized apps (most flexible)
- **Cloud Functions:** Single-purpose functions (simplest)
- **App Engine:** Traditional web apps (less flexible)

**For this guide:** Cloud Run (containerized = portable + flexible)

**Q: Why not use Airflow for health checks?**
A: Airflow (Cloud Composer) costs ~$300/month and is massive overkill for simple HTTP pings. Cloud Scheduler + Cloud Run is free and perfect for this.

**Q: Do I need Docker experience?**
A: No! Cloud Run can build containers from source code automatically. We'll show both approaches.

**Q: What if I exceed free tier?**
A: Set up billing alerts (covered in PREFLIGHT). Cloud Run is incredibly cheap: $0.00002400 per request beyond free tier.

## 🆘 Getting Stuck?

**gcloud command fails:**
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

**Cloud Run deploy fails:**
- Check region (use us-central1 for free tier)
- Verify billing is enabled
- Check container logs: `gcloud run services logs read SERVICE_NAME`

**Billing questions:**
- View current usage: https://console.cloud.google.com/billing
- Set up alerts: https://console.cloud.google.com/billing/alerts

## 🎯 Success Criteria

By the end of tonight, you should be able to:
- ✅ Deploy a containerized app to Cloud Run
- ✅ Schedule tasks with Cloud Scheduler
- ✅ View logs in Cloud Logging
- ✅ Monitor costs and usage
- ✅ Deploy the Streamlit health checker (replace your cron jobs!)

**Bonus points:**
- ✅ Add monitoring alerts
- ✅ Set up CI/CD with Cloud Build
- ✅ Deploy to multiple regions

## 🚀 Ready to Start?

### Option A: Hands-On Learner
Go straight to **PREFLIGHT.md** → Complete checklist → Start **README.md Lab 1**

### Option B: See It Work First
Do the 5-minute demo above → Then go back and do full labs

### Option C: Deploy Real Project Now
Skip to **streamlit-health-checker/README.md** (requires PREFLIGHT first)

---

**Remember:** The best way to learn is by doing. Actually deploy the containers!

**Pro tip:** Keep GCP Console open in one window (https://console.cloud.google.com), this guide in another.

---

## 📊 Time Breakdown

| Activity | Time | What You'll Do |
|----------|------|----------------|
| Pre-flight | 10 min | Setup GCP account, install gcloud CLI |
| Lab 1 | 15 min | Deploy Hello World to Cloud Run |
| Lab 2 | 15 min | Add Cloud Scheduler cron job |
| Lab 3 | 15 min | Deploy Streamlit health checker |
| Exploration | 15 min | Customize, add monitoring, experiment |
| **Total** | **~1 hour** | **Full serverless deployment knowledge!** |

---

**Let's go! Open PREFLIGHT.md and start your GCP serverless journey! 🚀**
