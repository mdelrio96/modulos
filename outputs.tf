# Outputs del despliegue

output "web_url" {
  description = "URL para acceder a la aplicación web"
  value       = format("http://%s", aws_lb.main.dns_name)
}

output "alb_dns_name" {
  description = "DNS del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.vpc.vpc_id
}

output "instance_private_ips" {
  description = "IPs privadas de las instancias EC2"
  value       = aws_instance.web_instances[*].private_ip
}

output "instance_ids" {
  description = "IDs de las instancias EC2"
  value       = aws_instance.web_instances[*].id
}
