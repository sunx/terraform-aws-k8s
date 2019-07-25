resource "aws_lb" "ks" {
  name = "ks"

  load_balancer_type = "network"
  internal           = false
  subnets         = ["${aws_subnet.ks.id}"]

  }

resource "aws_lb_listener" "apiserver-https" {
  load_balancer_arn = "${aws_lb.ks.arn}"
  protocol          = "TCP"
  port              = "6443"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.masters.arn}"
  }
}
resource "aws_lb_target_group" "masters" {
  vpc_id      = "${aws_vpc.default.id}"
  target_type = "instance"
  protocol = "TCP"
  port     = 6443
  health_check {
    protocol = "TCP"
    port     = 6443
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval = 10
  }
}

resource "aws_lb_target_group_attachment" "masters" {
  count = "${var.masters_count}"
  target_group_arn = "${aws_lb_target_group.masters.arn}"
  target_id        = "${element(aws_instance.masters.*.id, count.index)}"
  port             = 6443
}

resource "aws_lb_target_group" "ingrass-http" {
  vpc_id      = "${aws_vpc.default.id}"
  target_type = "instance"

  protocol = "TCP"
  port     = 80
  health_check {
    protocol = "TCP"
    port     = 80
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval = 10
  }
}
resource "aws_lb_target_group_attachment" "ingrass-http" {
  count = "${var.nodes_count}"
  target_group_arn = "${aws_lb_target_group.ingrass-http.arn}"
  target_id        = "${element(aws_instance.nodes.*.id, count.index)}"
  port             = 80
}
resource "aws_lb_target_group" "ingrass-https" {
  vpc_id      = "${aws_vpc.default.id}"
  target_type = "instance"

  protocol = "TCP"
  port     = 443
  health_check {
    protocol = "TCP"
    port     = 443
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval = 10
  }
}
resource "aws_lb_target_group_attachment" "ingrass-https" {
  count = "${var.nodes_count}"
  target_group_arn = "${aws_lb_target_group.ingrass-https.arn}"
  target_id        = "${element(aws_instance.nodes.*.id, count.index)}"
  port             = 443
}
