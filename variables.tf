# Variables para la configuración de AWS
variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetar los recursos"
  type        = string
  default     = "cheese-factory"
}

# Variable de entorno
variable "environment" {
  description = "Entorno de despliegue (dev o prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "El entorno debe ser 'dev' o 'prod'."
  }
}

# Variables para la VPC
variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "Zonas de disponibilidad para la VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_private_subnets" {
  description = "CIDR blocks para subredes privadas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "vpc_public_subnets" {
  description = "CIDR blocks para subredes públicas"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# Variables para las instancias EC2
variable "instance_count" {
  description = "Número de instancias EC2 a crear"
  type        = number
  default     = 3
}

# instance_type se calculará dinámicamente basado en environment
# Usar expresión condicional en main.tf: var.environment == "prod" ? "t3.small" : "t2.micro"

variable "ami_id" {
  description = "ID de la AMI de Amazon Linux 2"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
}

# Variables para las imágenes Docker
variable "docker_images" {
  description = "Lista de imágenes Docker para cada instancia"
  type        = list(string)
  default     = ["errm/cheese:wensleydale", "errm/cheese:cheddar", "errm/cheese:stilton"]
}

# Variable para la IP personal
variable "my_ip" {
  description = "Tu dirección IP para permitir acceso SSH"
  type        = string
  default     = "0.0.0.0/0"  # Cambiar por tu IP real
}

# Variables opcionales para personalización
variable "tags" {
  description = "Tags adicionales para todos los recursos"
  type        = map(string)
  default     = {
    Project   = "Cheese Factory"
    ManagedBy = "Terraform"
    Course    = "Infraestructura como Código"
  }
}
