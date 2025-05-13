# Variables
variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  default     = "140023385240"
  type        = string
}

variable "app_name" {
  description = "Name of the application"
  default     = "next-app"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  default     = "production"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
  type        = string
}

variable "app_port" {
  description = "Port the application runs on"
  default     = 3000
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances"
  default     = 2
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  default     = 4
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances"
  default     = 1
  type        = number
}

variable "app_path" {
  description = "Path to the Next.js application"
  default     = "../ecs-next-app"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  default     = "humayunjawad.com"
  type        = string
}