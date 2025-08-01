variable "environment_name" {
  type        = string
  description = "Name of the environment"
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

variable "public_subnet_ids" {
  description = "List of public subnet IDs."
  type        = list(string)
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


variable "catalog_db_endpoint" {
  type        = string
  description = "Endpoint of the catalog database"
}

variable "catalog_db_port" {
  type        = string
  description = "Port of the catalog database"
}

variable "catalog_db_name" {
  type        = string
  description = "Name of the catalog database"
}

variable "catalog_db_username" {
  type        = string
  description = "Username for the catalog database"
}

variable "catalog_db_password" {
  type        = string
  description = "Password for the catalog database"
}

variable "carts_dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for the carts service"
}

variable "carts_dynamodb_policy_arn" {
  type        = string
  description = "IAM policy for DynamoDB table for the carts service"
}

variable "orders_db_endpoint" {
  type        = string
  description = "Endpoint of the orders database"
}

variable "orders_db_port" {
  type        = string
  description = "Port of the orders database"
}

variable "orders_db_name" {
  type        = string
  description = "Name of the orders database"
}

variable "orders_db_username" {
  type        = string
  description = "Username for the orders database"
}

variable "orders_db_password" {
  type        = string
  description = "Username for the password database"
}

variable "checkout_redis_endpoint" {
  type        = string
  description = "Endpoint of the checkout redis"
}

variable "checkout_redis_port" {
  type        = string
  description = "Port of the checkout redis"
}

variable "mq_endpoint" {
  type        = string
  description = "Endpoint of the shared MQ"
}

variable "mq_username" {
  type        = string
  description = "Username for the shared MQ"
}

variable "mq_password" {
  type        = string
  description = "Password for the shared MQ"
}

variable "opentelemetry_enabled" {
  type        = bool
  default     = false
  description = "Enable OpenTelemetry instrumentation"
}

variable "container_insights_setting" {
  type        = string
  default     = "enhanced"
  description = "Container Insights setting for ECS cluster (enhanced or disabled)"

  validation {
    condition     = contains(["enhanced", "disabled"], var.container_insights_setting)
    error_message = "container_insights_setting must be either 'enhanced' or 'disabled'"
  }
}
