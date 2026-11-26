terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  # Connect Terraform to AWS Emulator
  endpoints {
    ec2 = "https://127.0.0.1:9297"
  }

  # Emulator-specific configuration
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
}

resource "aws_instance" "example" {
  ami                  = "ami-011899242bb902164"
  instance_type        = "t2.micro"
  iam_instance_profile = "TerraformEC2Profile"
  availability_zone    = "us-east-1a"
}
