variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "aws-beginners-2026"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is Free Tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 Key Pair for SSH access"
  type        = string
  default     = ""  # Set in terraform.tfvars
}

variable "my_ip" {
  description = "Your public IP address for SSH access (format: x.x.x.x/32)"
  type        = string
  default     = "0.0.0.0/0"  # Restrict this to your IP in production!
}
