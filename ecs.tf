resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"
}
# Launch Template (replacing Launch Configuration)
resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "${var.app_name}-"
  image_id      = data.aws_ami.amazon_linux_ecs.id # Use data source for latest ECS-optimized AMI
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_tasks.id]

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "${var.app_name}-asg"
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-ecs-instance"
    propagate_at_launch = true
  }
}
# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  # Define CPU and memory at the task level
  cpu    = "256"
  memory = "512"

  container_definitions = jsonencode([
    {
      name              = var.app_name
      image             = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_name}:latest"
      essential         = true
      memory            = 512
      memoryReservation = 256
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${var.app_port}/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.app_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = tostring(var.app_port)
        }
      ]
    }
  ])

  depends_on = [null_resource.docker_build]
}

resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "${var.app_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1000
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cp_attach" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 1
  }
}

resource "aws_ecs_service" "app" {
  name                              = "${var.app_name}-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.desired_capacity
  depends_on                        = [aws_lb_listener.http]
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.app_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 1
  }
}
