module "eks" {
  source                  = "terraform-aws-modules/eks/aws"
  version                 = "~> 20.31"
  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  eks_managed_node_groups = var.node_groups
  eks_managed_node_group_defaults = {
    tags = local.autoscaling_tags
  }

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

}

resource "aws_autoscaling_group_tag" "this" {
  for_each = { for t in local.asg_group_tags : t.id => t }

  autoscaling_group_name = module.eks.eks_managed_node_groups[each.value.name].node_group_autoscaling_group_names.0

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = true
  }
}

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}


