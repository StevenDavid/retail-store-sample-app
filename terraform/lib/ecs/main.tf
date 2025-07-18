locals {
  # Observability configuration - not needed anymore
 # enable_observ = var.enable_observ
 # observ_agent_name = var.observ_agent_name
}

module "container_images" {
  source = "../images"

  container_image_overrides = var.container_image_overrides
}