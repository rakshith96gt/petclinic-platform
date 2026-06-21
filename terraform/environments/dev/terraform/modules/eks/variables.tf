variable "project" {
  type        = string
  description = "Project name"
  default     = "petclinic"
}

variable "environment" {
  type        = string
  description = "Environment (dev/prod)"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.29"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the EKS cluster"
}

variable "cluster_sg_id" {
  type        = string
  description = "Security group ID for the EKS cluster"
}

variable "node_sg_id" {
  type        = string
  description = "Security group ID for the EKS nodes"
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types for the managed node group"
  default     = ["t4g.small"]
}

variable "node_ami_type" {
  type        = string
  description = "AMI type for the nodes"
  default     = "AL2_ARM_64"
}

variable "node_min_size" {
  type        = number
  description = "Minimum size of the node group"
  default     = 2
}

variable "node_max_size" {
  type        = number
  description = "Maximum size of the node group"
  default     = 4
}

variable "node_desired_size" {
  type        = number
  description = "Desired size of the node group"
  default     = 2
}

variable "node_disk_size" {
  type        = number
  description = "Disk size in GB for the nodes"
  default     = 20
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}

variable "admin_arn" {
  type        = string
  description = "IAM ARN of the user/role that should have cluster-admin access"
}
