#To ensure that your code is properly formatted, you can run:
#`terraform fmt`

#To check if the configuration is syntactically correct, run:
#`terraform validate`

#Before applying the configuration, it's a good idea to see what changes Terraform will make, run: 
#`terraform plan`

#To create the resources as defined in your Terraform configuration, run: 
#`terraform apply`

#If you ever need to tear down the infrastructure created by your Terraform configuration, you can run:
#`terraform destroy`

variable "env" {
  description = "Enter Environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "qat", "prd"], var.env)
    error_message = "Invalid environment. Allowed values are: dev, qat, prd."
  }
}

variable "ami" {
  description = "Enter AMI Id."
  type        = string
}

locals {
  environments = {
    dev = {
      desired_capacity         = 1
      max_size                 = 2
      min_size                 = 1
      subnets                  = ["subnet-Axxxx", "subnet-Bxxxx"]
      iam_profile              = "main-Ec2-role-dev"
      security_group_ids       = ["sg-jenkins", "sg-ansible"]
      cpu_utilization          = 70
      keypair                  = "UNIXKeyDV"
    }
    qat = {
      desired_capacity         = 1
      max_size                 = 2
      min_size                 = 1
      subnets                  = ["subnet-Axxxx", "subnet-Bxxxx"]
      iam_profile              = "main-Ec2-role-qat"
      security_group_ids       = ["sg-jenkins", "sg-ansible"]
      cpu_utilization          = 70
      keypair                  = "UNIXKeyQA"
    }
    prd = {
      desired_capacity         = 1
      max_size                 = 2
      min_size                 = 1
      subnets                  = ["subnet-Axxxx", "subnet-Bxxxx"]
      iam_profile              = "main-Ec2-role-prd"
      security_group_ids       = ["sg-jenkins", "sg-ansible"]
      cpu_utilization          = 70
      keypair                  = "UNIXKeyPRD"
    }
  }
}

resource "aws_launch_template" "abc_launch_template" {
  name = "abc-template-${var.env}"

  block_device_mappings {
    device_name = "/dev/sdf"
    
    # Add additional Block Device Mappings here if needed
  }
  ebs_optimized = true
  image_id      = var.ami
  instance_type = "m5.8xlarge"

  key_name = local.environments[var.env].keypair

  monitoring {
    enabled = true
  }

  user_data = filebase64("${path.module}/example.sh")

  vpc_security_group_ids = local.environments[var.env].security_group_ids
    
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "abc-${var.env}"
      Application = "GSD"
      Owner       = "abc"
    }
  }
}

resource "aws_autoscaling_group" "abc_autoscale" {
  desired_capacity = local.environments[var.env].desired_capacity
  max_size         = local.environments[var.env].max_size
  min_size         = local.environments[var.env].min_size

  vpc_zone_identifier = local.environments[var.env].subnets

  launch_template {
    id = aws_launch_template.abc_launch_template.id
  }

  tag {
    key                 = "Owner"
    value               = "abc"
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = "GSD"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "asg_cpu_policy" {
  autoscaling_group_name = "abc_autoscale"
  name                   = "asc-cpu-policy-${var.env}"
  scaling_adjustment     = 1
  cooldown               = 300
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = local.environments[var.env].cpu_utilization
  }

  depends_on = [aws_autoscaling_group.abc_autoscale]
}
