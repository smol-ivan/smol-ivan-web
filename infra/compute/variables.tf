variable "project_name" {
  type        = string
  description = "Project name used as a prefix for resource names"
}

variable "ami_id" {
  type        = string
  description = "Pin the instance to a specific AMI ID. If null, falls back to the most recent Debian 13 AMI (only safe for brand-new instances)."
  default     = null
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Name of the EC2 key pair used for SSH access"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to the instance"
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name to attach to the instance"
}

variable "swap_size_gb" {
  type        = number
  description = "Size in GB of the swap file created on boot"
  default     = 2
}
