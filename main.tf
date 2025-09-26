resource "awscc_elasticbeanstalk_application" "example" {
  application_name = "example"
  description      = "example"
}


locals {
  solution_stacks = [
    "64bit Amazon Linux 2023 v4.1.2 running Python 3.11",
    "64bit Amazon Linux 2023 v4.1.2 running Python 3.9",
    "64bit Amazon Linux 2023 v4.1.2 running Node.js 18",
  ]
}

resource "awscc_elasticbeanstalk_configuration_template" "example" {
  for_each = toset(local.solution_stacks)

  application_name    = awscc_elasticbeanstalk_application.example.application_name
  description         = "My sample configuration template for ${each.value}"
  solution_stack_name = each.value
  option_settings = [{
    namespace   = "aws:autoscaling:launchconfiguration"
    option_name = "IamInstanceProfile"
    value       = "testRoleEC2"
    },
    {
      namespace   = "aws:autoscaling:launchconfiguration"
      option_name = "InstanceType"
      value       = "t3.large"
    },
    {
      namespace   = "aws:elasticbeanstalk:command"
      option_name = "DeploymentPolicy"
      value       = "Immutable"
    },
    {
      namespace   = "aws:elasticbeanstalk:environment"
      option_name = "LoadBalancerType"
      value       = "application"
    },
    {
      namespace   = "aws:elbv2:loadbalancer"
      option_name = "AccessLogsS3Enabled"
      value       = "false"
    },
    {
      namespace   = "aws:elasticbeanstalk:environment"
      option_name = "LoadBalancerIsShared"
      value       = "false"
    }]
}
