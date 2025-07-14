data "aws_region" "current" {}

module "tags" {
  source = "../../lib/tags"

  environment_name = local.standard_environment_name
}

module "vpc" {
  source = "../../lib/vpc"

  environment_name = local.standard_environment_name

  tags = module.tags.result
}

module "datadog" {
  #count  = var.enable_datadog ? 1 : 0
  source = "./lib/datadog"
  
  environment_name = local.standard_environment_name
  datadog_api_key  = var.datadog_api_key
  datadog_api_url  = var.datadog_api_url
  datadog_app_key  = var.datadog_app_key
  tags             = module.tags.result
  
  # Datadog integration role and forwarder configuration
  datadog_integration_role_name = var.datadog_integration_role_name
  datadog_forwarder_lambda_arn  = var.datadog_forwarder_lambda_arn

  # Catalog database configuration
  catalog_db_endpoint        = module.dependencies.catalog_db_endpoint
  catalog_db_port            = module.dependencies.catalog_db_port
  catalog_db_name            = module.dependencies.catalog_db_database_name
  catalog_db_username        = module.dependencies.catalog_db_master_username
  catalog_db_password        = module.dependencies.catalog_db_master_password
  catalog_security_group_id  = module.dependencies.catalog_db_security_group_id
  
  # Orders database configuration
  orders_db_endpoint         = module.dependencies.orders_db_endpoint
  orders_db_port             = module.dependencies.orders_db_port
  orders_db_name             = module.dependencies.orders_db_database_name
  orders_db_username         = module.dependencies.orders_db_master_username
  orders_db_password         = module.dependencies.orders_db_master_password
  orders_security_group_id   = module.dependencies.orders_db_security_group_id
}

module "dependencies" {
  source = "../../lib/dependencies"

  environment_name = local.standard_environment_name
  tags             = module.tags.result

  vpc_id     = module.vpc.inner.vpc_id
  subnet_ids = module.vpc.inner.private_subnets

  catalog_security_group_id  = module.retail_app_ecs.catalog_security_group_id
  orders_security_group_id   = module.retail_app_ecs.orders_security_group_id
  checkout_security_group_id = module.retail_app_ecs.checkout_security_group_id
}

module "retail_app_ecs" {
  source = "../../lib/ecs"

  environment_name          = local.standard_environment_name
  vpc_id                    = module.vpc.inner.vpc_id
  subnet_ids                = module.vpc.inner.private_subnets
  public_subnet_ids         = module.vpc.inner.public_subnets
  tags                      = module.tags.result
  container_image_overrides = var.container_image_overrides

  catalog_db_endpoint = module.dependencies.catalog_db_endpoint
  catalog_db_port     = module.dependencies.catalog_db_port
  catalog_db_name     = module.dependencies.catalog_db_database_name
  catalog_db_username = module.dependencies.catalog_db_master_username
  catalog_db_password = module.dependencies.catalog_db_master_password

  carts_dynamodb_table_name = module.dependencies.carts_dynamodb_table_name
  carts_dynamodb_policy_arn = module.dependencies.carts_dynamodb_policy_arn

  orders_db_endpoint = module.dependencies.orders_db_endpoint
  orders_db_port     = module.dependencies.orders_db_port
  orders_db_name     = module.dependencies.orders_db_database_name
  orders_db_username = module.dependencies.orders_db_master_username
  orders_db_password = module.dependencies.orders_db_master_password

  checkout_redis_endpoint = module.dependencies.checkout_elasticache_primary_endpoint
  checkout_redis_port     = module.dependencies.checkout_elasticache_port

  mq_endpoint = module.dependencies.mq_broker_endpoint
  mq_username = module.dependencies.mq_user
  mq_password = module.dependencies.mq_password

  # Datadog configuration
  enable_datadog           = var.enable_datadog
  datadog_api_key_arn      = var.enable_datadog ? module.datadog.datadog_api_key_arn : ""
  datadog_forwarder_lambda_arn = var.enable_datadog ? var.datadog_forwarder_lambda_arn : ""
  datadog_api_key  = var.enable_datadog ? var.datadog_api_key : ""
  datadog_DD_SITE = var.enable_datadog ? var.datadog_DD_SITE : ""
  datadog_firelens_host = var.enable_datadog ? var.datadog_firelens_host : ""
  
    # FireLens container definition
  firelens_container = jsonencode([{
    "essential": true,
    "image": "amazon/aws-for-fluent-bit:latest",
    "name": "log_router",
    "firelensConfiguration": {
      "type": "fluentbit",
      "options": {
        "enable-ecs-log-metadata": "true"
      }
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "placeholder.cloudwatch_logs_group_id",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "firelens"
      }
    },
    memoryReservation = 50
  }])
 
  # Main Container log configuration: typically either firelens or Cloudwatch
  log_config = var.enable_datadog ? jsonencode([{
          "logDriver": "awsfirelens",
          "options": {
            "Name": "datadog",
            "Host": "${var.datadog_firelens_host}",
            "apikey": "${var.datadog_api_key}",
            "dd_service": "placeholder.service_name",
            "dd_source": "ecs",
            "dd_tags": "env:${var.environment_name},service:placeholder.service_name",
            "TLS": "on",
            "provider": "ecs"
        }
  }]) : "[]"
  
  
  # Define Datadog agent container if enabled
  datadog_container = var.enable_datadog ? jsonencode([{
    "name": "datadog-agent",
    "image": "public.ecr.aws/datadog/agent:latest",
    "essential": true,
    "environment": [
      {
        "name": "DD_ECS_TASK_COLLECTION_ENABLED",
        "value": "true"
      },    
      {
        "name": "DD_APM_ENABLED",
        "value": "true"
      },    
      {
        "name": "DD_EC2_PREFER_IMDSV2",
        "value": "false"
      },
      {
        "name": "DD_SITE",
        "value": "${var.datadog_DD_SITE}"
      },
      {
        "name": "DD_APM_NON_LOCAL_TRAFFIC",
        "value": "true"
      },
      {
        "name": "DD_LOGS_ENABLED",
        "value": "true"
      },
      {
        "name": "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL",
        "value": "true"
      },
      {
        "name": "DD_PROCESS_AGENT_ENABLED",
        "value": "true"
      },
      {
        "name": "DD_DOCKER_LABELS_AS_TAGS",
        "value": "{\"com.amazonaws.ecs.task-definition-family\":\"service_name\"}"
      },
      {
        "name": "DD_TAGS",
        "value": "env:${var.environment_name} service:placeholder.service_name"
      },
      {
        "name": "DD_API_KEY",
        "value": "${var.datadog_api_key}"
      },
      {
        "name": "ECS_FARGATE",
        "value": "true"
      }
    ],
    "healthCheck": {
      "retries": 3,
      "command": ["CMD-SHELL","agent health"],
      "timeout": 5,
      "interval": 30,
      "startPeriod": 15
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "placeholder.cloudwatch_logs_group_id",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "datadog-agent"
      }
    },
    "portMappings": [
      {
        "containerPort": 8126,
        "hostPort": 8126,
        "protocol": "tcp"
      }
    ]
  }]) : "[]"
  
}
