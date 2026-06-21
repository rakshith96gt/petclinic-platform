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

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}
