# Variables para el proyecto de bootstrap del backend

variable "aws_region" {
  description = "Región de AWS donde se crearán los recursos del backend"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre del bucket S3 para el estado de Terraform (debe ser único globalmente)"
  type        = string
  default     = "cheese-factory-terraform-state-2024"
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para bloqueo de estado"
  type        = string
  default     = "cheese-factory-terraform-locks"
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Project   = "Cheese Factory"
    ManagedBy = "Terraform"
    Course    = "Infraestructura como Código"
  }
}

