module "cluster_autoscaler_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                        = "${var.cluster_name}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    cluster_autoscaler = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.cluster_autoscaler_ns}:${local.cluster_autoscaler_sa}"]
    }
  }
}