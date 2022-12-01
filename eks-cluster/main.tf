## Create the vpc and subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  name = var.vpc
  cidr = var.cidr
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

## Use eks module to provisioned your eks cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = local.cluster_name
  cluster_version = "1.22"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    attach_cluster_primary_security_group = true
    create_security_group = false
  }
  eks_managed_node_groups = {
    one = {
      name = "node-group-1"
      instance_types = [var.instance_type1]
      min_size     = 1
      max_size     = 3
      desired_size = 1
      vpc_security_group_ids = [
        aws_security_group.node_group_one.id
      ]
    }
    two = {
      name = "node-group-2"
      instance_types = [var.instance_type2]
      min_size     = 1
      max_size     = 2
      desired_size = 1
      vpc_security_group_ids = [
        aws_security_group.node_group_two.id
      ]
    }
  }
}


## Configure DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_locks" {
  hash_key = "LockID"
  name = "terraform-test-locks"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  } 
}

## Set up the backend in S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "my-terraform-bucket-1234"
}
terraform {
  backend "s3" {
    bucket = "my-terraform-bucket-1234"
    key    = "s3/terraform.tfstate"
    region = "ap-south-1"
    }
  }