module "node_amitype" {
  source = "github.com/terraform-community-modules/tf_aws_virttype"
  instance_type = "${var.node-instance_type}"
}

module "node_ami" {
  source = "github.com/terraform-community-modules/tf_aws_coreos_ami"
  region = "${var.region}"
  channel = "${var.coreos-channel}"
  virttype = "${module.node_amitype.prefer_hvm}"
}

resource "template_file" "nodes_cloud_init" {
  filename = "node.yaml.tpl"
  vars {
    kubernetes_release = "${var.kubernetes_release}"
    master_ip = "${aws_elb.kubernetes_master.dns_name}"
    flanneld_cidr = "${var.flanneld_cidr}"
  }
}

resource "aws_launch_configuration" "kubernetes-node" {
  image_id = "${module.node_ami.ami_id}"
  instance_type = "${var.node-instance_type}"
  security_groups = ["${var.sg}"]
  associate_public_ip_address = true
  user_data = "${template_file.nodes_cloud_init.rendered}"
  key_name = "${var.admin_key_name}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kubernetes-node" {
  availability_zones = ["${var.primary-az}", "${var.secondary-az}"]
  name = "kubernetes-node"
  max_size = "${var.node-cluster-size}"
  min_size = "${var.node-cluster-size}"
  desired_capacity = "${var.node-cluster-size}"
  health_check_grace_period = 60
  health_check_type = "EC2"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.kubernetes-node.name}"
  vpc_zone_identifier = [ "${var.primary-az-subnet}", "${var.secondary-az-subnet}" ]
  tag {
    key = "Name"
    value = "kubernetes-node"
    propagate_at_launch = true
  }
}

