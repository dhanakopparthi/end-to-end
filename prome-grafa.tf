resource "aws_security_group" "grafana" {
  name        = "grafana"
  description = "this is using for securitygroup"
  vpc_id      = aws_vpc.Vpc_main.id

  ingress {
    description = "this is inbound rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["45.249.77.103/32"]
  }
  ingress {
    description = "this is inbound rule"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "this is inbound rule"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "this is inbound rule"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups    = [aws_security_group.alb-sg.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "grafana"
  }
}
data "template_file" "grafanauser" {
  template = file("pro-gra.sh")

  }
resource "aws_instance" "grafana" {
  ami = var.ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.privatesubnet[2].id
  vpc_security_group_ids = [aws_security_group.grafana.id]
  key_name               = aws_key_pair.deployer.id
  user_data              = data.template_file.grafanauser.rendered
  tags = {
    Name = "stage-grafana"
  }
}

resource "aws_lb_target_group" "prome-tg" {
  name     = "test-prome-tg"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = aws_vpc.Vpc_main.id
}

resource "aws_lb_target_group_attachment" "test-tg-attachment-prometheus" {
  target_group_arn = aws_lb_target_group.prome-tg.arn
  target_id        = aws_instance.grafana.id
  port             = 9090
}

resource "aws_lb_listener" "prometheus-listner" {
  load_balancer_arn = aws_lb.test-alb.arn
  port              = "80"
  protocol          = "HTTP"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prome-tg.arn
  }
}

resource "aws_lb_listener_rule" "prometheus-hostbased" {
  listener_arn = aws_lb_listener.prometheus-listner.arn
#   priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prome-tg.arn
  }

  condition {
    host_header {
      values = ["kopparthi.world-prometheus"]
    }
  }
}


resource "aws_lb_target_group" "grafana-tg" {
  name     = "test-grafana-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.Vpc_main.id
}

resource "aws_lb_target_group_attachment" "test-tg-attachment-grafana" {
  target_group_arn = aws_lb_target_group.grafana-tg.arn
  target_id        = aws_instance.grafana.id
  port             = 3000
}

resource "aws_lb_listener" "grafana-listner" {
  load_balancer_arn = aws_lb.test-alb.arn
  port              = "80"
  protocol          = "HTTP"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana-tg.arn
  }
}

resource "aws_lb_listener_rule" "grafana-hostbased" {
  listener_arn = aws_lb_listener.grafana-listner.arn
#   priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana-tg.arn
  }

  condition {
    host_header {
      values = ["kopparthi.world-grafana"]
    }
  }
}