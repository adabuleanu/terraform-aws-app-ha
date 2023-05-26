Background
================
The ACME company wants the candidate to deploy their new super duper web application to AWS
or Azure. The company employs some pretty interesting developers and they can on occasion play
russian roulette on the instances. The candidate should keep this in mind (Don't ask why they have
access to production).

Note: application binaries (go) are located in "bin" directory
____

## Dependencies
The application has no dependencies.

Problem 1
================
Use any tool to be able to create a repeatable and predictable product deployment.
Restrictions
There are no restrictions and the candidate should see this as an opportunity to showcase their
ability to perform repeatable and predictable deployments to one of the cloud providers listed
(AWS/Azure).
Verification
The deployment can be verified by issuing a web request to http://{ip}:8080/success

## Solution

#### Architecture

Tools: terraform and AWS

Below you can find the decisions that were taken based on requirements when designing the infrastructure:

| Requirements                                             | Architecture decisions                                                               | Notes                                                                                                                                                                                               |
|----------------------------------------------------------|--------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Application provided as go binaries                      | Deploy application inside EC2 instances. Store app binaries inside S3.                 | For a microservice app (not our case) we would have used k8s to achieve all the requirements. We could have bundled the binaries inside a container and run it inside k8s, but that is out of scope. |
| Highly availability (mitigate russian roulette behavior) | Deploy EC2 instance using EC2 Autoscaller.  |      You can adjust the Autoscaller params to fit your needs.                                                                                                                                                                                               |
| Security (self requirement)                              | Security inside AWS is implemented by SG and by ALB (e.g.: HTTP to HTTPS redirect)   |                                                                                                                                                                                                     |
| Support application updates (problem 2)                  | Expose app in front of an ALB and configure traffic split between multiple targets.                                                       | Using an ALB has other benefits as well, like TLS termination. Provided implementation can support very easy a new app version and can balance traffic in a canary style between versions.           |

#### Requirements

With terraform we only create the infrastructure specific for resolving this problem. 
The other infrastructure components (VPC, Route53, ACM) are not created, instead they are referenced (see `terraform/data.tf` for more details).
In a production scenario you will have different modules to create components and this is the desired workflow.

You also need to update the `terraform/state.tf` file with the desired configuration like S3 bucket.

#### Demo

Review the `terraform/vars.tf` to understand what variables you need to set. The description should be self explanatory.
Below you can find an example of a tfvars file:

```
$ cat example.tfvars
aws_profile="dev"
aws_region="us-west-2"
state_bucket="my-existing-unique-state-bucket"
route53_name="example.com"
domain_name="*.example.com"
tags = {
  "environment" = "dev"
}
web_apps = {
  "web-app-v1" = {
    ami           = "ami-0a0fca3eb2f42a3e3"
    instance_type = "t2.micro"
    path          = "../bin/eVision-product-ops.linux.1.0.0"
    weight        = 100
  }
}
```

The `web_apps` var stores the configuration of multiple apps with the desired traffic split. In the above case:
- we have one app called `web-app-v1`
- the ec2 instance ami for this app is `ami-0a0fca3eb2f42a3e3`
- the ec2 instance size for this app is `t2.micro`
- the app binary path is located at `../bin/eVision-product-ops.linux.1.0.0` (relative to the terraform dir - you can use absolute paths as well)
- all the traffic (100 weight) goes to this app

Below is the code to setup the environment:
```
# initialize the working dir
$ cd terraform
$ terraform init

# review and apply the changes (you can run terraform plan prior to this step)
$ terraform apply --var-file ../example.tfvars

# test app HA by running the script below and delete ec2 instances randomly from the UI or cli
# set the URL var below from the terraform output "app_endpoint" above
$ for i in {1..1000}; do echo $i; curl -m 1 ${URL}; echo ""; sleep 1; done

# delete one random ec2 instance and see the result in the above script 
# make sure the below code uses the correct ec2 instance name (they are defined by the app name)
$ APP="web-app-v1"
$ TARGET=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${APP}" "Name=instance-state-name,Values=running" --output text --query "Reservations[*].Instances[*].InstanceId" | sort -R | head -n 1)
$ echo "Terminating instance ${TARGET}"
$ aws ec2 terminate-instances --instance-ids ${TARGET}
```



Problem 2
================
The application has been updated and the candidate is required to deploy a new version of the
application and take into consideration that downtime should be minimized.

## Solution
 
As mentioned in the solution 1 architecture, the current implementation can support very easy a new app version and can balance traffic in a canary style between versions.

Let's see how we can deploy v2 and shift traffic in canary style. Update the var `web_apps` in .tfvars like this:
```
web_apps = {
  "web-app-v1" = {
    ami           = "ami-0a0fca3eb2f42a3e3"
    instance_type = "t2.micro"
    path          = "../bin/eVision-product-ops.linux.1.0.0"
    weight        = 50
  },
   "web-app-v2" = {
    ami           = "ami-0a0fca3eb2f42a3e3"
    instance_type = "t2.micro"
    path          = "../bin/eVision-product-ops.linux.1.0.1"
    weight        = 50
  },
}
```
In the above example we are deploying a new version of the app and balance 50/50 traffic between the two versions.


Below is the code to setup the environment:
```
# review and apply the changes (you can run terraform plan prior to this step)
$ terraform apply --var-file ../example.tfvars

# test the traffic split by running the script below and check the version balance in the response
# do not forget to set the URL var from the terraform output "app_endpoint" above 
$ for i in {1..1000}; do echo $i; curl -m 1 ${URL}; echo ""; sleep 1; done
```

If you want to split the traffic to v2 version only update the var `web_apps` in .tfvars like this and re-run the above process: 
```
web_apps = {
  "web-app-v1" = {
    ami           = "ami-0a0fca3eb2f42a3e3"
    instance_type = "t2.micro"
    path          = "../bin/eVision-product-ops.linux.1.0.0"
    weight        = 0
  },
   "web-app-v2" = {
    ami           = "ami-0a0fca3eb2f42a3e3"
    instance_type = "t2.micro"
    path          = "../bin/eVision-product-ops.linux.1.0.1"
    weight        = 100
  },
}
```
Note: when setting weight to 0, the autoscaller will resize to 0.

Do not forget to destroy the infrastructure when finished
```
$ terraform destroy --var-file ../example.tfvars
```