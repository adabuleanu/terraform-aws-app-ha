provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.aws_profile
  region                   = var.aws_region
}
