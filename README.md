# AWS for Beginners 2026 — Demo Walkthrough

Complete step-by-step instructions for every demo in the video. Every JSON, every CLI command, and every console click is here — no jumping between files.

---

## Prerequisites

Before starting any demo, complete these one-time setup steps.

### 1. Create a Free AWS Account

1. Go to **https://aws.amazon.com/free**
2. Click **Create a Free Account**
3. Enter email, password, account name
4. Provide a credit card (won't be charged — required for identity verification)
5. Choose **Free** Support Plan
6. Sign in at **https://console.aws.amazon.com**

> All demos in this guide use **Free Tier eligible** resources. Your cost will be $0 if you follow the instructions and clean up afterwards.

---

### 2. Secure Your Root Account (Do This First)

**Enable MFA on the root account:**

1. Sign in to AWS Console → Click your account name (top right) → **Security credentials**
2. Under **Multi-factor authentication (MFA)** → click **Assign MFA device**
3. Choose **Authenticator app** → scan the QR code with Google Authenticator or Authy
4. Enter two consecutive 6-digit codes → click **Add MFA**

**Create an IAM Admin user (never use root for daily tasks):**

1. In the search bar type `IAM` → click **IAM**
2. Left sidebar → **Users** → click **Create user**
3. Username: `admin` → check **Provide user access to the AWS Management Console** → Next
4. Select **Attach policies directly** → search for `AdministratorAccess` → check it → Next
5. Click **Create user**
6. **Copy the Console sign-in URL** shown on the success page
7. Click **Download .csv** to save the credentials
8. Sign out of root → sign in with your new IAM admin user

---

### 3. Install AWS CLI (for CLI-based demos)

**macOS / Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

**Windows:**
Download and run the MSI installer from: https://awscli.amazonaws.com/AWSCLIV2.msi

**Configure CLI with your IAM user credentials:**
```bash
aws configure
```
You will be prompted for:
```
AWS Access Key ID:     [paste from the .csv you downloaded]
AWS Secret Access Key: [paste from the .csv you downloaded]
Default region name:   us-east-1
Default output format: json
```

Verify it works:
```bash
aws sts get-caller-identity
```
Expected output:
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/admin"
}
```

---

## Demo 1 — IAM: Users, Groups, Roles & Policies

### 1a. Create an IAM User via Console

1. Go to **IAM** → **Users** → **Create user**
2. Username: `developer-1`
3. Check **Provide user access to the AWS Management Console**
4. Select **I want to create an IAM user**
5. Custom password: set one → uncheck "must change password" → Next
6. Select **Add user to group** → click **Create group**
7. Group name: `Developers`
8. Attach policy: search `AmazonS3ReadOnlyAccess` → check it → **Create user group**
9. Add `developer-1` to `Developers` → Next → **Create user**

### 1b. Create an Inline Policy (copy this JSON)

Use this to allow a user to list EC2 instances but nothing else:

1. Go to **IAM** → **Users** → click your user → **Add permissions** → **Create inline policy**
2. Click the **JSON** tab and paste:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEC2Describe",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeRegions"
      ],
      "Resource": "*"
    }
  ]
}
```

3. Click **Next** → Policy name: `EC2ReadOnly` → **Create policy**

### 1c. Create an S3 Access Role for EC2

> **How IAM Roles work:** An IAM Role has two parts:
> - **Trusted entity** — *who* is allowed to assume (use) this role. Here it's the EC2 service.
> - **Permissions policy** — *what* they can do once they assume it. Here it's read S3.
>
> So even though the goal is S3 access, you pick **EC2** as the trusted entity because EC2 is the service that will wear this role. Think of it as: "I'm creating a badge (role) that only EC2 staff can wear, and the badge grants S3 read access."

**Steps:**

1. Go to **IAM** → left sidebar → **Roles** → click **Create role**
2. **Trusted entity type:** AWS service
3. **Use case:** scroll down to find **EC2** → select it → click **Next**
4. In the search box type `AmazonS3ReadOnlyAccess` → check the box next to it → click **Next**
5. **Role name:** `EC2-S3-ReadOnly-Role`
6. Click **Create role**

**Verify it was created:**
- Go to **IAM** → **Roles** → search `EC2-S3-ReadOnly-Role` → click it
- Under **Trust relationships** you should see `ec2.amazonaws.com` — this confirms EC2 can assume it
- Under **Permissions** you should see `AmazonS3ReadOnlyAccess` — this is what EC2 can do with S3

You will attach this role to your EC2 instance in Demo 2 → Step 7.

---

## Demo 2 — EC2: Launch a Web Server

**File used:** `setup-ec2-webserver.sh`

### Step 1 — Open the EC2 Launch Wizard

1. In the AWS Console search bar type `EC2` → click **EC2**
2. Click the orange **Launch instance** button

### Step 2 — Name Your Instance

- Name: `my-web-server-2026`

### Step 3 — Choose an AMI

- Under **Application and OS Images** → confirm **Amazon Linux** is selected
- Choose: **Amazon Linux 2023 AMI** (says "Free tier eligible" next to it)

### Step 4 — Choose Instance Type

- Instance type: **t2.micro** (look for the "Free tier eligible" badge)
- 1 vCPU, 1 GiB RAM — plenty for a demo web server

### Step 5 — Create a Key Pair

> You need this to SSH into your instance. Only created once per key.

1. Click **Create new key pair**
2. Key pair name: `my-aws-key`
3. Key pair type: **RSA**
4. Private key file format: **.pem** (Mac/Linux) or **.ppk** (Windows/PuTTY)
5. Click **Create key pair** — the `.pem` file downloads automatically
6. **Save this file somewhere safe. You cannot re-download it.**

```bash
# On Mac/Linux — fix permissions so SSH accepts it
chmod 400 ~/Downloads/my-aws-key.pem
```

### Step 6 — Configure Security Group (Firewall)

1. Under **Network settings** → click **Edit**
2. You should see SSH (port 22) already listed — change **Source type** to **My IP**
3. Click **Add security group rule**:
   - Type: `HTTP`
   - Port: `80`
   - Source type: `Anywhere`  ← allows the world to see your website

### Step 7 — Attach IAM Role (optional but recommended)

1. Expand **Advanced details**
2. IAM instance profile → select `EC2-S3-ReadOnly-Role` (created in Demo 1c)

### Step 8 — Add User Data Script

Still in **Advanced details**, scroll down to **User data** — paste the entire script below:

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from AWS EC2 — 2026!</h1>" > /var/www/html/index.html
```

> This exact content is also in `setup-ec2-webserver.sh` — the version in that file is more advanced and displays your real Instance ID, Region, and IP on the page.

### Step 9 — Launch

1. Review the **Summary** on the right — confirm instance type is t2.micro
2. Click **Launch instance**
3. Click **View all instances**

### Step 10 — Access Your Website

1. Wait ~60 seconds for the instance to show **Running** state
2. Click your instance → copy the **Public IPv4 address** (e.g. `54.210.83.12`)
3. Open a new browser tab and visit: `http://54.210.83.12`

You should see: **Hello from AWS EC2 — 2026!**

### Step 11 — SSH Into Your Instance (optional)

```bash
# Replace with your actual .pem path and EC2 public IP
ssh -i ~/Downloads/my-aws-key.pem ec2-user@54.210.83.12
```

### Cleanup — Terminate the Instance

> Always terminate demo instances to avoid charges after the Free Tier 750hr/month limit.

1. EC2 → Instances → check your instance
2. **Instance state** → **Terminate instance** → confirm

---

## Demo 3 — S3: Host a Static Website

**Files used:**
- `s3-bucket-policy.json` — copy the JSON from here
- `s3-demo.py` — run this script to automate everything

### Option A — AWS Console (step by step)

#### Step 1 — Create a Bucket

1. In the search bar type `S3` → click **S3**
2. Click **Create bucket**
3. Bucket name: `my-website-2026-yourname` *(must be globally unique — add your name or random suffix)*
4. AWS Region: **US East (N. Virginia) us-east-1**
5. **Uncheck** "Block all public access" → check the acknowledgement checkbox that appears
6. Leave everything else as default → click **Create bucket**

#### Step 2 — Enable Static Website Hosting

1. Click your new bucket → go to the **Properties** tab
2. Scroll to the bottom → **Static website hosting** → click **Edit**
3. Select **Enable**
4. Index document: `index.html`
5. Error document: `error.html`
6. Click **Save changes**
7. Scroll back down to **Static website hosting** — copy the **Bucket website endpoint** URL (looks like `http://my-website-2026-yourname.s3-website-us-east-1.amazonaws.com`) — save this for Step 5.

#### Step 3 — Apply the Bucket Policy

1. Click the **Permissions** tab
2. Scroll to **Bucket policy** → click **Edit**
3. Copy the JSON below and paste it — **replace `YOUR-BUCKET-NAME` with your actual bucket name:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

> **Example:** If your bucket is named `my-website-2026-john`, the Resource line becomes:
> `"Resource": "arn:aws:s3:::my-website-2026-john/*"`

4. Click **Save changes**

#### Step 4 — Upload Your Website Files

1. Click the **Objects** tab → click **Upload**
2. Click **Add files**
3. Create a file on your computer called `index.html` with this content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>My AWS S3 Website</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #131A22; color: #fff;
           display: flex; align-items: center; justify-content: center; min-height: 100vh; }
    .card { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,153,0,0.3);
            border-radius: 16px; padding: 40px; text-align: center; max-width: 500px; }
    h1 { color: #FF9900; font-size: 2.2rem; }
    p { color: #aaa; margin-top: 10px; }
    .badge { display: inline-block; background: #FF9900; color: #000;
             font-weight: 900; padding: 4px 18px; border-radius: 20px; margin-top: 18px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>☁️ Hello from S3!</h1>
    <p>This static website is hosted on Amazon S3.</p>
    <p>No servers. No EC2. Just files in a bucket.</p>
    <div class="badge">AWS for Beginners 2026</div>
  </div>
</body>
</html>
```

4. Select that file in the Upload dialog → click **Upload**

#### Step 5 — View Your Website

Open the bucket website endpoint URL you copied in Step 2. Your website is live!

`http://my-website-2026-yourname.s3-website-us-east-1.amazonaws.com`

---

### Option B — AWS CLI (faster, 3 commands)

```bash
# 1. Create the bucket (replace YOUR-BUCKET-NAME with something unique)
aws s3 mb s3://YOUR-BUCKET-NAME --region us-east-1

# 2. Upload your index.html
aws s3 cp index.html s3://YOUR-BUCKET-NAME/index.html

# 3. Sync an entire folder (if you have a local website folder)
aws s3 sync ./website/ s3://YOUR-BUCKET-NAME/
```

Apply the bucket policy via CLI — save `s3-bucket-policy.json`, replace the bucket name inside it, then run:

```bash
aws s3api put-bucket-policy \
  --bucket YOUR-BUCKET-NAME \
  --policy file://s3-bucket-policy.json
```

Enable static website hosting via CLI:

```bash
aws s3 website s3://YOUR-BUCKET-NAME \
  --index-document index.html \
  --error-document error.html
```

---

### Option C — Automated Python Script

Runs all steps automatically (creates bucket, uploads site, sets policy, enables hosting):

```bash
pip install boto3
python s3-demo.py
```

The script auto-generates a unique bucket name and prints the live website URL at the end.

### Cleanup — Delete the Bucket

```bash
# Delete all objects first, then the bucket
aws s3 rm s3://YOUR-BUCKET-NAME --recursive
aws s3 rb s3://YOUR-BUCKET-NAME
```

Or in the console: S3 → select bucket → **Empty** → then **Delete**.

---

## Demo 4 — Lambda: Deploy a Hello World API

**File used:** `lambda-hello-api.py`

### Option A — AWS Console

#### Step 1 — Create the Function

1. Search for `Lambda` → click **Lambda**
2. Click **Create function**
3. Select **Author from scratch**
4. Function name: `hello-api-2026`
5. Runtime: **Python 3.12**
6. Architecture: **x86_64**
7. Expand **Change default execution role** → select **Create a new role with basic Lambda permissions**
8. Click **Create function**

#### Step 2 — Paste the Code

1. In the **Code source** editor, click on `lambda_function.py`
2. Select all (Ctrl+A / Cmd+A) and delete everything
3. Copy the entire contents of `lambda-hello-api.py` from this repo and paste it
4. Click **Deploy** (orange button)

#### Step 3 — Test the Function

1. Click the **Test** tab
2. Click **Create new event**
3. Event name: `TestGreet`
4. Paste this JSON in the Event JSON box:

```json
{
  "name": "AWS Learner",
  "action": "greet"
}
```

5. Click **Save** → then click **Test**

Expected response:
```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  },
  "body": "{\n  \"message\": \"👋 Hello, AWS Learner! Welcome to AWS Lambda — 2026!\",\n  \"timestamp\": \"2026-03-15T10:00:00+00:00\",\n  \"service\": \"AWS Lambda\",\n  \"runtime\": \"Python 3.12\"\n}"
}
```

#### Step 4 — Test the Info Action

Click **Test** → change the Event JSON to:

```json
{
  "action": "info"
}
```

This returns Lambda runtime details: function name, memory limit, region, remaining execution time.

### Option B — AWS CLI

```bash
# 1. Zip the function file
zip lambda.zip lambda-hello-api.py

# 2. Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 3. Create IAM execution role for Lambda
aws iam create-role \
  --role-name lambda-basic-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# 4. Attach basic execution policy (allows CloudWatch Logs)
aws iam attach-role-policy \
  --role-name lambda-basic-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Wait 10 seconds for the role to propagate
sleep 10

# 5. Create the Lambda function
aws lambda create-function \
  --function-name hello-api-2026 \
  --runtime python3.12 \
  --handler lambda-hello-api.lambda_handler \
  --role arn:aws:iam::${ACCOUNT_ID}:role/lambda-basic-role \
  --zip-file fileb://lambda.zip

# 6. Invoke it
aws lambda invoke \
  --function-name hello-api-2026 \
  --payload '{"name":"AWS Learner","action":"greet"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json
```

#### Step 5 — Add API Gateway (expose as HTTP endpoint)

1. In the Lambda console → click your function → **Add trigger**
2. Select **API Gateway**
3. Create a **new** API → type: **HTTP API**
4. Security: **Open**
5. Click **Add**
6. Click the newly created API Gateway trigger → copy the **API endpoint** URL
7. Open the URL in your browser — you'll get the Lambda JSON response

Your Lambda is now a live public API endpoint.

### Option C — Run Locally (no AWS needed)

```bash
pip install boto3
python lambda-hello-api.py
```

This simulates two invocations using the `FakeContext` class at the bottom of the file.

### Cleanup — Delete Lambda Function

```bash
aws lambda delete-function --function-name hello-api-2026
```

---

## Demo 5 — Terraform: Full Infrastructure as Code

**Files used:** `terraform/main.tf`, `terraform/variables.tf`, `terraform/outputs.tf`, `terraform/userdata.sh`

Provisions: VPC + public/private subnets + Internet Gateway + Security Group + EC2 with Elastic IP + S3 bucket.

### Prerequisites

Install Terraform: https://developer.hashicorp.com/terraform/install

Verify:
```bash
terraform -v
# Terraform v1.7.x
```

### Step 1 — Create a `terraform.tfvars` File

Create `demo/terraform/terraform.tfvars` and paste:

```hcl
aws_region          = "us-east-1"
project_name        = "aws-beginners-2026"
environment         = "demo"
instance_type       = "t2.micro"
key_pair_name       = "my-aws-key"
my_ip               = "YOUR.PUBLIC.IP.HERE/32"
```

> To find your public IP: https://checkip.amazonaws.com — add `/32` at the end.
> `key_pair_name` must match an existing Key Pair in your AWS account (created in EC2 Demo Step 5).

### Step 2 — Initialize Terraform

```bash
cd demo/terraform
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 3 — Preview What Will Be Created

```bash
terraform plan
```

Review the list of resources — you should see ~12 resources to be created (VPC, subnets, IGW, route table, security group, IAM role, EC2, S3, etc.)

### Step 4 — Apply (Deploy Everything)

```bash
terraform apply
```

Type `yes` when prompted. Wait ~2 minutes.

### Step 5 — See Outputs

When complete, Terraform prints:

```
Outputs:

ec2_public_ip  = "54.210.83.12"
website_url    = "http://54.210.83.12"
s3_bucket_name = "aws-beginners-2026-website-123456789012"
s3_website_url = "http://aws-beginners-2026-website-....s3-website-us-east-1.amazonaws.com"
instance_id    = "i-0abc123def456"
ssh_command    = "ssh -i ~/.ssh/my-aws-key.pem ec2-user@54.210.83.12"
vpc_id         = "vpc-0abc123..."
```

Open `website_url` in your browser — your EC2 web server is live.

### Step 6 — SSH Into the Server

```bash
# Use the ssh_command from the terraform output
ssh -i ~/.ssh/my-aws-key.pem ec2-user@54.210.83.12
```

### Cleanup — Destroy All Resources

```bash
terraform destroy
```

Type `yes`. This deletes every resource Terraform created — zero lingering charges.

---

## Quick Reference — Copy-Paste Snippets

### S3 Bucket Policy — Public Read

Replace `YOUR-BUCKET-NAME` before using.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

This file is also saved as: `s3-bucket-policy.json`

---

### IAM Policy — Allow S3 Read Only for Specific Bucket

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadSpecificBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME",
        "arn:aws:s3:::YOUR-BUCKET-NAME/*"
      ]
    }
  ]
}
```

---

### EC2 User Data — Apache Web Server (paste into Launch Wizard)

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from AWS EC2 — 2026!</h1>" > /var/www/html/index.html
```

Full version (shows instance metadata): `setup-ec2-webserver.sh`

---

### Lambda Test Event — Greet Action

Paste into the Lambda console Test tab:

```json
{
  "name": "Your Name Here",
  "action": "greet"
}
```

---

### Lambda Test Event — Info Action

```json
{
  "action": "info"
}
```

---

### CloudWatch Alarm — High CPU (CLI)

Replace `YOUR-INSTANCE-ID` and `YOUR-SNS-TOPIC-ARN`:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "HighCPU-WebServer" \
  --alarm-description "Alert when CPU exceeds 80% for 10 min" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --dimensions Name=InstanceId,Value=YOUR-INSTANCE-ID \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions YOUR-SNS-TOPIC-ARN \
  --treat-missing-data notBreaching
```

---

## File Structure

```
demo/
├── README.md                   ← You are here
├── setup-ec2-webserver.sh      ← Paste into EC2 User Data (advanced version)
├── s3-demo.py                  ← Automated S3 demo (Python + boto3)
├── s3-bucket-policy.json       ← Public read bucket policy — copy this JSON
├── lambda-hello-api.py         ← Lambda function code — paste into console
└── terraform/
    ├── main.tf                 ← All AWS resources (VPC, EC2, S3, IAM)
    ├── variables.tf            ← Config variables
    ├── outputs.tf              ← Outputs: IPs, URLs, SSH command
    ├── userdata.sh             ← EC2 startup script (Terraform-templated)
    └── terraform.tfvars        ← YOUR values go here (create this file)
```

---

## Cleanup Checklist

After the video, avoid surprise charges by deleting these resources:

- [ ] EC2 instances → **Terminate**
- [ ] Elastic IPs → **Release** (charged even when not attached)
- [ ] S3 buckets → **Empty** then **Delete**
- [ ] RDS instances → **Delete** (uncheck final snapshot for demos)
- [ ] Lambda functions → **Delete**
- [ ] API Gateways → **Delete**
- [ ] NAT Gateways → **Delete** (these cost ~$0.045/hr even when idle)
- [ ] Terraform resources → `terraform destroy`

Check your billing at: **AWS Console → Billing → Bills**
Set a billing alert: **Billing → Budgets → Create budget** → alert at $1 to catch anything unexpected.
