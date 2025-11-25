# Bootstrap para Backend Remoto de Terraform
# Este proyecto crea el bucket S3 y la tabla DynamoDB necesarios para el backend remoto

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Generar un ID aleatorio para el nombre del bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Módulo público para crear el bucket S3
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = var.bucket_name != "" ? var.bucket_name : "cheese-factory-mdelrio-${lower(random_id.bucket_suffix.hex)}"
  acl    = "private"

  # Habilitar control de acceso mediante ACL
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  # Versionamiento habilitado
  versioning = {
    enabled = true
  }

  # Bloqueo de acceso público
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Cifrado del bucket
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Name        = var.bucket_name != "" ? var.bucket_name : "cheese-factory-mdelrio-${lower(random_id.bucket_suffix.hex)}"
      Purpose     = "Terraform State Backend"
      Environment = "Infrastructure"
    }
  )
}

# Tabla DynamoDB para bloqueo de estado
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      Name        = var.dynamodb_table_name
      Purpose     = "Terraform State Locking"
      Environment = "Infrastructure"
    }
  )
}

