## Confiure variables for your eks cluster

variable "region" {
  description = "AWS region"
  default     = "ap-south-1"
}
variable "instance_type1" {
    default = "t3.small"
}
variable "instance_type2" {
    default = "t3.medium"
}
variable "vpc" {
    default = "eksvpc"
}
variable "cidr" {
    default = "10.0.0.0/16" 
}
variable "artifacts_type" {
  default     = "NO_ARTIFACTS"
}
variable "project_name" {
  default     = "eks-terraform"
}
variable "git_clone_depth" {
  default     = "1"
}
variable "buildspec_file_absolute_path" {
  default     = "buildpsecs/buildspec.yml"
}
variable "create_role_and_policy" {
  type        = bool
  default     = true
}
variable "codebuild_role_arn" {
  type        = string
  default     = ""
}
variable "build_image" {
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
}
variable "environment" {
  type        = string
  default     = "develop"
}
variable "codebuild_env_vars" {
  type = object({
    LOAD_VARS           = bool
    EXPORT_PROJECT_NAME = string
  })
  default = {
    LOAD_VARS           = true
    EXPORT_PROJECT_NAME = "eks-terraform"
  }
}
variable "compute_type" {
  default     = "BUILD_GENERAL1_MEDIUM"
}
variable "artifact_bucket_arn" {
  default     = "arn:aws:s3:::*"
  type        = string
}
variable "environment_type" {
  default     = "LINUX_CONTAINER"
}
variable "environment_image" {
  default     = "hashicorp/terraform:1.2.2"
}