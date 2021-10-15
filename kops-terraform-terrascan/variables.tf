variable "kops_cluster" {
  type = object({
    cluster_name = string
    dns_zone = string
    kubernetes_version = string
    worker_node_type = string
    min_worker_nodes  = string
    max_worker_nodes = string
    master_node_type  = string
    region = string
    state_bucket = string
    node_image = string
    nodes=list(any)
    addons=list(string)
  })
}

variable "vpc" {
  type = object({
    cidr = string
    public_subnets = list(string)
    private_subnets = list(string)
    rds_subnets     = list(string)
    elasticache_subnets = list(string)
    dns_hostnames = bool
    dns_support   = bool
    tenancy       = string
  })
}

variable "region" {
  default = "us-west-2"
  type = string
}
