resource "aws_ecr_repository" "web_repo" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE" # Allows overwriting the 'latest' tag

  image_scanning_configuration {
    scan_on_push = true # Scan image for vulnerabilities on push
  }
}
