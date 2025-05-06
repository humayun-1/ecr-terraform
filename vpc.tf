module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = "ecs-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_dns_hostnames = true
  enable_nat_gateway   = false

  tags = {
    Terraform = "true"
  }
}

# Security group for ALB & ECS instances
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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