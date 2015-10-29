module "master_amitype" {
  source = "github.com/terraform-community-modules/tf_aws_virttype"
  instance_type = "${var.master-instance_type}"
}

module "master_ami" {
  source = "github.com/terraform-community-modules/tf_aws_coreos_ami"
  region = "${var.region}"
  channel = "${var.coreos-channel}"
  virttype = "${module.master_amitype.prefer_hvm}"
}

resource "template_file" "masters_cloud_init" {
  filename = "master.yaml.tpl"
  vars {
    kubernetes_release = "${var.kubernetes_release}"
    master_ip = "${aws_elb.kubernetes_master.dns_name}"
    flanneld_cidr = "${var.flanneld_cidr}"
  }
}

resource "aws_launch_configuration" "kubernetes-master" {
  image_id = "${module.master_ami.ami_id}"
  instance_type = "${var.master-instance_type}"
  security_groups = ["${var.sg}"]
  associate_public_ip_address = true
  user_data = "${template_file.masters_cloud_init.rendered}"
  key_name = "${var.admin_key_name}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kubernetes-master" {
  availability_zones = ["${var.primary-az}", "${var.secondary-az}"]
  name = "kubernetes-master"
  max_size = "${var.master-cluster-size}"
  min_size = "${var.master-cluster-size}"
  desired_capacity = "${var.master-cluster-size}"
  health_check_grace_period = 60
  health_check_type = "EC2"
  force_delete = true
  load_balancers = [
    "${aws_elb.kubernetes_master.id}",
    "${aws_elb.kubernetes_master_public.id}"
  ]
  launch_configuration = "${aws_launch_configuration.kubernetes-master.name}"
  vpc_zone_identifier = [ "${var.primary-az-subnet}", "${var.secondary-az-subnet}" ]
  tag {
    key = "Name"
    value = "kubernetes-master"
    propagate_at_launch = true
  }
}

resource "aws_elb" "kubernetes_master" {
  name = "kubernetes-master"
  subnets = [ "${var.primary-az-subnet}", "${var.secondary-az-subnet}" ]
  cross_zone_load_balancing = true
  security_groups = ["${var.sg}"]
  internal = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8080/"
    interval = 30
  }

  listener {
    instance_port = 2379
    instance_protocol = "http"
    lb_port = 2379
    lb_protocol = "http"
  }

  listener {
    instance_port = 2380
    instance_protocol = "http"
    lb_port = 2380
    lb_protocol = "http"
  }

  listener {
    instance_port = 4001
    instance_protocol = "http"
    lb_port = 4001
    lb_protocol = "http"
  }

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 8080
    lb_protocol = "http"
  }
}

resource "aws_elb" "kubernetes_master_public" {
  name = "kubernetes-master-public"
  subnets = [ "${var.primary-az-subnet}", "${var.secondary-az-subnet}" ]
  cross_zone_load_balancing = true
  security_groups = ["${var.sg}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8080/"
    interval = 30
  }

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

output "public_url" {
  value = "http://${aws_elb.kubernetes_master_public.dns_name}"
}
