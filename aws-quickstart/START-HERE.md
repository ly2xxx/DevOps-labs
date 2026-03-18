# 🚀 AWS CloudFormation & Service Catalog Quick Start

**Welcome!** This guide will get you hands-on with AWS infrastructure automation in under an hour.

## 📂 What's in This Folder?

```
aws-quickstart/
├── START-HERE.md          ← You are here! Read this first
├── PREFLIGHT.md           ← Complete this checklist (5-10 min)
├── README.md              ← Main tutorial with 3 hands-on labs (45 min)
├── cheatsheet.md          ← Quick reference for commands and syntax
├── lab1-simple-s3.yaml    ← Lab 1: Simple S3 bucket template
├── lab2-ec2-with-vpc.yaml ← Lab 2: Web server with full networking
└── lab3-rds-database.yaml ← Lab 3 (Bonus): MySQL database setup
```

## 🎯 What You'll Learn

By tonight you'll be able to:
1. **Write CloudFormation templates** - Define AWS infrastructure as code
2. **Deploy stacks** - Create/update/delete entire environments with one command
3. **Use Service Catalog** - Provide self-service infrastructure to teams
4. **Understand governance** - Control who can deploy what, with constraints

**Total time: ~1 hour** (includes 3 hands-on labs)

## 🏁 Quick Start (3 Steps)

### Step 1: Pre-flight (5-10 minutes)
```bash
# Open and complete:
PREFLIGHT.md
```
This ensures you have:
- ✅ AWS account access
- ✅ EC2 key pair created
- ✅ Billing alerts configured (important!)

### Step 2: Main Tutorial (45 minutes)
```bash
# Open and follow:
README.md
```
Three progressive labs:
- **Lab 1:** Deploy an S3 bucket (15 min)
- **Lab 2:** Deploy a web server with VPC (15 min)
- **Lab 3:** Set up Service Catalog (15 min)

### Step 3: Reference Material
```bash
# Keep open while working:
cheatsheet.md
```
Quick lookup for commands and syntax.

## 💡 The Big Picture

**Before CloudFormation:**
```
Click AWS Console → Create VPC → Create Subnet → 
Create Security Group → Launch EC2 → (repeat 100x) → 
Forget a step → Manually troubleshoot → 😩
```

**With CloudFormation:**
```
Write template.yaml → `aws cloudformation deploy` → ☕ → Done! ✅
Want another environment? → Re-run command → Done again! 🎉
```

**With Service Catalog:**
```
Developer clicks "Launch Dev Environment" button → 
CloudFormation deploys automatically (with your rules!) → 
Developer happy, you happy, security happy! 🚀
```

## 🎓 Learning Path

```
Tonight's Focus:
┌─────────────────────────────────────────────────┐
│ 1. CloudFormation Basics                        │ ← Lab 1
│    - Templates, stacks, parameters               │
│                                                  │
│ 2. Multi-Resource Stacks                        │ ← Lab 2
│    - Dependencies, networking, UserData          │
│                                                  │
│ 3. Service Catalog                               │ ← Lab 3
│    - Products, portfolios, self-service          │
└─────────────────────────────────────────────────┘

After Tonight:
┌─────────────────────────────────────────────────┐
│ • Nested stacks (modular templates)             │
│ • StackSets (multi-account/region)              │
│ • CDK (define infrastructure in Python/TS)      │
│ • CI/CD integration (GitHub Actions, Jenkins)   │
└─────────────────────────────────────────────────┘
```

## ⚡ Ultra-Quick 5-Minute Demo

If you want to see CloudFormation in action RIGHT NOW:

1. **Go to:** https://console.aws.amazon.com/cloudformation/
2. **Click:** Create stack → With new resources
3. **Upload:** `lab1-simple-s3.yaml`
4. **Stack name:** `test-stack`
5. **BucketName:** `yourname-test-bucket-20260318` (must be unique!)
6. **Click:** Next → Next → Submit
7. **Watch:** The Events tab as AWS creates your bucket
8. **Check:** Resources tab - your S3 bucket exists!
9. **Clean up:** Select stack → Delete

**🎉 Congratulations! You just automated AWS infrastructure!**

## 💰 Cost Notes

**All labs are FREE TIER** if you:
- ✅ Delete stacks immediately after testing
- ✅ Use `t2.micro`/`t3.micro` instances only
- ✅ Are within first 12 months of AWS account

**Set a billing alarm!** (See PREFLIGHT.md)

## 📖 Recommended Reading Order

1. **PREFLIGHT.md** - Setup checklist
2. **README.md** - Main tutorial (do all 3 labs)
3. **cheatsheet.md** - Reference material

Or jump straight to the 5-minute demo above to see it in action first!

## 🤔 Common Questions

**Q: CloudFormation vs Terraform?**
A: Both are infrastructure-as-code tools. CloudFormation is AWS-only but deeply integrated. Terraform is multi-cloud. Tonight: focus on CloudFormation. Learn Terraform later if you need multi-cloud.

**Q: Do I need to know YAML?**
A: Basic YAML is easy! It's just key-value pairs with indentation. The templates are well-commented - you'll pick it up quickly.

**Q: What if I break something?**
A: CloudFormation makes it safe! Stacks are isolated. Deleting a stack removes everything. Hard to accidentally affect other resources.

**Q: Is this production-ready?**
A: The concepts are! But these templates are simplified for learning. Production needs: backups, monitoring, auto-scaling, multi-AZ, etc.

## 🆘 Getting Stuck?

**Template validation errors:**
```bash
aws cloudformation validate-template --template-body file://template.yaml
```

**Stack creation fails:**
- Check the Events tab in CloudFormation console
- Most common: IAM permissions or resource name conflicts

**Need help?**
- AWS CloudFormation docs: https://docs.aws.amazon.com/cloudformation/
- AWS re:Post (like Stack Overflow): https://repost.aws/

## 🎯 Success Criteria

By the end of tonight, you should be able to:
- ✅ Explain what CloudFormation is (infrastructure as code)
- ✅ Write a basic CloudFormation template
- ✅ Deploy and delete stacks via AWS Console
- ✅ Understand parameters, resources, and outputs
- ✅ Explain how Service Catalog adds governance
- ✅ Launch a product from Service Catalog

**Bonus points:**
- ✅ Use AWS CLI to deploy stacks
- ✅ Create your own custom template
- ✅ Set up a Service Catalog product from scratch

## 🚀 Ready to Start?

### Option A: Hands-On Learner
Go straight to **PREFLIGHT.md** → Complete checklist → Start **README.md Lab 1**

### Option B: Conceptual First
Read **README.md** "The Big Picture" section → Then do hands-on labs

### Option C: Jump In
Do the 5-minute demo above → Then go back and do full labs

---

**Remember:** The best way to learn is by doing. Don't just read - actually deploy the templates!

**Pro tip:** Keep the AWS Console open in one browser window, this guide in another. Switch between them as you work through labs.

---

## 📊 Time Breakdown

| Activity | Time | What You'll Do |
|----------|------|----------------|
| Pre-flight | 10 min | Setup AWS access, create key pair |
| Lab 1 | 15 min | Deploy S3 bucket with CloudFormation |
| Lab 2 | 15 min | Deploy web server with VPC |
| Lab 3 | 15 min | Set up Service Catalog |
| Exploration | 15 min | Try your own experiments |
| **Total** | **~1 hour** | **Complete AWS automation knowledge!** |

---

**Let's go! Open PREFLIGHT.md and start your AWS automation journey! 🚀**
