module "carts_service" {
  source = "./service"

  environment_name                = var.environment_name
  service_name                    = "carts"
  cluster_arn                     = aws_ecs_cluster.cluster.arn
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.subnet_ids
  tags                            = var.tags
  container_image                 = module.container_images.result.cart.url
  service_discovery_namespace_arn = aws_service_discovery_private_dns_namespace.this.arn
  cloudwatch_logs_group_id        = aws_cloudwatch_log_group.ecs_tasks.id
  healthcheck_path                = "/actuator/health"

  environment_variables = {
    RETAIL_CART_PERSISTENCE_PROVIDER            = "dynamodb"
    RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME = var.carts_dynamodb_table_name
  }

  additional_task_role_iam_policy_arns = [
    var.carts_dynamodb_policy_arn, "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
  ]
  
  # Datadog configuration
  enable_datadog     = local.datadog_enabled
  datadog_api_key_arn = var.datadog_api_key_arn
  datadog_api_key = var.datadog_api_key
  datadog_DD_SITE = var.datadog_DD_SITE
  datadog_firelens_host =var.datadog_firelens_host
}