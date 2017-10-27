variable aws_region {
  default = "eu-west-1"
}

provider "aws" {
  profile     = "jcd-ppr"
  region      = "${var.aws_region}"
}



resource "aws_api_gateway_integration_response" "example" {
  # (resource arguments)
}