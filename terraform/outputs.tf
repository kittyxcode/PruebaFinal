# Salida de la VPC ID
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

# Salida de la Subnet pública ID
output "public_subnet_id" {
  description = "ID de la subnet pública"
  value       = aws_subnet.public.id
}

# Salida de la Subnet privada ID
output "private_subnet_id" {
  description = "ID de la subnet privada"
  value       = aws_subnet.private.id
}

# Salida de la dirección del Gateway de Internet
output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Salida del Security Group ID
output "web_security_group_id" {
  description = "ID del Security Group para web"
  value       = aws_security_group.web.id
}

# Salida del repositorio de ECR
output "ecr_repository_url" {
  description = "URL del repositorio de ECR"
  value       = aws_ecr_repository.app.repository_url
}

# Salida de la URL de la SNS Topic
output "sns_topic_arn" {
  description = "ARN de la SNS Topic"
  value       = aws_sns_topic.alerts.arn
}

# Salida de la URL del grupo de logs en CloudWatch
output "cloudwatch_log_group_name" {
  description = "Nombre del grupo de logs en CloudWatch"
  value       = aws_cloudwatch_log_group.app_logs.name
}

# Salida del nombre de la alarma de CloudWatch
output "cloudwatch_alarm_name" {
  description = "Nombre de la alarma de CloudWatch"
  value       = aws_cloudwatch_metric_alarm.cpu_alarm.alarm_name
}

# Salida de la función Lambda
output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.process_message.arn
}

# Salida de la cola SQS
output "sqs_queue_url" {
  description = "URL de la cola SQS"
  value       = aws_sqs_queue.lambda_queue.url
}

# Salida del ARN del rol de Lambda
output "lambda_role_arn" {
  description = "ARN del rol IAM de Lambda"
  value       = aws_iam_role.lambda_role.arn
}