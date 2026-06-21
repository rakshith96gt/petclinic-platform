variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "subnet_ids" {
  description = "Subnet IDs for cluster"
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "Cluster security group ID"
  type        = string
}

variable "node_sg_id" {
  description = "Node security group ID"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for nodes"
  type        = list(string)
  default     = ["t4g.small"]
}

variable "node_ami_type" {
  description = "AMI type for nodes"
  type        = string
  default     = "AL2_ARM_64"
}

variable "node_min_size" {
  description = "Min node count"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Max node count"
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired node count"
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-2"
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to access the EKS API server"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Default to all, but allows restriction
}

variable "deployer_arn" {
  description = "IAM ARN of the principal who should have cluster access"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
