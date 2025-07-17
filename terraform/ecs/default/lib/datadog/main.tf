data "aws_caller_identity" "current" {}

locals {
    aws_account_id = data.aws_caller_identity.current.account_id
}

variable "datadog_api_url" {
  description = "Datadog API url for the provider"
  type        = string
  # No default - this should be provided by the user when enable_datadog is true
  default     = ""
}


variable "environment_name" {
  description = "Name of the environment"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog Application key from your datadog account"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "datadog_integration_role_name" {
  description = "Name of the Datadog integration IAM role"
  type        = string
  default     = "DatadogIntegrationRole"
}

# Generate a random string to append to resource names
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Create a secret for the Datadog API key
resource "aws_secretsmanager_secret" "datadog_api_key" {
  name        = "${var.environment_name}-datadog-api-key-${random_string.suffix.result}"
  description = "Datadog API key for ${var.environment_name} environment"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id     = aws_secretsmanager_secret.datadog_api_key.id
  secret_string = var.datadog_api_key
}


