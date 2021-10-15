variable "vpc" {}

variable "public_subnets" {
  type        = list(any)
  default     = []
}

variable "private_subnets" {
  type        = list(any)
  default     = []
}

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
