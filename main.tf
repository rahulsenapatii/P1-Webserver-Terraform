terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Fetch existing Default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch existing subnets in Default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group - HTTP only
resource "aws_security_group" "web_sg" {
  name        = "rahul-p1-webserver-sg-v2"
  description = "Allow HTTP inbound traffic only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rahul-p1-webserver-sg-v2"
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# EC2 Web Server
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-USERDATA
              #!/bin/bash
              dnf update -y
              dnf install -y httpd

              systemctl enable httpd
              systemctl start httpd

              cat > /var/www/html/index.html <<HTML
              <html>
              <head>
                <title>Terraform Web Server</title>
              </head>
              <body>
                <h1>Deployed via Terraform</h1>
                <h2>Project 1 - Rahul Senapati</h2>
              </body>
              </html>
              HTML
              USERDATA

  tags = {
    Name = "rahul-p1-ec2-webserver"
  }
}
