# ============================================================
# AWS for Beginners 2026 — Terraform Infrastructure Demo
# Provisions: VPC + EC2 + S3 + Security Group
#
# Prerequisites:
#   1. Install Terraform: https://developer.hashicorp.com/terraform/install
#   2. Install AWS CLI and run: aws configure
#   3. Run:
#        terraform init
#        terraform plan
#        terraform apply
#   4. To destroy: terraform destroy
# ============================================================

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────────────────────────
# DATA SOURCES
# ──────────────────────────────────────────────────────────────

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current caller identity (for outputs)
data "aws_caller_identity" "current" {}

# ──────────────────────────────────────────────────────────────
# VPC — VIRTUAL PRIVATE CLOUD
# ──────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Internet Gateway — connects VPC to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# Public Subnet — for EC2 web server
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-subnet"
    Type = "public"
  })
}

# Private Subnet — for databases (not used in this demo but good practice)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-subnet"
    Type = "private"
  })
}

# Route Table — directs traffic from public subnet to internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# Associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ──────────────────────────────────────────────────────────────
# SECURITY GROUP — EC2 Firewall
# ──────────────────────────────────────────────────────────────

resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  # HTTP — allow from anywhere (web traffic)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  # HTTPS — allow from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  # SSH — restrict to your IP (update var.my_ip in terraform.tfvars)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "SSH from my IP only"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-sg"
  })
}

# ──────────────────────────────────────────────────────────────
# IAM ROLE — EC2 Instance Profile (to access S3)
# ──────────────────────────────────────────────────────────────

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

# Attach S3 read-only policy to EC2 role
resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile — attaches IAM role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ──────────────────────────────────────────────────────────────
# EC2 INSTANCE — Web Server
# ──────────────────────────────────────────────────────────────

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name  # Must exist in your AWS account

  # User data script — runs on first boot
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    project_name = var.project_name
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-server"
  })
}

# Elastic IP — static public IP for EC2
resource "aws_eip" "web_server" {
  instance = aws_instance.web_server.id
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# ──────────────────────────────────────────────────────────────
# S3 BUCKET — Static Assets / Website
# ──────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-website-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, {
    Name    = "${var.project_name}-website"
    Purpose = "static-website"
  })
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  index_document { suffix = "index.html" }
  error_document { key    = "error.html" }
}

# ──────────────────────────────────────────────────────────────
# LOCALS
# ──────────────────────────────────────────────────────────────

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Year        = "2026"
  }
}
