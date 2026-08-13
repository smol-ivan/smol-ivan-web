data "aws_ami" "debian13" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }

  owners = ["136693071363"] # Debian's official AMI owner ID
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.debian13.id
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
