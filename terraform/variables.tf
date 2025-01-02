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

variable "ingress_cidr" {
  description = "Rango de IP permitido para acceso entrante"
  default     = "0.0.0.0/0"
}
