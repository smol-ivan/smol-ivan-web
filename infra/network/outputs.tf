output "vpc_id" {
  value = aws_default_vpc.default.id
}

output "security_group_id" {
  value = aws_security_group.web_sg.id
}
