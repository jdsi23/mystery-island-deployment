variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID for us-east-1"
  default     = "ami-0c02fb55956c7d316"
}

variable "key_name" {
  description = "Name of your existing AWS key pair"
  type        = string
}

variable "s3_bucket_name" {
  description = "Unique name for your S3 bucket"
  type        = string
}
