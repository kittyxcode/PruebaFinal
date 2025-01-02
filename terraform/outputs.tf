# ==================================
# outputs.tf
# ==================================
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID de la subnet pública"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID de la subnet privada"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "web_security_group_id" {
  description = "ID del Security Group para web"
  value       = aws_security_group.web.id
}

output "ecr_repository_url" {
  description = "URL del repositorio de ECR"
  value       = aws_ecr_repository.app.repository_url
}

output "sns_topic_arn" {
  description = "ARN de la SNS Topic"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_group_name" {
  description = "Nombre del grupo de logs en CloudWatch"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "cloudwatch_alarm_name" {
  description = "Nombre de la alarma de CloudWatch"
  value       = aws_cloudwatch_metric_alarm.cpu_alarm.alarm_name
}

output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.process_message.arn
}

output "sqs_queue_url" {
  description = "URL de la cola SQS"
  value       = aws_sqs_queue.lambda_queue.url
}

output "lambda_role_arn" {
  description = "ARN del rol IAM de Lambda"
  value       = aws_iam_role.lambda_role.arn
}
