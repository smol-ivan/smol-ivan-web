provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "debian13" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }

  owners = ["136693071363"]
}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "web_sg" {
  name        = "smol-ivan-web-sg"
  description = "Allow SSH (22), HTTP (80) y HTTPS (443)"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.debian13.id
  instance_type = "t3.micro"

  key_name = "smol-ivan-oregon"

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y ca-certificates curl gnupg
              
              # Llavero de seguridad oficial de Docker
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc

              # Agregar repositorio oficial de Docker para Debian
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

              # Instalar herramientas
              sudo apt-get update
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # IMPORTANTE: Darle permisos al usuario 'admin' de Debian para usar Docker sin sudo
              sudo usermod -aG docker admin

              # Tarea cron: Cada domingo a las 4:00 AM reinicia Nginx para forzar la lectura del SSL renovado
echo "0 4 * * 0 root cd /home/admin/app && docker compose -f docker-compose.prod.yml restart smol-ivan-web" | sudo tee -a /etc/crontab
              EOF

  tags = {
    Name = "smol-ivan-debian-production"
  }
}

output "server_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Apunta tu dominio en Namecheap a esta IP"
}

# 6. Repositorio privado en AWS ECR para guardar las imagenes Docker 
resource "aws_ecr_repository" "web_repo" {
  name                 = "smol-ivan-web"
  image_tag_mutability = "MUTABLE" # Permite sobrescribir el tag 'latest'

  image_scanning_configuration {
    scan_on_push = true # Escanea la imagen en busca de vulnerabilidades al subirla
  }
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.web_repo.repository_url
  description = "La URL de tu registro ECR en AWS"
}

# 1. Crear el Rol de IAM para el EC2
resource "aws_iam_role" "ec2_ecr_role" {
  name = "smol-ivan-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Adjuntar la política oficial de AWS para solo lectura de ECR
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. Crear el perfil de instancia que Terraform inyectará al EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "smol-ivan-ec2-profile"
  role = aws_iam_role.ec2_ecr_role.name
}
