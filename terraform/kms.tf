# ==================================
# kms.tf
# ==================================
# KMS key para CloudWatch Logs
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.project_tags

  # Permitir que CloudWatch Logs use esta clave KMS
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchLogsToUseKey"
        Effect    = "Allow"
        Action    = [
          "kms:Decrypt",
          "kms:Encrypt"
        ]
        Resource  = "*"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# KMS key para ECR
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.project_tags
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecr"
  target_key_id = aws_kms_key.ecr.key_id
}

# KMS key para SNS
resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.project_tags
}

resource "aws_kms_alias" "sns" {
  name          = "alias/sns"
  target_key_id = aws_kms_key.sns.key_id
}
