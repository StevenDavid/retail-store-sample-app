locals {
  #adding this validation block for it to check for API Key 
  validate_datadog_config = var.enable_datadog && var.datadog_api_key_arn == "" ? tobool("Datadog API key ARN must be provided when Datadog is enabled") : true

  environment = jsonencode([for k, v in var.environment_variables : {
    "name" : k,
    "value" : v
  }])

  secrets = jsonencode([for k, v in var.secrets : {
    "name" : k,
    "valueFrom" : v
  }])
  
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.environment_name}-${var.service_name}"
  container_definitions    = <<DEFINITION
    [
      {
        "name": "${var.service_name}",
        "image": "${var.container_image}",
        "portMappings": [
          {
            "containerPort": 8080,
            "hostPort": 8080,
            "name": "application",
            "protocol": "tcp"
          }
        ],
        "essential": true,
        "networkMode": "awsvpc",
        "readonlyRootFilesystem": false,
        "environment": ${local.environment},
        "secrets": ${local.secrets},
        "cpu": 0,
        "mountPoints": [],
        "volumesFrom": [],
        "healthCheck": {
          "command": [ "CMD-SHELL", "curl -f http://localhost:8080${var.healthcheck_path} || exit 1" ],
          "interval": 10,
          "startPeriod": 60,
          "retries": 3,
          "timeout": 5
        },
        "logConfiguration": ${var.enable_datadog ? "${substr(var.log_config, 1, length(var.log_config) - 2)}," : "{},"}
        "dependsOn": ${var.enable_datadog ? "[{\"containerName\": \"datadog-agent\", \"condition\": \"HEALTHY\"}]" : "[]"}
    }
    ${var.enable_datadog ? ",${substr(var.datadog_container, 1, length(var.datadog_container) - 2)}" : ""}
    ${var.enable_datadog ? ",${substr(var.firelens_container, 1, length(var.firelens_container) - 2)}" : ""}
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "1024"
  memory                  = "2048"
  execution_role_arn      = aws_iam_role.task_execution_role.arn
  task_role_arn           = aws_iam_role.task_role.arn
}

resource "aws_ecs_service" "this" {
  name                   = var.service_name
  cluster                = var.cluster_arn
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = 1
  
  timeouts {
    create = "40m"
  }
  launch_type            = "FARGATE"
  enable_execute_command = true
  wait_for_steady_state  = true

  network_configuration {
    security_groups  = [aws_security_group.this.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.service_discovery_namespace_arn
    service {
      client_alias {
        dns_name = var.service_name
        port     = "80"
      }
      discovery_name = var.service_name
      port_name      = "application"
    }
  }

  dynamic "load_balancer" {
    for_each = var.alb_target_group_arn == "" ? [] : [1]

    content {
      target_group_arn = var.alb_target_group_arn
      container_name   = "${var.service_name}"
      container_port   = 8080
    }
  }

  tags = var.tags
}
