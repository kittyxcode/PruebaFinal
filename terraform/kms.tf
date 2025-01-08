# ==================================
# kms.tf
# ==================================

# KMS key para CloudWatch Logs
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.project_tags

  # Política KMS con permisos adicionales
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAccountManagement",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogsToUseKey",
        Effect    = "Allow",
        Principal = {
          Service = "logs.amazonaws.com"
        },
        Action    = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/cloudwatch-logsfinal"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# KMS key para ECR
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.project_tags

  # Política mínima para ECR (se puede expandir si es necesario)
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAccountManagement",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecrfinal"
  target_key_id = aws_kms_key.ecr.key_id
}

# KMS key para SNS
resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.project_tags

  # Política mínima para SNS (se puede expandir si es necesario)
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAccountManagement",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:root"
        },
        Action    = "kms:*",
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "sns" {
  name          = "alias/snsfinal"
  target_key_id = aws_kms_key.sns.key_id
}
