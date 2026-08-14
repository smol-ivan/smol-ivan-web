output "server_public_ip" {
  value       = module.compute.public_ip
  description = "Point your domains (Namecheap) to this IP"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "Your ECR repository URL"
}
