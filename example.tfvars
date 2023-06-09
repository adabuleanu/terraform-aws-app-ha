aws_profile        = "dev"
aws_region         = "us-west-2"
vpc_id             = "vpc-XXXXXXX"
subnet_public_ids  = ["subnet-AAAAAAAAA", "subnet-BBBBBBBB", "subnet-CCCCCCCCCC"]
subnet_private_ids = ["subnet-XXXXXXXXX", "subnet-YYYYYYYY", "subnet-ZZZZZZZZZZ"]
route53_name       = "example.com"
domain_name        = "*.example.com"
tags = {
  "environment" = "dev"
}

# all traffic goes to app v1
web_apps = {
  "web-app-v1" = {
    ami           = "ami-0a0fca3eb2f42a3e3"
    instance_type = "t2.micro"
    path          = "../bin/eVision-product-ops.linux.1.0.0"
    weight        = 100
  }
}

# 50/50 traffic split between v1 and v2
# web_apps = {
#   "web-app-v1" = {
#     ami           = "ami-0a0fca3eb2f42a3e3"
#     instance_type = "t2.micro"
#     path          = "../bin/eVision-product-ops.linux.1.0.0"
#     weight        = 50
#   },
#   "web-app-v2" = {
#     ami           = "ami-0a0fca3eb2f42a3e3"
#     instance_type = "t2.micro"
#     path          = "../bin/eVision-product-ops.linux.1.0.1"
#     weight        = 50
#   }
# }

# all traffic goes to app v2
# web_apps = {
#   "web-app-v1" = {
#     ami           = "ami-0a0fca3eb2f42a3e3"
#     instance_type = "t2.micro"
#     path          = "../bin/eVision-product-ops.linux.1.0.0"
#     weight        = 0
#   },
#   "web-app-v2" = {
#     ami           = "ami-0a0fca3eb2f42a3e3"
#     instance_type = "t2.micro"
#     path          = "../bin/eVision-product-ops.linux.1.0.1"
#     weight        = 100
#   },
# }
