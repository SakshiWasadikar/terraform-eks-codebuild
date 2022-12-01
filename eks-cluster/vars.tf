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