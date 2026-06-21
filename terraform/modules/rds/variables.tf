variable "project" {
  type        = string
  description = "Project name"
  default     = "petclinic"
}

variable "environment" {
  type        = string
  description = "Environment (dev/prod)"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for DB subnet group"
}

variable "security_group_id" {
  type        = string
  description = "RDS security group ID"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Initial storage in GB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Max autoscale storage in GB"
  default     = 20
}

variable "multi_az" {
  type        = bool
  description = "Multi-AZ deployment"
  default     = false
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention in days"
  default     = 7
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on delete"
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Deletion protection"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}
