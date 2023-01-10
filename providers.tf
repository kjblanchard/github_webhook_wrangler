terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
    backend "s3" {
    bucket   = "supergoon-terraform-plans"
    key      = "github_discord_gw/terraform.tfstate"
    region   = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Environment = "Prod"
      app = "Discord-Github-Webhooks"
    }
  }
}