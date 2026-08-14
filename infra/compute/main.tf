data "aws_ami" "debian13" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }

  owners = ["136693071363"] # Debian's official AMI owner ID
}

resource "aws_instance" "web_server" {
  # Pinned to the AMI already running on the existing instance. Using the
  # 'most_recent' data source directly here would force a replacement every
  # time a newer Debian AMI is published. Bump this deliberately (and plan
  # for the resulting instance replacement) when you want to upgrade the OS.
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.debian13.id
  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    swap_size_gb = var.swap_size_gb
  })

  tags = {
    Name = "${var.project_name}-production"
  }
}

resource "aws_eip" "web_server" {
  instance = aws_instance.web_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}
