#!/bin/bash

# Script de configuración para instancias EC2 de ${project_name}
# Este script se ejecuta al iniciar cada instancia

# Actualizar el sistema
yum update -y

# Instalar Docker
yum install -y docker

# Iniciar el servicio de Docker
systemctl start docker
systemctl enable docker

# Agregar el usuario ec2-user al grupo docker
usermod -a -G docker ec2-user

# Esperar un momento para que Docker esté completamente iniciado
sleep 10

# Usar el índice de instancia pasado desde Terraform
INSTANCE_INDEX=${instance_index}

# Log para debugging
echo "=== CHEESE FACTORY SETUP LOG ===" > /var/log/cheese-setup.log
echo "Instance index from Terraform: $INSTANCE_INDEX" >> /var/log/cheese-setup.log
echo "Project name: ${project_name}" >> /var/log/cheese-setup.log

# Mapear el índice a la imagen correspondiente usando case
case $INSTANCE_INDEX in
  0) DOCKER_IMAGE="errm/cheese:wensleydale" ;;
  1) DOCKER_IMAGE="errm/cheese:cheddar" ;;
  2) DOCKER_IMAGE="errm/cheese:stilton" ;;
  *) DOCKER_IMAGE="errm/cheese:wensleydale" ;;
esac

echo "Selected Docker image: $DOCKER_IMAGE" >> /var/log/cheese-setup.log

# Descargar y ejecutar el contenedor Docker
echo "Pulling Docker image: $DOCKER_IMAGE" >> /var/log/cheese-setup.log
docker pull $DOCKER_IMAGE

# Verificar que la imagen se descargó correctamente
if [ $? -eq 0 ]; then
  echo "Docker image pulled successfully" >> /var/log/cheese-setup.log
  
  # Ejecutar el contenedor
  docker run -d -p 80:80 --name cheese-container --restart unless-stopped $DOCKER_IMAGE
  
  # Verificar que el contenedor se inició
  sleep 5
  if docker ps | grep -q cheese-container; then
    echo "Docker container started successfully with image: $DOCKER_IMAGE" >> /var/log/cheese-setup.log
  else
    echo "ERROR: Docker container failed to start" >> /var/log/cheese-setup.log
    docker logs cheese-container >> /var/log/cheese-setup.log 2>&1
  fi
else
  echo "ERROR: Failed to pull Docker image: $DOCKER_IMAGE" >> /var/log/cheese-setup.log
fi

# Mostrar estado de contenedores
echo "Container status:" >> /var/log/cheese-setup.log
docker ps >> /var/log/cheese-setup.log

# Configurar el firewall para permitir tráfico en el puerto 80
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Guardar las reglas de iptables
service iptables save

# Verificar que el puerto 80 esté escuchando
echo "Checking if port 80 is listening..." >> /var/log/cheese-setup.log
netstat -tlnp | grep :80 >> /var/log/cheese-setup.log

# Verificar conectividad HTTP local
echo "Testing local HTTP connection..." >> /var/log/cheese-setup.log
curl -s -o /dev/null -w "%%{http_code}" http://localhost >> /var/log/cheese-setup.log 2>&1
echo "" >> /var/log/cheese-setup.log

echo "${project_name} instance configuration completed successfully!" >> /var/log/cheese-setup.log
echo "=== END OF SETUP LOG ===" >> /var/log/cheese-setup.log
