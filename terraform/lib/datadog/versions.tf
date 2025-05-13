terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

provider "datadog" {
  api_url = var.datadog_api_url
  api_key = var.datadog_api_key
  app_key = "3fc4d67f883d14fbd1def1fcb013f112b6db4e38"
}


