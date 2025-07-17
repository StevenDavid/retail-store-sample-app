locals {
  # Datadog configuration
  enable_observ = var.enable_observ != ""
}

module "container_images" {
  source = "../images"

  container_image_overrides = var.container_image_overrides
}