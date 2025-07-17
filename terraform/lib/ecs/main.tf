locals {
  # Datadog configuration
  datadog_enabled = var.enable_datadog != ""
}

module "container_images" {
  source = "../images"

  container_image_overrides = var.container_image_overrides
}