module "ui_service" {
  source = "./service"

  environment_name                = var.environment_name
  service_name                    = "ui"
  cluster_arn                     = aws_ecs_cluster.cluster.arn
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.subnet_ids
  tags                            = var.tags
  container_image                 = module.container_images.result.ui.url
  service_discovery_namespace_arn = aws_service_discovery_private_dns_namespace.this.arn
  cloudwatch_logs_group_id        = aws_cloudwatch_log_group.ecs_tasks.id
  healthcheck_path                = "/actuator/health"
  alb_target_group_arn            = element(module.alb.target_group_arns, 0)

  environment_variables = {
    RETAIL_UI_ENDPOINTS_CATALOG  = "http://${module.catalog_service.ecs_service_name}"
    RETAIL_UI_ENDPOINTS_CARTS    = "http://${module.carts_service.ecs_service_name}"
    RETAIL_UI_ENDPOINTS_CHECKOUT = "http://${module.checkout_service.ecs_service_name}"
    RETAIL_UI_ENDPOINTS_ORDERS   = "http://${module.orders_service.ecs_service_name}"
  }
  
  additional_task_execution_role_iam_policy_arns = [ 
    "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
  ]
  
  # Datadog configuration
  enable_datadog     = local.datadog_enabled
  datadog_api_key_arn = var.datadog_api_key_arn
  datadog_api_key = var.datadog_api_key
  datadog_DD_SITE = var.datadog_DD_SITE
  datadog_firelens_host =var.datadog_firelens_host
  
  #moving Observability Config out of the lib.
  firelens_container = replace(var.firelens_container, "placeholder.cloudwatch_logs_group_id", aws_cloudwatch_log_group.ecs_tasks.id)
  log_config = replace(var.log_config, "placeholder.service_name", "ui")
  datadog_container = replace(var.datadog_container, "placeholder.cloudwatch_logs_group_id", aws_cloudwatch_log_group.ecs_tasks.id)
}
