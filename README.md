# Terraform
contains terraforms scripts

#initialize your Terraform workspace. This step downloads the necessary providers and sets up your environment.
terraform init

#To ensure that your code is properly formatted, you can run:
terraform fmt

#To check if the configuration is syntactically correct, run:
terraform validate

#Before applying the configuration, it's a good idea to see what changes Terraform will make
terraform plan

#To create the resources as defined in your Terraform configuration,
terraform apply

#If you ever need to tear down the infrastructure created by your Terraform configuration, you can run:
terraform destroy

#Terraform keeps track of the infrastructure it manages via a state file (terraform.tfstate).
