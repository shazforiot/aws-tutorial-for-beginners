output "ec2_public_ip" {
  description = "Public IP of the EC2 web server (static Elastic IP)"
  value       = aws_eip.web_server.public_ip
}

output "website_url" {
  description = "URL to access the EC2 web server"
  value       = "http://${aws_eip.web_server.public_ip}"
}

output "s3_website_url" {
  description = "S3 static website URL"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.web_server.id
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_eip.web_server.public_ip}"
}
