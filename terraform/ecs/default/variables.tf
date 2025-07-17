variable "environment_name" {
  type        = string
  default     = "retail-store-ecs"
  description = "Name of the environment"
}

variable "container_image_overrides" {
  type = object({
    default_repository = optional(string)
    default_tag        = optional(string)

    ui       = optional(string)
    catalog  = optional(string)
    cart     = optional(string)
    checkout = optional(string)
    orders   = optional(string)
  })
  default     = {}
  description = "Object that encapsulates any overrides to default values"
}

# Datadog integration variables
variable "enable_datadog" {
  description = "Enable Datadog integration"
  type        = bool
  default     = true
}

variable "datadog_integration_role_name" {
  description = "Name of the Datadog integration IAM role"
  type        = string
  default     = "DatadogIntegrationRole"
}

# Datadog database monitoring variables
variable "enable_database_monitoring" {
  description = "Enable Datadog database monitoring"
  type        = bool
  default     = false
}

# Datadog database monitoring cluster
variable "datadog_dbm_cluster_name" {
  description = "Name of the ECS cluster for Datadog database monitoring"
  type        = string
  default     = "datadog-managed-dbm"
}

variable "datadog_api_key" {
  description = "Datadog API key from your datadog account"
  type        = string
  nullable    = false
}

variable "datadog_api_url" {
  description = "Datadog API url for the provider (for US5 its https://api.us5.datadoghq.com/)"
  type        = string
}

variable "datadog_app_key" {
  description = "Datadog Application Key from your datadog account"
  type        = string
  nullable    = false
}

variable "datadog_DD_SITE" {
  description = "Datadog DD_SITE (for US5 its us5.datadoghq.com) which changes based on your Datadog account (see https://docs.datadoghq.com/logs/log_collection/)"
  type        = string
}

variable "datadog_firelens_host" {
  description = "Datadog LogDriver firelens Host (for US5 its http-intake.logs.us5.datadoghq.com) which changes based on your Datadog account (see https://docs.datadoghq.com/logs/log_collection/)"
  type        = string
}
