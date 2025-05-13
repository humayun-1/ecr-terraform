output "ecr_repository_url" {
  value = aws_ecr_repository.app_ecr_repo.repository_url
}

output "load_balancer_dns" {
  value = aws_lb.main.dns_name
}

output "nameservers" {
  value = "Add these nameservers to your domain provider's DNS settings if not already configured:\n${join("\n", aws_route53_zone.primary.name_servers)}"
}
