data "template_file" "data_etcd" {
  template = "$${NAMEETCD}=https://$${HOSTETCD}:2380"
  count    = "${var.masters_count}"

  vars = {
    HOSTETCD = "${element(aws_instance.masters.*.private_ip, count.index)}"
    NAMEETCD = "master${count.index + 1}"
  }
}
data "template_file" "data_config" {
  template = "        - https://$${HOSTETCD}:2379"
  count    = "${var.masters_count}"

  vars = {
    HOSTETCD = "${element(aws_instance.masters.*.private_ip, count.index)}"
  }
}

data "template_file" "data_etcd_yaml" {
  template = "${file("${path.module}/etcd.yaml.tpl")}"
  count    = "${var.masters_count}"

  vars = {
    LOAD_BALANCER_DNS = "${aws_lb.ks.dns_name}"
    LOAD_BALANCER_PORT = "${var.secure-port}"
    HOSTETCD = "${element(aws_instance.masters.*.private_ip, count.index)}"
    NAME = "master${count.index + 1}"
    initial-cluster = "${join(",", data.template_file.data_etcd.*.rendered)}"
    DOMAIN = "${var.DOMAIN}"
    KSSUBNET = "${var.KSSUBNET}"
  }
}
data "template_file" "data_etcd_service" {
  template = "${file("${path.module}/etcd.service.tpl")}"
  count    = "${var.masters_count}"

  vars = {
    HOSTETCD = "${element(aws_instance.masters.*.private_ip, count.index)}"
    NAME = "master${count.index + 1}"
    initial-cluster = "${join(",", data.template_file.data_etcd.*.rendered)}"
  }
}

data "template_file" "data_config_yaml" {
  template = "${file("${path.module}/config.yaml.tpl")}"
  count    = "${var.masters_count}"

  vars = {
    LOAD_BALANCER_DNS = "${aws_lb.ks.dns_name}"
    LOAD_BALANCER_PORT = "${var.secure-port}"
    ENDPOINTS = "${join("\n", data.template_file.data_config.*.rendered)}"
    DOMAIN = "${var.DOMAIN}"
    KSSUBNET = "${var.KSSUBNET}"
  }
}

data "template_file" "ca-cert" {
  template = "${file("${path.module}/ca-csr.json.tpl")}"

  vars = {
    COUNTRY = "${var.COUNTRY}"
    LOCALITY = "${var.LOCALITY}"
    OU = "${var.OU}"
  }
}
resource "local_file" "config" {
  content  = "${data.template_file.ca-cert.rendered}"
  filename = "ca-csr.json"
}
