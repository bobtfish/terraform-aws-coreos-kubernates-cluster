module "master_amitype" {
  source = "github.com/bobtfish/terraform-amitype"
  instance_type = "${var.master-instance_type}"
}

module "master_ami" {
  source = "github.com/bobtfish/terraform-coreos-ami"
  region = "${var.region}"
  channel = "${var.coreos_channel}"
  virttype = "${module.master_amitype.ami_type_prefer_hvm}"
}

resource "aws_launch_configuration" "kubernates-master" {
    image_id = "${module.cmaster_ami.ami_id}"
    instance_type = "${var.master-instance_type}"
    security_groups = ["${var.sg}"]
    associate_public_ip_address = false
    user_data = "${var.kubernates-master-user-data}"
    key_name = "${var.admin_key_name}"
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "kubernates-node" {
  availability_zones = ["${var.primary-az}", "${var.secondary-az}"]
  name = "kubernates-node"
  max_size = "${var.master-cluster-size}"
  min_size = "${var.master-cluster-size}"
  desired_capacity = "${var.master-cluster-size}"
  health_check_grace_period = 120
  health_check_type = "EC2"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.kubernates-master.name}"
  vpc_zone_identifier = [ "${var.primary-az-subnet}", "${var.secondary-az-subnet}" ]
  tag {
    key = "Name"
    value = "kubernates-master"
    propagate_at_launch = true
  }
}

