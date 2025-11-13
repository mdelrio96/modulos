# The Cheese Factory - Infraestructura con Terraform

Proyecto de infraestructura en AWS usando Terraform con módulos públicos para la Actividad 2.1.

## Arquitectura

- 3 instancias EC2 en subredes **privadas** ejecutando contenedores Docker
- Application Load Balancer en subredes **públicas**
- VPC personalizada con módulo público `terraform-aws-modules/vpc/aws`
- Backend remoto S3 con módulo público `terraform-aws-modules/s3-bucket/aws`

## Requisitos Previos

- Terraform >= 1.0
- AWS CLI configurado
- Git

## Configuración

### 1. Editar Variables

Copia y personaliza el archivo de variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` y cambia:

```hcl
environment = "dev"              # "dev" o "prod"
my_ip = "TU_IP_PUBLICA/32"       # Obtener en https://ipinfo.io/ip
```

**Importante:** 
- `environment = "dev"` → Instancias t2.micro
- `environment = "prod"` → Instancias t3.small

### 2. Backend S3 (Opcional)

Si deseas usar backend remoto:

```bash
cd s3-backend-bootstrap
terraform init
terraform apply
cd ..
```

Luego descomentar líneas 13-20 en `main.tf` y ejecutar `terraform init -migrate-state`

## Despliegue

```bash
# Inicializar
terraform init

# Aplicar
terraform apply

# Ver URL de la aplicación
terraform output web_url
```

### Probar el Round-Robin de Quesos

Para ver los diferentes tipos de queso en cada recarga:

1. **Abrir la URL en modo incógnito** (evita caché)
2. **Usar Ctrl+F5** para forzar recarga (no F5 normal)
3. Cada recarga mostrará un queso diferente en rotación:
   - Wensleydale → Cheddar → Stilton → Wensleydale...

**Nota:** F5 normal puede usar caché. Siempre usar **Ctrl+F5** o modo incógnito.

## Destruir Recursos

```bash
terraform destroy
```

## Estructura

```
Prueba1/
├── main.tf                      # Infraestructura principal
├── variables.tf                 # Variables (incluye environment)
├── outputs.tf                   # Outputs
├── terraform.tfvars             # Valores personalizados
├── terraform.tfvars.example     # Ejemplo de configuración
├── user_data.sh                 # Script de inicialización
└── s3-backend-bootstrap/        # Proyecto para backend S3
```

## Funcionalidades Implementadas

- ✅ Variable `environment` (dev/prod)
- ✅ Expresión condicional para tipo de instancia según entorno
- ✅ Módulo público VPC (terraform-aws-modules/vpc/aws)
- ✅ Módulo público S3 (terraform-aws-modules/s3-bucket/aws)
- ✅ 3 subredes públicas + 3 privadas en diferentes AZs
- ✅ EC2 en subredes privadas, ALB en subredes públicas
- ✅ Security Groups con principio de mínimo privilegio
- ✅ Funciones nativas: format(), merge(), element(), templatefile()
- ✅ Backend remoto S3 con DynamoDB

## Información del Proyecto

**Curso:** AUY1103 - Infraestructura como Código  
**Actividad:** 2.1 - Despliegue Profesional con Módulos Públicos  
**Institución:** DUOC UC
