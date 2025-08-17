terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_lightsail_instance" "my_lightsail" {
  # (resource arguments)
  name = "Ubuntu-1"
    availability_zone = "us-east-2a"
    blueprint_id = "ubuntu_24_04"
    bundle_id = "micro_3_0"
}
