## Configure the providers
provider "aws" {
  region = var.region
  profile = "default"
}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

## Confiure local variable to define the environment name
data "aws_availability_zones" "available" {}
locals {
  cluster_name = "${terraform.workspace}-cluster"
}
## Configure CodeBuild resource
resource "aws_codebuild_project" "eks-terraform" {
  name = var.project_name
  build_timeout = "120"
  service_role  = var.create_role_and_policy ? aws_iam_role.codebuild_role[0].arn : var.codebuild_role_arn  
  artifacts {
   type = var.artifacts_type
  }
  source {
    type            = "GITHUB"
    location        = "https://github.com/SakshiWasadikar/terraform-eks-codebuild.git"
    git_clone_depth = var.git_clone_depth
    buildspec = "buildspecs/buildspec.yml"
    #templatefile("${path.cwd}/${var.build_spec_file}", {})
  git_submodules_config {
   fetch_submodules = true
    }
  }
   environment {
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    compute_type                = var.compute_type
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = var.codebuild_env_vars["LOAD_VARS"] != false ? var.codebuild_env_vars : {}
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
   }
}
resource "aws_iam_role" "codebuild_role" {
  count = var.create_role_and_policy ? 1 : 0
  name  = "${"${var.project_name}"}_codebuild_deploy_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "codebuild_deploy" {
  role       = aws_iam_role.codebuild_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
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

