#!/bin/bash
# EC2 User Data — runs on first boot
# Templated by Terraform — ${project_name} is substituted

yum update -y
yum install -y httpd

systemctl start httpd
systemctl enable httpd

cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${project_name} — Terraform Deployed</title>
  <style>
    body { font-family: system-ui; background: #131A22; color: #fff;
           display: flex; align-items: center; justify-content: center; min-height: 100vh; }
    .box { background: rgba(255,255,255,0.06); border: 1px solid rgba(255,153,0,0.3);
           border-radius: 16px; padding: 40px; text-align: center; }
    h1 { color: #FF9900; }
    .tag { background: #FF9900; color: #000; font-weight: 900;
           padding: 4px 16px; border-radius: 20px; display: inline-block; margin-top: 12px; }
  </style>
</head>
<body>
  <div class="box">
    <h1>☁️ Deployed via Terraform!</h1>
    <p>Project: ${project_name}</p>
    <p>Infrastructure as Code — 2026</p>
    <div class="tag">AWS + Terraform</div>
  </div>
</body>
</html>
HTMLEOF
