variable "region" {}

variable "domain_name" {} 

variable "alarm_sns_topic" {}


variable "creator" {
    description = "Name of creator"
    type = string
    default = "claudia"
}

variable "techstack" {
    description = "Choose your tech stack - php80, php74, java11, java8, tomcat85j11, tomcat85j8, go344, docker"
    type = string
    default = "php80"
}

variable "eb_env_name" {
    description = "Elastic beanstalk environment name"
    type = string
    default = "abk-tf-app-env"
}

variable "app_version" {
    description = "Application version"
    type = string
    default = "my-default-version"
}

variable "eb_stack" {
    description = "Platform for Elastic beanstalk environment" 
    type = map(string)
    default = {
        php80 = "64bit Amazon Linux 2 v3.3.9 running PHP 8.0"
        php74 = "64bit Amazon Linux 2 v3.3.9 running PHP 7.4"
        java11 = "64bit Amazon Linux 2 v3.2.10 running Corretto 11"
        java8 = "64bit Amazon Linux 2 v3.2.10 running Corretto 8"
        tomcat85j11 = "64bit Amazon Linux 2 v4.2.10 running Tomcat 8.5 Corretto 11"
        tomcat85j8 = "64bit Amazon Linux 2 v4.2.10 running Tomcat 8.5 Corretto 8"
        go1 = "64bit Amazon Linux 2 v3.4.4 running Go 1"
        docker = "64bit Amazon Linux 2 v3.4.10 running Docker"
    }
}

variable "app_tags" {
  type = string
}

variable "application_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ec2_subnets" {
  type = string
}

variable "elb_subnets" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "disk_size" {
  type = string
}

variable "keypair" {
  type = string
}

variable "sshrestrict" {
  type = string
}



