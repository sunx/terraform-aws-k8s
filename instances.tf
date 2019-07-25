resource "aws_instance" "masters" {
  count = "${var.masters_count}"
  instance_type = "${var.aws_type}"
  ami = "${var.aws_amis}"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.masters.id}"]
  subnet_id = "${aws_subnet.ks.id}"
  user_data = <<-EOF
     #cloud-config
     hostname: "master${count.index + 1}"
     manage_etc_hosts: true
     users:
       - default
       - name: "${var.aws-key-name}"
         sudo: ALL=(ALL) NOPASSWD:ALL
         groups: users, admin
         primary_group: "${var.aws-key-name}"
         shell: /bin/bash
         ssh_authorized_keys:
           - "${file(var.public_key_path)}"
     package_update: true
     packages:
      - software-properties-common
      - uidmap
     apt:
       sources:
         project_atomic.list:
           source: "deb http://ppa.launchpad.net/projectatomic/ppa/ubuntu bionic main"
           keyid: 7AD8C79D
         google_cloud.list:
           source: "deb https://apt.kubernetes.io/ kubernetes-xenial main"
           keyid: BA07F4FB
     packages:
      - podman
      - cri-o-1.14
      - kubelet
      - kubeadm
      - kubectl
     runcmd:
      - echo "KUBELET_EXTRA_ARGS='--cgroup-driver=cgroupfs'" > /etc/default/kubelet
      - sed -i 's/systemd/cgroupfs/g' /etc/crio/crio.conf
      - modprobe br_netfilter
      - echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
      - echo "net.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.d/k8s.conf
      - echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/k8s.conf
      - echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/k8s.conf
      - rm /etc/cni/net.d/100-crio-bridge.conf
      - [ sysctl, -p, /etc/sysctl.d/k8s.conf]
      - [ systemctl, enable, crio.service, kubelet.service ]
      - [ systemctl, restart , crio.service, kubelet.service ]
      EOF
  tags = {
    project = "ks"
    role = "master"
  }
}

resource "aws_instance" "nodes" {
  connection {
    user = "${var.aws-key-name}"
  }
  count = "${var.nodes_count}"
  instance_type = "${var.aws_type}"
  ami = "${var.aws_amis}"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.nodes.id}"]
  subnet_id = "${aws_subnet.ks.id}"
  user_data = <<-EOF
     #cloud-config
     hostname: "node${count.index + 1}"
     manage_etc_hosts: true
     users:
       - default
       - name: "${var.aws-key-name}"
         sudo: ALL=(ALL) NOPASSWD:ALL
         groups: users, admin
         primary_group: "${var.aws-key-name}"
         shell: /bin/bash
         ssh_authorized_keys:
           - "${file(var.public_key_path)}"
     package_update: true
     packages:
      - software-properties-common
      - uidmap
     apt:
       sources:
         project_atomic.list:
           source: "deb http://ppa.launchpad.net/projectatomic/ppa/ubuntu bionic main"
           keyid: 7AD8C79D
         google_cloud.list:
           source: "deb https://apt.kubernetes.io/ kubernetes-xenial main"
           keyid: BA07F4FB
     packages:
      - podman
      - cri-o-1.14
      - kubelet
      - kubeadm
      - kubectl
     runcmd:
      - echo "KUBELET_EXTRA_ARGS='--cgroup-driver=cgroupfs'" > /etc/default/kubelet
      - sed -i 's/systemd/cgroupfs/g' /etc/crio/crio.conf
      - modprobe br_netfilter
      - echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
      - echo "net.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.d/k8s.conf
      - echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/k8s.conf
      - echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/k8s.conf
      - rm /etc/cni/net.d/100-crio-bridge.conf
      - [ sysctl, -p, /etc/sysctl.d/k8s.conf]
      - [ systemctl, enable, crio.service, kubelet.service ]
      - [ systemctl, restart , crio.service, kubelet.service ]
      EOF
  tags = {
    project = "ks"
    role = "node"
  }
}
