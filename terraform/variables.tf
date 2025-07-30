variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "The AWS region to deploy resources in"
}

variable "local_public_key_path" {
  type        = string
  default     = "/home/angel.cruz/.ssh/id_rsa.pub"
  description = "Path to the local public key for the Jenkins instance"
}