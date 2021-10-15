output "shell_vars" {
  description = "varibles to be exported for kubectl commands"

  value = <<EOF
export AWS_REGION="${var.kops_cluster.region}"
kops export kubecfg ${local.cluster_name}.${var.kops_cluster.dns_zone} --state s3://${var.kops_cluster.state_bucket}
EOF
}
