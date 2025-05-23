resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment_name}-cluster"
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "retailstore.local"
  description = "Service discovery namespace"
  vpc         = var.vpc_id
}