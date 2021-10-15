locals {
  cluster_name = "${var.kops_cluster.cluster_name}-${terraform.workspace}"
}


resource "null_resource" "output" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.root}/output/${local.cluster_name}"
  }
}

data "template_file" "public_subnet_map" {
  count    = length(var.public_subnets)
  template = "${file("${path.module}/templates/kops/subnet.tmpl.yaml")}"

  vars = {
    name = "PublicSubnet-${count.index}"
    cidr = var.public_subnets[count.index].cidr_block
    id = var.public_subnets[count.index].id
    type = "Public"
    az = var.public_subnets[count.index].availability_zone
  }
}

data "template_file" "node_group_definitions" {
  count    = length(var.kops_cluster.nodes)
  template = "${file("${path.module}/templates/kops/agents.tmpl.yaml")}"

  vars = {
    name = var.kops_cluster.nodes[count.index].name
    role = var.kops_cluster.nodes[count.index].role
    instanceType = var.kops_cluster.nodes[count.index].instanceType
    minSize = var.kops_cluster.nodes[count.index].minSize
    maxSize = var.kops_cluster.nodes[count.index].maxSize
  }
}

data "template_file" "addons" {
  count    = length(var.kops_cluster.addons)
  template = "${file("${path.module}/templates/kops/addons.tmpl.yaml")}"

  vars = {
    name = var.kops_cluster.addons[count.index]
  }
}

data "template_file" "private_subnet_map" {
  count    = length(var.private_subnets)
  template = "${file("${path.module}/templates/kops/subnet.tmpl.yaml")}"

  vars = {
    name = "PrivateSubnet-${count.index}"
    cidr = var.private_subnets[count.index].cidr_block
    id = var.private_subnets[count.index].id
    type = "Private"
    az = var.private_subnets[count.index].availability_zone
  }
}

data "template_file" "kops_values_file" {
  template = "${file("${path.module}/templates/kops/values.tmpl.yaml")}"

  vars = {
    cluster_name = local.cluster_name
    dns_zone = var.kops_cluster.dns_zone
    kubernetes_version = var.kops_cluster.kubernetes_version
    state_bucket = var.kops_cluster.state_bucket
    node_image = var.kops_cluster.node_image
    vpc_id = var.vpc.id
    vpc_cidr = var.vpc.cidr_block
    region = var.kops_cluster.region
    private_subnets = join("", data.template_file.private_subnet_map.*.rendered)
    public_subnets = join("", data.template_file.public_subnet_map.*.rendered)
    nodes = join("", data.template_file.node_group_definitions.*.rendered)
    worker_node_type = var.kops_cluster.worker_node_type
    min_worker_nodes = var.kops_cluster.min_worker_nodes
    max_worker_nodes = var.kops_cluster.max_worker_nodes
    master_node_type = var.kops_cluster.master_node_type
    addons = join("", data.template_file.addons.*.rendered)
  }
}

resource "local_file" "rendered_kops_values_file" {
  content  = data.template_file.kops_values_file.rendered
  filename = "${path.root}/output/values-rendered.yaml"
}

resource "null_resource" "provision_kops" {
  depends_on = [ local_file.rendered_kops_values_file ]

  triggers = {
    bucket = var.kops_cluster.state_bucket
    dns_zone = var.kops_cluster.dns_zone
    cluster_name = local.cluster_name
  }

  provisioner "local-exec" {
    environment = {
      KOPS_STATE_STORE = "s3://${var.kops_cluster.state_bucket}"
    }

    command = <<EOT
    kops toolbox template --template ${path.module}/templates/kops/cluster.tmpl.yaml \
    --template ${path.module}/templates/kops/worker.tmpl.yaml \
    --template ${path.module}/templates/kops/master.tmpl.yaml --values ${path.root}/output/values-rendered.yaml > ${path.root}/output/output.yaml
    kops create -f ${path.root}/output/output.yaml
    kops create secret --name ${local.cluster_name}.${var.kops_cluster.dns_zone} sshpublickey admin -i ~/.ssh/id_rsa.pub
    kops update cluster ${local.cluster_name}.${var.kops_cluster.dns_zone} --yes
EOT
  }

  provisioner "local-exec" {
    when = destroy
    environment = {
      KOPS_STATE_STORE = "s3://${self.triggers.bucket}"
    }
    command = "kops delete cluster ${self.triggers.cluster_name}.${self.triggers.dns_zone} --yes"
  }
}
