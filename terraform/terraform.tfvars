# Configuración de red
vpc_cidr    = "10.0.0.0/16"
aws_region  = "us-east-1"
environment = "dev"

# Lista de IPs permitidas
# - 10.0.0.0/16: VPC CIDR
# - 192.168.1.0/24: Rango de IPs corporativo
allowed_ips = ["10.0.0.0/16", "192.168.1.0/24"]

# Tags del proyecto
project_tags = {
  Project     = "TechWave"
  Environment = "dev"
  Owner       = "DevOps"
}