module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.16"

  name               = "${var.cluster_name}-vpc"
  cidr               = var.vpc_cidr
  azs                = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets    = var.private_subnets_cidrs
  public_subnets     = var.public_subnets_cidrs
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}
