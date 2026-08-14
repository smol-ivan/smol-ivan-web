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

variable "ami_id" {
  type        = string
  description = "Pin the instance to this AMI ID to avoid unwanted replacement. Set to the AMI currently in use."
  default     = "ami-06a877a0bb8824880"
}
