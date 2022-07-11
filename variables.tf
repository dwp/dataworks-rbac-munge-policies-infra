variable "assume_role" {
  type        = string
  default     = "ci"
  description = "IAM role assumed by Concourse when running Terraform"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "image_version" {
  description = "Container tag values."
  default = {
    rbac-munge-policies = {
      development = "debug_6"
      qa          = "debug"
      integration = "debug"
      preprod     = "debug"
      production  = "debug"
    }
  }
}

variable "ecs_hardened_ami_id" {}