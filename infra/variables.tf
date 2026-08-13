variable "project_name" {
  type        = string
  description = "Project name used as a prefix for resource names"
  default     = "smol-ivan"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-west-2"
}

variable "key_name" {
  type        = string
  description = "Name of the existing EC2 key pair used for SSH access"
  default     = "smol-ivan-oregon"
}

variable "swap_size_gb" {
  type        = number
  description = "Size in GB of the swap file created on the instance"
  default     = 2
}
