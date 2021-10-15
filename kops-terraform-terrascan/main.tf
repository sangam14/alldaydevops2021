module "network" {
  source          = "./modules/vpc"
  environment     = terraform.workspace
  vpc             = var.vpc
  cluster_name    = "terrascan-demo-kops"
}

module "kubernetes" {
  source              = "./modules/kubernetes"
  vpc                 = module.network.vpc
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets
  kops_cluster    = var.kops_cluster
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = "arn"
  log_destination = "log"
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.ok_vpc.id
}

