# Pre-Flight Checklist ✈️

Complete these steps before starting the labs (5-10 minutes):

## ✅ Step 1: AWS Account Access

- [ ] Log in to AWS Console: https://console.aws.amazon.com/
- [ ] Confirm you're on **Free Tier** (check billing dashboard)
- [ ] Note your default region (top-right, e.g., "us-east-1")

## ✅ Step 2: Create EC2 Key Pair (for Lab 2)

**Why?** You need this to SSH into EC2 instances.

1. Go to: https://console.aws.amazon.com/ec2/
2. Left menu → **Network & Security** → **Key Pairs**
3. Click **Create key pair**
   - Name: `my-lab-key`
   - Key pair type: `RSA`
   - File format: `pem` (for Mac/Linux) or `ppk` (for Windows/PuTTY)
4. Download the `.pem` file and save it somewhere safe

**For Mac/Linux users:**
```bash
chmod 400 ~/Downloads/my-lab-key.pem
```

## ✅ Step 3: Install AWS CLI (Optional, for bonus commands)

**Check if already installed:**
```bash
aws --version
```

**If not installed:**
- Windows: https://awscli.amazonaws.com/AWSCLIV2.msi
- Mac: `brew install awscli`
- Linux: `sudo apt install awscli` or `sudo yum install awscli`

**Configure credentials:**
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Default region (e.g., us-east-1), Output format (json)
```

Get credentials from: https://console.aws.amazon.com/iam/home#/security_credentials

## ✅ Step 4: Understand Costs (Important!)

**All labs use FREE TIER resources, but only if:**
- ✅ You're within the first 12 months of your AWS account
- ✅ You **delete stacks immediately after testing**
- ✅ You don't leave resources running overnight

**Free Tier Limits:**
- EC2: 750 hours/month of `t2.micro` or `t3.micro`
- S3: 5GB storage, 20,000 GET requests, 2,000 PUT requests
- RDS: 750 hours/month of `db.t2.micro` or `db.t3.micro`, 20GB storage

**Cost Safeguard:**
Set up a billing alarm:
1. Go to: https://console.aws.amazon.com/billing/
2. Left menu → **Budgets** → **Create budget**
3. Choose **Zero spend budget** (alerts if you exceed free tier)

## ✅ Step 5: Browser Check

Use Chrome, Firefox, or Edge for best AWS Console experience. Safari sometimes has issues.

## ✅ Step 6: Open Files in This Folder

You'll need to reference:
- `README.md` - Main guide (follow Lab 1 → Lab 2 → Lab 3)
- `lab1-simple-s3.yaml` - Template for Lab 1
- `lab2-ec2-with-vpc.yaml` - Template for Lab 2
- `cheatsheet.md` - Quick reference (keep open in another window)

**Tip:** Open `README.md` in a markdown viewer or browser for better formatting.

## ✅ You're Ready! 🚀

**Start here:** Open `README.md` and begin with **Lab 1** (15 minutes).

**Estimated timeline:**
- ⏰ Lab 1: 15 minutes
- ⏰ Lab 2: 15 minutes
- ⏰ Lab 3: 15 minutes
- **Total: ~45 minutes** (plus time for exploration!)

---

## 🆘 Need Help?

**CloudFormation stuck?**
- Check the **Events** tab in CloudFormation console for error messages
- Most common issue: Forgot to create EC2 key pair (Step 2 above)

**IAM permission errors?**
- Your AWS user needs `CloudFormation` and `EC2` permissions
- If using AWS Organizations, check SCPs (Service Control Policies)

**Template upload fails?**
- Check file size (max 51,200 bytes for direct upload)
- For larger templates, upload to S3 first and reference the S3 URL

**Free Tier concerns?**
- Use the AWS Free Tier Usage dashboard: https://console.aws.amazon.com/billing/home#/freetier
- Set up billing alerts immediately!

---

**Remember:** Delete all stacks after you're done exploring! 🗑️

Select stack → **Delete** → Confirm

This ensures you don't get any surprise charges.

---

## 📖 After the Labs

Once you complete all labs, you'll understand:
1. ✅ How to define AWS infrastructure as code (CloudFormation)
2. ✅ How to create reusable templates with parameters
3. ✅ How CloudFormation manages dependencies automatically
4. ✅ How Service Catalog provides governance and self-service
5. ✅ The difference between direct CloudFormation vs. Service Catalog

**Next steps:**
- Build your own template for a real project
- Explore AWS CDK (define infrastructure using Python/TypeScript)
- Learn Terraform (multi-cloud IaC alternative)
- Implement CI/CD pipelines that deploy CloudFormation stacks

Good luck! 🍀
