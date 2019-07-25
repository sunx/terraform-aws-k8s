provider "aws" {
  region = "${var.aws-region}"
  profile = "${var.aws-profile}"
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

locals {
 count = "${var.masters_count}"
 masterslist = "${aws_instance.masters.*.public_ip}"
 mastercrop = "${slice(local.masterslist, 1, var.masters_count)}"
}

resource "null_resource" "ca-certs" {
  provisioner "local-exec" {
    command = "./certs.sh"
  }
}
resource "null_resource" "copy" {
  count = "${var.masters_count}"
  connection {
    type = "ssh"
    user = "${var.aws-key-name}"
    host = "${element(aws_instance.masters.*.public_ip, count.index)}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
  provisioner "file" {
    content     = "${element(data.template_file.data_etcd_yaml.*.rendered, count.index)}"
    destination = "/tmp/etcd.yml"
    connection {
      type = "ssh"
      user = "${var.aws-key-name}"
      host = "${element(aws_instance.masters.*.public_ip, count.index)}"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }
  provisioner "file" {
    content     = "${element(data.template_file.data_config_yaml.*.rendered, count.index)}"
    destination = "/tmp/config.yml"
    connection {
      type = "ssh"
      user = "${var.aws-key-name}"
      host = "${element(aws_instance.masters.*.public_ip, count.index)}"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }
  provisioner "file" {
    content     = "${element(data.template_file.data_etcd_service.*.rendered, count.index)}"
    destination = "/tmp/etcd.service"
    connection {
      type = "ssh"
      user = "${var.aws-key-name}"
      host = "${element(aws_instance.masters.*.public_ip, count.index)}"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }

  provisioner "file" {
    source     = "certs/pki"
    destination = "/tmp/"
  }
  provisioner "file" {
    source     = "etcd/etcd"
    destination = "/tmp/etcd"
  }
  provisioner "remote-exec" {
    inline     = [
      "sudo mv /tmp/config.yml /etc/kubernetes/config.yml",
      "sudo mv /tmp/etcd.yml /etc/kubernetes/etcd.yml",
      "sudo mv /tmp/etcd.service /etc/systemd/system/etcd.service",
      "sudo mkdir -p /etc/kubernetes/pki/etcd",
      "sudo cp /tmp/pki/* /etc/kubernetes/pki/",
      "sudo mv /tmp/pki/* /etc/kubernetes/pki/etcd/",
      "sudo chown root:root -R /etc/kubernetes/",
      "sudo chmod 400 /etc/kubernetes/pki/ca.key",
      "sudo chmod 400 /etc/kubernetes/pki/etcd/ca.key",
      "sudo cp /tmp/etcd /usr/local/bin/",
      "sudo chmod +x /usr/local/bin/etcd",
      "sudo chown root:root /etc/systemd/system/etcd.service",
      "sudo kubeadm init phase certs etcd-server --config=/etc/kubernetes/etcd.yml",
      "sudo kubeadm init phase certs etcd-peer --config=/etc/kubernetes/etcd.yml",
      "sudo kubeadm init phase certs etcd-healthcheck-client --config=/etc/kubernetes/etcd.yml",
      "sudo kubeadm init phase certs apiserver-etcd-client --config=/etc/kubernetes/etcd.yml",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart etcd",
    ]
  }
}
resource "null_resource" "init" {
  connection {
    type = "ssh"
    user = "${var.aws-key-name}"
    host = "${aws_instance.masters.0.public_ip}"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline     = [ 
      "sudo kubeadm init --config=/etc/kubernetes/config.yml --cri-socket '/var/run/crio/crio.sock' --ignore-preflight-errors=all",
    ]
  }
  provisioner "local-exec" {
    command = <<EOT
       echo `ssh "${aws_instance.masters.0.public_ip}" 'sudo kubeadm init phase upload-certs --upload-certs --config=/etc/kubernetes/config.yml| tail -n1'` > CERTIFICATE.var;
       echo `ssh "${aws_instance.masters.0.public_ip}" 'sudo kubeadm token create'` > TOKEN.var;
       echo `ssh "${aws_instance.masters.0.public_ip}" "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null |openssl dgst -sha256 -hex | sed 's/^.* //'"` > DISCOVERY.var;
    EOT
  }
  depends_on = [
    "null_resource.copy",
  ]
}

resource "null_resource" "control-plane" {
  count = "${var.masters_count}"
  provisioner "local-exec" {
    command = <<EOT
       ssh "${element(local.mastercrop, count.index)}" "sudo kubeadm join ${aws_lb.ks.dns_name}:6443 --cri-socket '/var/run/crio/crio.sock' --token `cat TOKEN.var` --discovery-token-ca-cert-hash sha256:`cat DISCOVERY.var` --control-plane --certificate-key `cat CERTIFICATE.var` --ignore-preflight-errors=NumCPU" ;
    EOT
  }
  depends_on = [
    "null_resource.init",
  ]
}

resource "null_resource" "add-cni" {
  provisioner "local-exec" {
    command = <<EOT
       ssh "${aws_instance.masters.0.public_ip}" "sudo kubectl apply --kubeconfig=/etc/kubernetes/admin.conf -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml"
    EOT
  }
  depends_on = [
    "null_resource.control-plane",
  ]
}

resource "null_resource" "join" {
  count = "${var.nodes_count}"
  provisioner "local-exec" {
    command = <<EOT
       ssh "${element(aws_instance.nodes.*.public_ip, count.index)}" "sudo kubeadm join ${aws_lb.ks.dns_name}:6443 --cri-socket '/var/run/crio/crio.sock' --token `cat TOKEN.var` --discovery-token-ca-cert-hash sha256:`cat DISCOVERY.var`" ;
       rm -f TOKEN.var ;
       rm -f DISCOVERY.var ;
       rm -f CERTIFICATE.var
    EOT
  }
  depends_on = [
    "null_resource.add-cni",
  ]
}

resource "null_resource" "restart-crio-masters" {
  count = "${var.masters_count}"
  provisioner "local-exec" {
    command = <<EOT
       ssh "${element(aws_instance.masters.*.public_ip, count.index)}" "sudo systemctl restart crio" ;
    EOT
  }
  depends_on = [
    "null_resource.join",
  ]
}

resource "null_resource" "restart-crio-nodes" {
  count = "${var.nodes_count}"
  provisioner "local-exec" {
    command = <<EOT
       ssh "${element(aws_instance.nodes.*.public_ip, count.index)}" "sudo systemctl restart crio" ;
    EOT
  }
  depends_on = [
    "null_resource.join",
  ]
}

