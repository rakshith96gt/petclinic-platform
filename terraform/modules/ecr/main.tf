resource "aws_ecr_repository" "this" {
  for_each = toset(var.service_names)

  name                 = "${var.project}-${var.environment}/${each.key}"
  image_tag_mutability = var.environment == "dev" ? "MUTABLE" : "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = toset(var.service_names)
  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType    = "sincePushCount"
          countUnit    = "days"
          countNumber  = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType    = "imageCountMoreThan"
          countNumber  = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
