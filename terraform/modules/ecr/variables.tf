variable "project" {
  type        = string
  description = "Project name"
  default     = "petclinic"
}

variable "environment" {
  type        = string
  description = "Environment (dev or prod)"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment must be either 'dev' or 'prod'."
  }
}

variable "service_names" {
  type        = list(string)
  description = "List of service names for which to create ECR repositories"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags for the repositories"
  default     = {}
}
