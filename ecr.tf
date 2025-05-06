resource "aws_ecr_repository" "nodejs_aws" {
  name = var.repo_name
}

resource "null_resource" "docker_build_push" {
  depends_on = [aws_ecr_repository.nodejs_aws]

  provisioner "local-exec" {
    command = <<EOT
      $(aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.us-east-1.amazonaws.com)
      docker build -t ${var.account_id}.dkr.ecr.us-east-1.amazonaws.com/${var.repo_name}:latest -f ../realtime-dashboard/Dockerfile ../realtime-dashboard
      docker push ${var.account_id}.dkr.ecr.us-east-1.amazonaws.com/${var.repo_name}:latest
    EOT
  }
}