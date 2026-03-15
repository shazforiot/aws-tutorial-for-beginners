"""
AWS for Beginners 2026 — S3 Demo Script
========================================
Demonstrates: Bucket creation, file upload, static website hosting,
presigned URLs, and bucket policy management using boto3 (AWS SDK for Python).

Prerequisites:
  pip install boto3
  aws configure   # set Access Key, Secret Key, Region

Usage:
  python s3-demo.py
"""

import boto3
import json
import os
import uuid
from botocore.exceptions import ClientError

# ── Config ────────────────────────────────────────────────────────────────────
REGION = "us-east-1"
BUCKET_NAME = f"aws-beginners-demo-{uuid.uuid4().hex[:8]}"  # unique bucket name

# ── Initialize S3 client ──────────────────────────────────────────────────────
s3 = boto3.client("s3", region_name=REGION)

# ═══════════════════════════════════════════════════════════════════════════════
def create_bucket(bucket_name: str) -> bool:
    """Create an S3 bucket in the specified region."""
    print(f"\n[1] Creating S3 bucket: {bucket_name}")
    try:
        if REGION == "us-east-1":
            # us-east-1 does not accept LocationConstraint
            s3.create_bucket(Bucket=bucket_name)
        else:
            s3.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={"LocationConstraint": REGION},
            )
        print(f"    ✅ Bucket created: s3://{bucket_name}")
        return True
    except ClientError as e:
        print(f"    ❌ Error: {e}")
        return False


# ═══════════════════════════════════════════════════════════════════════════════
def upload_file(bucket_name: str, file_path: str, object_key: str) -> bool:
    """Upload a local file to S3."""
    print(f"\n[2] Uploading file: {file_path} → s3://{bucket_name}/{object_key}")
    try:
        s3.upload_file(file_path, bucket_name, object_key)
        print(f"    ✅ File uploaded successfully")
        return True
    except ClientError as e:
        print(f"    ❌ Upload failed: {e}")
        return False


# ═══════════════════════════════════════════════════════════════════════════════
def upload_html_content(bucket_name: str) -> bool:
    """Upload a sample index.html directly from string content."""
    print(f"\n[2b] Uploading HTML website content...")
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>My AWS S3 Website — 2026</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #131A22; color: #fff;
           display: flex; align-items: center; justify-content: center; min-height: 100vh; }
    .card { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,153,0,0.3);
            border-radius: 16px; padding: 40px; text-align: center; max-width: 500px; }
    h1 { color: #FF9900; font-size: 2rem; }
    p { color: #aaa; margin-top: 10px; }
    .badge { display: inline-block; background: #FF9900; color: #000;
             font-weight: 900; padding: 4px 16px; border-radius: 20px; margin-top: 16px; }
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
</html>"""

    try:
        s3.put_object(
            Bucket=bucket_name,
            Key="index.html",
            Body=html_content.encode("utf-8"),
            ContentType="text/html",
        )
        print(f"    ✅ index.html uploaded")
        return True
    except ClientError as e:
        print(f"    ❌ Upload failed: {e}")
        return False


# ═══════════════════════════════════════════════════════════════════════════════
def disable_block_public_access(bucket_name: str) -> None:
    """Disable S3 Block Public Access (required for public website)."""
    print(f"\n[3] Disabling Block Public Access...")
    s3.put_public_access_block(
        Bucket=bucket_name,
        PublicAccessBlockConfiguration={
            "BlockPublicAcls": False,
            "IgnorePublicAcls": False,
            "BlockPublicPolicy": False,
            "RestrictPublicBuckets": False,
        },
    )
    print("    ✅ Public access unblocked")


# ═══════════════════════════════════════════════════════════════════════════════
def set_public_read_policy(bucket_name: str) -> None:
    """Apply a bucket policy to allow public GET requests."""
    print(f"\n[4] Setting public read bucket policy...")
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": f"arn:aws:s3:::{bucket_name}/*",
            }
        ],
    }
    s3.put_bucket_policy(Bucket=bucket_name, Policy=json.dumps(policy))
    print("    ✅ Bucket policy applied — public read enabled")


# ═══════════════════════════════════════════════════════════════════════════════
def enable_static_website(bucket_name: str) -> str:
    """Enable static website hosting and return the website URL."""
    print(f"\n[5] Enabling static website hosting...")
    s3.put_bucket_website(
        Bucket=bucket_name,
        WebsiteConfiguration={
            "IndexDocument": {"Suffix": "index.html"},
            "ErrorDocument": {"Key": "error.html"},
        },
    )
    website_url = f"http://{bucket_name}.s3-website-{REGION}.amazonaws.com"
    print(f"    ✅ Website enabled")
    print(f"    🌐 URL: {website_url}")
    return website_url


# ═══════════════════════════════════════════════════════════════════════════════
def generate_presigned_url(bucket_name: str, object_key: str, expiry_seconds: int = 3600) -> str:
    """Generate a pre-signed URL for temporary private access (no public policy needed)."""
    print(f"\n[6] Generating pre-signed URL (expires in {expiry_seconds}s)...")
    url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket_name, "Key": object_key},
        ExpiresIn=expiry_seconds,
    )
    print(f"    ✅ Pre-signed URL: {url[:80]}...")
    return url


# ═══════════════════════════════════════════════════════════════════════════════
def list_objects(bucket_name: str) -> None:
    """List all objects in the bucket."""
    print(f"\n[7] Listing objects in s3://{bucket_name}:")
    response = s3.list_objects_v2(Bucket=bucket_name)
    objects = response.get("Contents", [])
    if not objects:
        print("    (empty bucket)")
    for obj in objects:
        size_kb = obj["Size"] / 1024
        print(f"    📄 {obj['Key']} ({size_kb:.1f} KB) — {obj['LastModified'].strftime('%Y-%m-%d %H:%M')}")


# ═══════════════════════════════════════════════════════════════════════════════
def cleanup(bucket_name: str) -> None:
    """Delete all objects and then the bucket (cleanup demo resources)."""
    print(f"\n[8] Cleaning up — deleting bucket {bucket_name}...")
    # Delete all objects first
    response = s3.list_objects_v2(Bucket=bucket_name)
    objects = response.get("Contents", [])
    if objects:
        s3.delete_objects(
            Bucket=bucket_name,
            Delete={"Objects": [{"Key": obj["Key"]} for obj in objects]},
        )
    s3.delete_bucket(Bucket=bucket_name)
    print(f"    ✅ Bucket {bucket_name} deleted")


# ═══════════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    print("=" * 60)
    print(" AWS S3 Demo — Beginners 2026")
    print("=" * 60)

    # Step 1: Create bucket
    if not create_bucket(BUCKET_NAME):
        exit(1)

    # Step 2: Upload HTML website
    upload_html_content(BUCKET_NAME)

    # Step 3: Make it publicly readable
    disable_block_public_access(BUCKET_NAME)
    set_public_read_policy(BUCKET_NAME)

    # Step 4: Enable static website hosting
    website_url = enable_static_website(BUCKET_NAME)

    # Step 5: Generate a presigned URL (useful for private buckets)
    generate_presigned_url(BUCKET_NAME, "index.html", expiry_seconds=300)

    # Step 6: List objects
    list_objects(BUCKET_NAME)

    print("\n" + "=" * 60)
    print(f" ✅ Demo complete!")
    print(f" 🌐 Website URL: {website_url}")
    print(f" ⏳ Note: DNS propagation may take 1-2 minutes")
    print("=" * 60)

    # Optionally clean up — comment out to keep the bucket
    input("\nPress Enter to delete demo resources (or Ctrl+C to keep them)...")
    cleanup(BUCKET_NAME)
