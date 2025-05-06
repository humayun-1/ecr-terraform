variable "region" {
  description = "AWS region to create resources in"
  type  = string
  default = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID"
  type  = string
  default = "00000000"
}

variable "repo_name" {
  description = "ECR repo name"
  type  = string
  default = "ECR_REPO_NAME"
}