# S3 Backend Bootstrap

Proyecto separado para crear el bucket S3 y tabla DynamoDB del backend remoto de Terraform.

## Recursos que Crea

- Bucket S3 (con módulo `terraform-aws-modules/s3-bucket/aws`)
  - Privado
  - Versionamiento habilitado
  - Bloqueo de acceso público
- Tabla DynamoDB para state locking

## Uso

```bash
cd s3-backend-bootstrap
terraform init
terraform apply
```

Después de crear los recursos, descomenta el bloque `backend` en el `main.tf` principal (líneas 13-20) y ejecuta:

```bash
cd ..
terraform init -migrate-state
```

## Nota

Si el nombre del bucket ya existe, cambia `bucket_name` en `variables.tf`.
