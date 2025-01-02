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
  cidr_block             = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.project_tags, {
    Name = "techwave-web-sg-${var.environment}"
  })
}

# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "techwave-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.project_tags
}

# CloudWatch
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/techwave/app"
  retention_in_days = 14

  tags = var.project_tags
}

# SNS Topic para alertas
resource "aws_sns_topic" "alerts" {
  name = "techwave-alerts"
  
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
  name = "techwave-lambda-updates"
  
  tags = var.project_tags
}

# SQS Queue
resource "aws_sqs_queue" "lambda_queue" {
  name = "techwave-lambda-queue"
  
  delay_seconds             = 0
  max_message_size         = 262144
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
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.lambda_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn": aws_sns_topic.lambda_updates.arn
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

# Política para el rol de Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "techwave-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.lambda_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.lambda_updates.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Función Lambda
resource "aws_lambda_function" "process_message" {
  filename      = "../lambda/function.zip"
  function_name = "techwave-process-message"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.lambda_updates.arn
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
