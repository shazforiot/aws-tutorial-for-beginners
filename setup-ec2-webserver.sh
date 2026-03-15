#!/bin/bash
# ============================================================
# AWS for Beginners 2026 — EC2 Web Server Demo Setup Script
# Run this as EC2 User Data (Advanced Details → User Data)
# OR SSH into your instance and run: bash setup-ec2-webserver.sh
# ============================================================

set -e  # Exit immediately if a command fails

echo "============================================="
echo " AWS EC2 Web Server Setup — 2026 Edition    "
echo "============================================="

# Update system packages
echo "[1/5] Updating system packages..."
yum update -y

# Install Apache web server
echo "[2/5] Installing Apache HTTP server..."
yum install -y httpd

# Start and enable Apache (auto-start on reboot)
echo "[3/5] Starting Apache service..."
systemctl start httpd
systemctl enable httpd

# Get instance metadata (available from within EC2)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "unknown")
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "unknown")
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "unknown")

# Write a styled HTML homepage
echo "[4/5] Creating homepage..."
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My AWS Server — 2026</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: linear-gradient(135deg, #131A22, #232F3E);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
    }
    .container {
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,153,0,0.3);
      border-radius: 20px;
      padding: 48px 56px;
      max-width: 680px;
      width: 90%;
      text-align: center;
    }
    .aws-badge {
      display: inline-block;
      background: #FF9900;
      color: #000;
      font-weight: 900;
      font-size: 0.9rem;
      padding: 6px 20px;
      border-radius: 20px;
      margin-bottom: 20px;
      letter-spacing: 2px;
    }
    h1 { font-size: 2.4rem; font-weight: 900; margin-bottom: 8px; }
    h1 span { color: #FF9900; }
    .subtitle { color: #aaa; font-size: 1rem; margin-bottom: 32px; }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
      margin-top: 24px;
      text-align: left;
    }
    .info-card {
      background: rgba(255,255,255,0.05);
      border-radius: 10px;
      padding: 14px 18px;
      border: 1px solid rgba(255,255,255,0.08);
    }
    .info-card .key { color: #FF9900; font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; }
    .info-card .val { color: #ddd; font-size: 0.9rem; margin-top: 4px; font-family: monospace; }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(124,179,66,0.15);
      border: 1px solid rgba(124,179,66,0.4);
      color: #7CB342;
      font-weight: 700;
      padding: 8px 20px;
      border-radius: 20px;
      margin-top: 28px;
      font-size: 0.9rem;
    }
    .dot { width: 8px; height: 8px; background: #7CB342; border-radius: 50%; animation: pulse 1.5s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
    .footer { margin-top: 28px; color: #555; font-size: 0.8rem; }
  </style>
</head>
<body>
  <div class="container">
    <div class="aws-badge">☁️ AWS EC2</div>
    <h1>Hello from <span>AWS!</span></h1>
    <p class="subtitle">Your EC2 web server is running — 2026 Edition</p>
    <div class="status-badge">
      <div class="dot"></div>
      Server Online &amp; Healthy
    </div>
    <div class="info-grid">
      <div class="info-card">
        <div class="key">Instance ID</div>
        <div class="val">$INSTANCE_ID</div>
      </div>
      <div class="info-card">
        <div class="key">Region</div>
        <div class="val">$REGION</div>
      </div>
      <div class="info-card">
        <div class="key">Public IP</div>
        <div class="val">$PUBLIC_IP</div>
      </div>
      <div class="info-card">
        <div class="key">Availability Zone</div>
        <div class="val">$AZ</div>
      </div>
    </div>
    <p class="footer">Deployed with AWS EC2 + Apache · AWS for Beginners 2026</p>
  </div>
</body>
</html>
EOF

# Set correct permissions
echo "[5/5] Setting file permissions..."
chown apache:apache /var/www/html/index.html
chmod 644 /var/www/html/index.html

echo ""
echo "============================================="
echo " ✅ Setup complete! Your web server is live."
echo " Visit your EC2 Public IP in a browser."
echo "============================================="
