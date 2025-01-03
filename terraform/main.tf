# VPC y Networking
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.project_tags, {
    Name = "techwave-vpc-${var.environment}"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = merge(var.project_tags, {
    Name = "techwave-public-subnet-${var.environment}"
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = "${var.aws_region}a"

  tags = merge(var.project_tags, {
    Name = "techwave-private-subnet-${var.environment}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.project_tags, {
    Name = "techwave-igw-${var.environment}"
  })
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.project_tags, {
    Name = "techwave-public-rt-${var.environment}"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "web" {
  name        = "techwave-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
    description = "HTTP access from allowed IPs"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
    description = "HTTPS access from allowed IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow all outbound traffic within VPC"
  }

  tags = merge(var.project_tags, {
    Name = "techwave-web-sg-${var.environment}"
  })
}

# Repositorio ECR para API
resource "aws_ecr_repository" "app" {
  name                 = "techwave-api"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle_policy {
    policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 30 images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v"]
            countType     = "imageCountMoreThan"
            countNumber   = 30
          }
          action = {
            type = "expire"
          }
        }
      ]
    })
  }

  tags = var.project_tags
}

# Repositorio ECR para Web
resource "aws_ecr_repository" "web" {
  name                 = "techwave-web"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle_policy {
    policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 30 images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v"]
            countType     = "imageCountMoreThan"
            countNumber   = 30
          }
          action = {
            type = "expire"
          }
        }
      ]
    })
  }

  tags = var.project_tags
}

# Política IAM para ECR
resource "aws_iam_role_policy" "ecr_policy" {
  name = "techwave-ecr-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/techwave/app"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = var.project_tags
}

# SNS Topic para alertas
resource "aws_sns_topic" "alerts" {
  name              = "techwave-alerts"
  kms_master_key_id = aws_kms_key.sns.arn

  tags = var.project_tags
}

# CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "techwave-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
}

# SNS Topic para Lambda
resource "aws_sns_topic" "lambda_updates" {
  name              = "techwave-lambda-updates"
  kms_master_key_id = aws_kms_key.sns.arn

  tags = var.project_tags
}

# SQS Queue
resource "aws_sqs_queue" "lambda_queue" {
  name = "techwave-lambda-queue"

  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = var.project_tags
}

# Política para permitir que SNS publique en SQS
resource "aws_sqs_queue_policy" "lambda_queue_policy" {
  queue_url = aws_sqs_queue.lambda_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.lambda_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : aws_sns_topic.lambda_updates.arn
          }
        }
      }
    ]
  })
}

# Suscripción de SQS a SNS
resource "aws_sns_topic_subscription" "lambda_updates_sqs" {
  topic_arn = aws_sns_topic.lambda_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.lambda_queue.arn
}

# Role IAM para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "techwave-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.project_tags
}

# Función Lambda
resource "aws_lambda_function" "process_message" {
  filename      = "../lambda/function.zip"
  function_name = "techwave-process-message"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"

  tracing_config {
    mode = "Active"
  }

   environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.lambda_updates.arn
      ENVIRONMENT   = var.environment
      LOG_LEVEL     = "INFO"
    }
  }

  tags = var.project_tags
}

# Trigger de SQS para Lambda
resource "aws_lambda_event_source_mapping" "sqs_lambda" {
  event_source_arn = aws_sqs_queue.lambda_queue.arn
  function_name    = aws_lambda_function.process_message.arn
  batch_size       = 1
}

# Trigge