# Outputs del proyecto bootstrap

output "s3_bucket_id" {
  description = "ID del bucket S3 creado"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3 creado"
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_region" {
  description = "Región del bucket S3"
  value       = module.s3_bucket.s3_bucket_region
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para bloqueo"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_config" {
  description = "Configuración del backend para copiar en main.tf"
  value = <<-EOT
  
  Añade esta configuración al bloque terraform {} en tu main.tf:
  
  backend "s3" {
    bucket         = "${module.s3_bucket.s3_bucket_id}"
    key            = "cheese-factory/terraform.tfstate"
    region         = "${var.aws_region}"
    dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
    encrypt        = true
  }
  EOT
}

