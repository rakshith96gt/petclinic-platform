variable "project" {
  type        = string
  description = "Project name"
  default     = "petclinic"
}

variable "environment" {
  type        = string
  description = "Environment (dev/prod)"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the hosted zone (e.g., example.com)"
}

variable "alb_dns_name" {
  type        = string
  description = "The DNS name of the ALB to alias"
  default     = null
}

variable "alb_zone_id" {
  type        = string
  description = "The hosted zone ID of the ALB (canonical zone ID)"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}
