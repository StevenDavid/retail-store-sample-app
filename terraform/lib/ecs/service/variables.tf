variable "environment_name" {
  type        = string
  description = "Name of the environment"
}

variable "service_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "cluster_arn" {
  description = "ECS cluster ARN"
  type        = string
}

variable "tags" {
  description = "List of tags to be associated with resources."
  default     = {}
  type        = any
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "container_image" {
  description = "Container image for the service"
  type        = string
}

variable "service_discovery_namespace_arn" {
  description = "ARN of the service discovery namespace for Service Connect"
  type        = string
}

variable "environment_variables" {
  description = "Map of environment variables for the ECS task"
  default     = {}
  type        = any
}

variable "secrets" {
  description = "Map of secrets for the ECS task"
  default     = {}
  type        = any
}

variable "additional_task_role_iam_policy_arns" {
  description = "Additional IAM policy ARNs to be added to the task role"
  default     = []
  type        = list(string)
}

variable "additional_task_execution_role_iam_policy_arns" {
  description = "Additional IAM policy ARNs to be added to the task execution role"
  default     = []
  type        = list(string)
}

variable "healthcheck_path" {
  description = "HTTP path used to health check the service"
  default     = "/health"
  type        = string
}

variable "cloudwatch_logs_group_id" {
  description = "CloudWatch logs group ID"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group the ECS service should register tasks to"
  default     = ""
  type        = string
}

variable "enable_datadog" {
  description = "Enable Datadog integration"
  type        = bool
  default     = true
}

variable "cpu" {
  description = "The number of CPU units to reserve for the container"
  type        = string
  default     = "1024"
}

variable "memory" {
  description = "The amount of memory (in MiB) to allow the container to use"
  type        = string
  default     = "2048"
}

#Datadog variables
variable "datadog_api_key_arn" {
  description = "ARN of the Datadog API key secret"
  type        = string
  default     = ""
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
}

variable "datadog_DD_SITE" {
  description = "Datadog DD_SITE (for US5 its us5.datadoghq.com) which changes based on your Datadog account (see https://docs.datadoghq.com/logs/log_collection/)"
  type        = string
}

variable "datadog_firelens_host" {
  description = "Datadog LogDriver firelens Host (for US5 its http-intake.logs.us5.datadoghq.com) which changes based on your Datadog account (see https://docs.datadoghq.com/logs/log_collection/)"
  type        = string
}

variable "firelens_container" {
  description = "ECS task code for the firelens container"
  type        = string
}

variable "log_config" {
  description = "ECS task code for the where to log for the main container"
  type        = string
}

variable "datadog_container" {
  description = "ECS task code for the Observability agent"
  type        = string
}
