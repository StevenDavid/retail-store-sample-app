resource "aws_cloudwatch_log_group" "ecs_tasks" {
  name              = "${var.environment_name}-tasks"
  retention_in_days = 7
  tags              = var.tags
}

data "aws_region" "current" {}
