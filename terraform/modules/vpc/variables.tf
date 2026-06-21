variable "project" {
  type        = string
  description = "Project name"
  default     = "petclinic"
}

variable "environment" {
  type        = string
  description = "Environment (dev/prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs for subnets"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}
