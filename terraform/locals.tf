locals {
  asg_group_tags = flatten([
    for node_key, node_value in var.node_groups : [
      for tag_key, tag_value in local.autoscaling_tags : {
        id    = "${tag_key}-${node_key}"
        name  = node_key
        key   = tag_key
        value = tag_value
      }
    ]
  ])
  autoscaling_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    "k8s.io/cluster-autoscaler/enabled" : true,
  }
  cluster_autoscaler_ns = "cluster-autoscaler"
  cluster_autoscaler_sa = "cluster-autoscaler"
}