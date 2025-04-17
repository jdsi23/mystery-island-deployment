variable "ami_id" {
  description = "ami-0c55b159cbfafe1f0"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}
