# Configuración del proveedor AWS y Backend Remoto
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto S3 con bloqueo DynamoDB
   backend "s3" {
     bucket         = "cheese-factory-terraform-state-2024"
     key            = "cheese-factory/terraform.tfstate"
     region         = "us-east-1"
     dynamodb_table = "cheese-factory-terraform-locks"
     encrypt        = true
   }
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# MÓDULO PÚBLICO PARA VPC
# ==============================================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = format("cheese-%s-vpc", var.environment)
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  # Habilitar NAT Gateway para que las instancias privadas tengan acceso a Internet
  enable_nat_gateway = true
  single_nat_gateway = var.environment == "dev" ? true : false  # En dev, solo un NAT; en prod, uno por AZ

  # Habilitar DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags usando función merge
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = format("cheese-%s-vpc", var.environment)
    }
  )

  # Tags específicos para subredes públicas
  public_subnet_tags = {
    Type = "Public"
    Tier = "Web"
  }

  # Tags específicos para subredes privadas
  private_subnet_tags = {
    Type = "Private"
    Tier = "Application"
  }
}

# ==============================================================================
# LOCALS PARA CONFIGURACIÓN DINÁMICA
# ==============================================================================
locals {
  # Expresión condicional para instance_type basado en environment (REQUERIMIENTO)
  instance_type = var.environment == "prod" ? "t3.small" : "t2.micro"

  # Mapeo de nombres de quesos para cada instancia usando lookup
  cheese_names = ["wensleydale", "cheddar", "stilton"]

  # User data scripts procesados con templatefile
  user_data_scripts = [
    for i in range(var.instance_count) : base64encode(templatefile("${path.module}/user_data.sh", {
      docker_images  = var.docker_images
      project_name   = var.project_name
      instance_index = i
    }))
  ]

  # Tags comunes usando merge (FUNCIÓN NATIVA)
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )
}

# ==============================================================================
# SECURITY GROUPS
# ==============================================================================

# Security Group para el Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name_prefix = format("cheese-%s-alb-sg-", var.environment)  # FUNCIÓN format
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Permitir tráfico HTTP desde cualquier lugar (REQUERIMIENTO)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(
    local.common_tags,
    {
      Name = format("cheese-%s-alb-sg", var.environment)
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group para las instancias EC2
resource "aws_security_group" "web_sg" {
  name_prefix = format("cheese-%s-web-sg-", var.environment)  # FUNCIÓN format
  description = "Security group for web instances - Principle of Least Privilege"
  vpc_id      = module.vpc.vpc_id

  # Permitir tráfico HTTP SOLO desde el ALB (REQUERIMIENTO - Principio de mínimo privilegio)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "HTTP from ALB only"
  }

  # Permitir SSH SOLO desde tu IP (REQUERIMIENTO - Principio de mínimo privilegio)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "SSH from my IP only"
  }

  # Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(
    local.common_tags,
    {
      Name = format("cheese-%s-web-sg", var.environment)
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# INSTANCIAS EC2 EN SUBREDES PRIVADAS
# ==============================================================================

resource "aws_instance" "web_instances" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = local.instance_type  # Usa la expresión condicional
  subnet_id              = module.vpc.private_subnets[count.index]  # SUBREDES PRIVADAS
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = local.user_data_scripts[count.index]

  # Tags usando función format para nombrar recursos (FUNCIÓN NATIVA)
  tags = merge(
    local.common_tags,
    {
      Name       = format("cheese-%s-ec2-%s", var.environment, local.cheese_names[count.index])
      Cheese     = element(var.docker_images, count.index)
      CheeseName = local.cheese_names[count.index]
      IsPrimary  = count.index == 0 ? "true" : "false"
      Subnet     = format("private-%s", var.vpc_azs[count.index])
    }
  )
}

# ==============================================================================
# APPLICATION LOAD BALANCER EN SUBREDES PÚBLICAS
# ==============================================================================

resource "aws_lb" "main" {
  name               = format("cheese-%s-alb", var.environment)  # FUNCIÓN format
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets  # SUBREDES PÚBLICAS

  enable_deletion_protection = false

  tags = merge(
    local.common_tags,
    {
      Name = format("cheese-%s-alb", var.environment)
    }
  )
}

# Target Group para el ALB
resource "aws_lb_target_group" "web_tg" {
  name     = format("cheese-%s-tg", var.environment)  # FUNCIÓN format
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # Deshabilitar stickiness para round-robin entre quesos
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(
    local.common_tags,
    {
      Name = format("cheese-%s-tg", var.environment)
    }
  )
}

# Listener del ALB
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = format("cheese-%s-listener", var.environment)
    }
  )
}

# Attachment de las instancias al Target Group
resource "aws_lb_target_group_attachment" "web_attachment" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_instances[count.index].id
  port             = 80
}
