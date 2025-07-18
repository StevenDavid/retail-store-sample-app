locals {
    aws_account_id = data.aws_caller_identity.current.account_id
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

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
  source = "./lib/datadog"
  
  environment_name = local.standard_environment_name
  datadog_api_key  = var.datadog_api_key
  datadog_api_url  = var.datadog_api_url
  datadog_app_key  = var.datadog_app_key
  tags             = module.tags.result
  
  # Datadog integration role
  datadog_integration_role_name = var.datadog_integration_role_name

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
  enable_observ           = var.enable_observ
  observ_agent_name = var.observ_agent_name
  
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
  log_config = jsonencode([{
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
  }])
  
  
  # Define Datadog agent container if enabled
  observ_container = jsonencode([{
    "name": "${var.observ_agent_name}",
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
  }])
  
}



#AWS integrations code

variable "aws_permission_list" {
  type    = set(string)
  default = [
      "apigateway:GET",
    "aoss:BatchGetCollection",
    "aoss:ListCollections",
    "autoscaling:Describe*",
    "backup:List*",
    "bcm-data-exports:GetExport",
    "bcm-data-exports:ListExports",
    "bedrock:GetAgent",
    "bedrock:GetAgentAlias",
    "bedrock:GetFlow",
    "bedrock:GetFlowAlias",
    "bedrock:GetGuardrail",
    "bedrock:GetImportedModel",
    "bedrock:GetInferenceProfile",
    "bedrock:GetMarketplaceModelEndpoint",
    "bedrock:ListAgentAliases",
    "bedrock:ListAgents",
    "bedrock:ListFlowAliases",
    "bedrock:ListFlows",
    "bedrock:ListGuardrails",
    "bedrock:ListImportedModels",
    "bedrock:ListInferenceProfiles",
    "bedrock:ListMarketplaceModelEndpoints",
    "bedrock:ListPromptRouters",
    "bedrock:ListProvisionedModelThroughputs",
    "budgets:ViewBudget",
    "cassandra:Select",
    "cloudfront:GetDistributionConfig",
    "cloudfront:ListDistributions",
    "cloudtrail:DescribeTrails",
    "cloudtrail:GetTrailStatus",
    "cloudtrail:LookupEvents",
    "cloudwatch:Describe*",
    "cloudwatch:Get*",
    "cloudwatch:List*",
    "codeartifact:DescribeDomain",
    "codeartifact:DescribePackageGroup",
    "codeartifact:DescribeRepository",
    "codeartifact:ListDomains",
    "codeartifact:ListPackageGroups",
    "codeartifact:ListPackages",
    "codedeploy:BatchGet*",
    "codedeploy:List*",
    "codepipeline:ListWebhooks",
    "cur:DescribeReportDefinitions",
    "directconnect:Describe*",
    "dynamodb:Describe*",
    "dynamodb:List*",
    "ec2:Describe*",
    "ec2:GetAllowedImagesSettings",
    "ec2:GetEbsDefaultKmsKeyId",
    "ec2:GetInstanceMetadataDefaults",
    "ec2:GetSerialConsoleAccessStatus",
    "ec2:GetSnapshotBlockPublicAccessState",
    "ec2:GetTransitGatewayPrefixListReferences",
    "ec2:SearchTransitGatewayRoutes",
    "ecs:Describe*",
    "ecs:List*",
    "elasticache:Describe*",
    "elasticache:List*",
    "elasticfilesystem:DescribeAccessPoints",
    "elasticfilesystem:DescribeFileSystems",
    "elasticfilesystem:DescribeTags",
    "elasticloadbalancing:Describe*",
    "elasticmapreduce:Describe*",
    "elasticmapreduce:List*",
    "emr-containers:ListManagedEndpoints",
    "emr-containers:ListSecurityConfigurations",
    "emr-containers:ListVirtualClusters",
    "es:DescribeElasticsearchDomains",
    "es:ListDomainNames",
    "es:ListTags",
    "events:CreateEventBus",
    "fsx:DescribeFileSystems",
    "fsx:ListTagsForResource",
    "glacier:GetVaultNotifications",
    "glue:ListRegistries",
    "grafana:DescribeWorkspace",
    "greengrass:GetComponent",
    "greengrass:GetConnectivityInfo",
    "greengrass:GetCoreDevice",
    "greengrass:GetDeployment",
    "health:DescribeAffectedEntities",
    "health:DescribeEventDetails",
    "health:DescribeEvents",
    "kinesis:Describe*",
    "kinesis:List*",
    "lambda:GetPolicy",
    "lambda:List*",
    "lightsail:GetInstancePortStates",
    "logs:DeleteSubscriptionFilter",
    "logs:DescribeLogGroups",
    "logs:DescribeLogStreams",
    "logs:DescribeSubscriptionFilters",
    "logs:FilterLogEvents",
    "logs:PutSubscriptionFilter",
    "logs:TestMetricFilter",
    "macie2:GetAllowList",
    "macie2:GetCustomDataIdentifier",
    "macie2:ListAllowLists",
    "macie2:ListCustomDataIdentifiers",
    "macie2:ListMembers",
    "macie2:GetMacieSession",
    "managedblockchain:GetAccessor",
    "managedblockchain:GetMember",
    "managedblockchain:GetNetwork",
    "managedblockchain:GetNode",
    "managedblockchain:GetProposal",
    "managedblockchain:ListAccessors",
    "managedblockchain:ListInvitations",
    "managedblockchain:ListMembers",
    "managedblockchain:ListNodes",
    "managedblockchain:ListProposals",
    "memorydb:DescribeAcls",
    "memorydb:DescribeMultiRegionClusters",
    "memorydb:DescribeParameterGroups",
    "memorydb:DescribeReservedNodes",
    "memorydb:DescribeSnapshots",
    "memorydb:DescribeSubnetGroups",
    "memorydb:DescribeUsers",
    "oam:ListAttachedLinks",
    "oam:ListSinks",
    "organizations:Describe*",
    "organizations:List*",
    "osis:GetPipeline",
    "osis:GetPipelineBlueprint",
    "osis:ListPipelineBlueprints",
    "osis:ListPipelines",
    "proton:GetComponent",
    "proton:GetDeployment",
    "proton:GetEnvironment",
    "proton:GetEnvironmentAccountConnection",
    "proton:GetEnvironmentTemplate",
    "proton:GetEnvironmentTemplateVersion",
    "proton:GetRepository",
    "proton:GetService",
    "proton:GetServiceInstance",
    "proton:GetServiceTemplate",
    "proton:GetServiceTemplateVersion",
    "proton:ListComponents",
    "proton:ListDeployments",
    "proton:ListEnvironmentAccountConnections",
    "proton:ListEnvironmentTemplateVersions",
    "proton:ListEnvironmentTemplates",
    "proton:ListEnvironments",
    "proton:ListRepositories",
    "proton:ListServiceInstances",
    "proton:ListServiceTemplateVersions",
    "proton:ListServiceTemplates",
    "proton:ListServices",
    "qldb:ListJournalKinesisStreamsForLedger",
    "rds:Describe*",
    "rds:List*",
    "redshift:DescribeClusters",
    "redshift:DescribeLoggingStatus",
    "redshift-serverless:ListEndpointAccess",
    "redshift-serverless:ListManagedWorkgroups",
    "redshift-serverless:ListNamespaces",
    "redshift-serverless:ListRecoveryPoints",
    "redshift-serverless:ListSnapshots",
    "route53:List*",
    "s3:GetBucketLocation",
    "s3:GetBucketLogging",
    "s3:GetBucketNotification",
    "s3:GetBucketTagging",
    "s3:ListAccessGrants",
    "s3:ListAllMyBuckets",
    "s3:PutBucketNotification",
    "s3express:GetBucketPolicy",
    "s3express:GetEncryptionConfiguration",
    "s3express:ListAllMyDirectoryBuckets",
    "s3tables:GetTableBucketMaintenanceConfiguration",
    "s3tables:ListTableBuckets",
    "s3tables:ListTables",
    "savingsplans:DescribeSavingsPlanRates",
    "savingsplans:DescribeSavingsPlans",
    "secretsmanager:GetResourcePolicy",
    "ses:Get*",
    "ses:ListAddonInstances",
    "ses:ListAddonSubscriptions",
    "ses:ListAddressLists",
    "ses:ListArchives",
    "ses:ListContactLists",
    "ses:ListCustomVerificationEmailTemplates",
    "ses:ListMultiRegionEndpoints",
    "ses:ListIngressPoints",
    "ses:ListRelays",
    "ses:ListRuleSets",
    "ses:ListTemplates",
    "ses:ListTrafficPolicies",
    "sns:GetSubscriptionAttributes",
    "sns:List*",
    "sns:Publish",
    "sqs:ListQueues",
    "states:DescribeStateMachine",
    "states:ListStateMachines",
    "support:DescribeTrustedAdvisor*",
    "support:RefreshTrustedAdvisorCheck",
    "tag:GetResources",
    "tag:GetTagKeys",
    "tag:GetTagValues",
    "timestream:DescribeEndpoints",
    "timestream:ListTables",
    "waf-regional:GetRule",
    "waf-regional:GetRuleGroup",
    "waf-regional:ListRuleGroups",
    "waf-regional:ListRules",
    "waf:GetRule",
    "waf:GetRuleGroup",
    "waf:ListRuleGroups",
    "waf:ListRules",
    "wafv2:GetIPSet",
    "wafv2:GetLoggingConfiguration",
    "wafv2:GetRegexPatternSet",
    "wafv2:GetRuleGroup",
    "wafv2:ListLoggingConfigurations",
    "workmail:DescribeOrganization",
    "workmail:ListOrganizations",
    "xray:BatchGetTraces",
    "xray:GetTraceSummaries"
  ]
}


# don't change arn:aws:iam::464622532012:root this is the Datadog owned account you are integrating with, not your account ID
#==================================================
# data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::464622532012:root"]
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "sts:ExternalId"
#       values = [
#         "${datadog_integration_aws_account.datadog_integration.auth_config.aws_auth_config_role.external_id}"
#       ]
#     }
#   }
# }

data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::643497387296:root"]
    }
  }
}


data "aws_iam_policy_document" "datadog_aws_integration" {
  statement {
    actions = var.aws_permission_list
    resources = ["*"]
  }
}

resource "aws_iam_policy" "datadog_aws_integration" {
  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_aws_integration.json
}
resource "aws_iam_role" "datadog_aws_integration" {
  name               = "DatadogIntegrationRole"
  description        = "Role for Datadog AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.datadog_aws_integration_assume_role.json
}
resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = aws_iam_policy.datadog_aws_integration.arn
}
resource "aws_iam_role_policy_attachment" "datadog_aws_integration_security_audit" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "datadog_integration_aws_account" "datadog_integration" {
  account_tags   = []
  aws_account_id = "${local.aws_account_id}"
  aws_partition  = "aws"
  aws_regions {
    include_all = true
  }
  auth_config {
    aws_auth_config_role {
      role_name = "DatadogIntegrationRole"
    }
  }
    resources_config {
    cloud_security_posture_management_collection = true
    extended_collection                          = true
  }
  traces_config {
    xray_services {
    }
  }
    logs_config {
    lambda_forwarder {
    }
  }
  metrics_config {
    namespace_filters {
    }
  }
}
