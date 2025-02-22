# ==================================
# variables.tf
# ==================================

variable "AWS_ACCOUNT_ID" {
  description = "AWS Account ID for KMS key policies"
  type        = string
}
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_tags" {
  description = "Tags for the project"
  type        = map(string)
  default = {
    Project     = "TechWave"
    Environment = "dev"
    Owner       = "DevOps"
  }
}

variable "allowed_ips" {
  description = "Lista de rangos IP permitidos para acceso web"
  type        = list(string)
  default     = ["10.0.0.0/16", "192.168.1.0/24"]  # Ajusta estos rangos según tus necesidades
}

