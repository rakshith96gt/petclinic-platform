variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-2"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "domain_name" {
  description = "Domain name for Route 53"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB (provided after ALB creation)"
  type        = string
  default     = null
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the ALB"
  type        = string
  default     = null
}
