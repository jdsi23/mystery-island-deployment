provider "aws" {
  region = "us-east-1"
}

# Generate random suffix for globally unique S3 bucket name
resource "random_id" "bucket_id" {
  byte_length = 4
}

# Get latest Ubuntu 20.04 AMI for us-east-1
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Custom VPC
resource "aws_vpc" "mystery_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "mystery-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "mystery_subnet" {
  vpc_id                  = aws_vpc.mystery_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mystery-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mystery_vpc.id

  tags = {
    Name = "mystery-igw"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.mystery_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "mystery-public-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.mystery_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group (HTTP + SSH)
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_vpc.mystery_vpc.id

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP_HERE/32"]  # Replace with your IP
  }

  ingress {
    description = "HTTP Access"
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
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.mystery_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
}
