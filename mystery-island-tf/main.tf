provider "aws" {
  region = "us-east-1"
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

# Associate Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.custom.id
  route_table_id = aws_route_table.rt.id
}

# Security Group (open SSH + HTTP)
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.custom.id

  ingress {
    description = "SSH access (sandbox safe)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Sandbox-safe, but wide open
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
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2, us-east-1
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.custom.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "MysteryIslandWebServer"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "mystery_bucket" {
  bucket = "mystery-bucket-island-${random_id.rand.hex}" # Ensures uniqueness

  tags = {
    Name        = "MysteryBucket"
    Environment = "dev"
  }
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.mystery_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Generate random ID for unique bucket names (required)
resource "random_id" "rand" {
  byte_length = 4
}
