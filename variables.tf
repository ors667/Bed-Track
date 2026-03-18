variable "region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "alert_email" {
  description = "Email address for bed availability alert notifications"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs across multiple AZs for Lambda deployment"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for Lambda network placement"
  type        = string
}

variable "lambda_sg_id" {
  description = "Security group ID for the BedTrack Lambda function"
  type        = string
}
