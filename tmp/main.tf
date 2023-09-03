# terraform configuration
terraform {
  required_version = "= 1.4.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.64.0"
    }
  }
}
# provider
provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

module "webserver" {
  source        = "./modules/nginx_server"
  instance_type = "t2.micro"

}

output "instance_id" {
  value = module.webserver.instance_id
}