resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = merge({
    Name = "${var.project}-${var.environment}-vpc"
  }, var.tags)
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = "${var.project}-${var.environment}-igw"
  }, var.tags)
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge({
    Name = "${var.project}-${var.environment}-public-rt"
  }, var.tags)
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone        = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.project}-${var.environment}-public-${count.index + 1}"
    "kubernetes.io/cluster/${var.project}-${var.environment}" = "shared"
    "kubernetes.io/role/elb"                                 = "1"
  }, var.tags)
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc-flow-logs/${var.project}-${var.environment}"
  retention_in_days = 7

  tags = merge({
    Name = "${var.project}-${var.environment}-vpc-flow-logs"
  }, var.tags)
}

resource "aws_flow_log" "this" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_log.arn
  log_destination_type  = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id

  tags = merge({
    Name = "${var.project}-${var.environment}-vpc-flow-logs"
  }, var.tags)
}

# Security Groups

resource "aws_security_group" "eks_cluster" {
  name        = "${var.project}-${var.environment}-cluster-sg"
  description = "EKS Cluster Security Group"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.project}-${var.environment}-cluster-sg"
  }, var.tags)
}

resource "aws_security_group" "eks_node" {
  name        = "${var.project}-${var.environment}-node-sg"
  description = "EKS Node Security Group"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.project}-${var.environment}-node-sg"
  }, var.tags)
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.this.id

  tags = merge({
    Name = "${var.project}-${var.environment}-rds-sg"
  }, var.tags)
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.this.id

  egress = []

  tags = merge({
    Name = "${var.project}-${var.environment}-alb-sg"
  }, var.tags)
}

# Security Group Rules

# ALB Ingress Rules
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# Cluster SG Rules
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_node.id
}

# Node SG Rules
resource "aws_security_group_rule" "node_ingress_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "node_ingress_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_node.id
  self                     = true
}

resource "aws_security_group_rule" "node_ingress_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "node_ingress_alb" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "node_ingress_alb_health" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.alb.id
}

# RDS SG Rules
resource "aws_security_group_rule" "rds_ingress_nodes" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.eks_node.id
}

# ALB SG Rules
resource "aws_security_group_rule" "alb_egress_nodes" {
  type                     = "egress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_node.id
}

resource "aws_security_group_rule" "alb_egress_health" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_node.id
}
