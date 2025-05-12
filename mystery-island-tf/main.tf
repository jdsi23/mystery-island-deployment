terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Generate random ID for unique S3 bucket names
resource "random_id" "rand" {
  byte_length = 4
}

# VPC
resource "aws_vpc" "custom" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "mystery-vpc"
  }
}

# Subnet
resource "aws_subnet" "custom" {
  vpc_id            = aws_vpc.custom.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "mystery-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom.id

  tags = {
    Name = "mystery-gateway"
  }
}

# Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.custom.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "mystery-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.custom.id
  route_table_id = aws_route_table.rt.id
}

# Security Group: HTTP + SSH
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.custom.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
    Name = "web-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.custom.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git
              cd /home/ec2-user
              git clone https://github.com/jdsi23/mystery-island-navigation.git
              cd mystery-island-navigation
              chmod +x start.sh
              ./start.sh
              EOF

  tags = {
    Name = "MysteryIslandWebServer"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "mystery_bucket" {
  bucket = "mystery-bucket-island-${random_id.rand.hex}"

  tags = {
    Name        = "MysteryBucket"
    Environment = "dev"
  }

  depends_on = [random_id.rand]
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.mystery_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.mystery_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Policy for Least Privilege
resource "aws_iam_policy" "mystery_user_policy" {
  name        = "MysteryUserLeastPrivilege"
  description = "Minimal permissions for EC2 and S3 access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EC2InstanceManagement",
        Effect = "Allow",
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:AssociateAddress"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowSpecificS3BucketAccess",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::mystery-bucket-island-*",
          "arn:aws:s3:::mystery-bucket-island-*/*"
        ]
      }
    ]
  })
}

# IAM User Module (uses custom policy above)
module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"

  name                     = "mystery-user"
  force_destroy            = true
  pgp_key                  = "keybase:test"
  password_reset_required  = false

  policy_arns = [
    aws_iam_policy.mystery_user_policy.arn
  ]

  depends_on = [aws_iam_policy.mystery_user_policy]
}
