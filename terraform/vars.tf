variable "aws_profile" {
  description = "AWS profile"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of VPC used"
  type        = string
}

variable "subnet_public_ids" {
  description = "List of public subnets inside the VPC"
  type        = list(string)
}

variable "subnet_private_ids" {
  description = "List of private subnets inside the VPC"
  type        = list(string)
}

variable "route53_name" {
  description = "Route53 public zone name. Used to create DNS A record for ALB"
  type        = string
}

variable "domain_name" {
  description = "Domain name. Used to find ACM cert"
  type        = string
}

variable "tags" {
  description = "Extra tags to add for all resources"
  type        = map(string)
  default     = {}
}

variable "web_apps" {
  description = "Configuration of multiple apps with the desired traffic split. See Readme.md or examples.tfvars for more details."
  type = map(object({
    ami           = string
    instance_type = string
    path          = string
    weight        = number
  }))
}
