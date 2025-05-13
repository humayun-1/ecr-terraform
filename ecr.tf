resource "null_resource" "docker_build" {
  triggers = {
    docker_file  = filesha256("${var.app_path}/Dockerfile")
    package_json = filesha256("${var.app_path}/package.json")
  }

  provisioner "local-exec" {
    command = <<-EOT
    echo "App path: ${var.app_path}"
    echo "Dockerfile hash: ${filesha256("${var.app_path}/Dockerfile")}"
    echo "Package.json hash: ${filesha256("${var.app_path}/package.json")}"

    cd ${var.app_path} && \
    echo "Logged into ECR" && \
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com && \
    echo "Starting Docker build..." && \
    docker build -t ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.app_ecr_repo.name}:latest . && \
    docker push ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.app_ecr_repo.name}:latest
  EOT
  }

  depends_on = [aws_ecr_repository.app_ecr_repo]
}

# ECR Repository
resource "aws_ecr_repository" "app_ecr_repo" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}