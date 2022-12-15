#apache-security group
resource "aws_security_group" "nexus" {
  name        = "nexus"
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
    description     = "this is inbound rule"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 8081
    to_port          = 8081
    protocol         = "tcp"
    security_groups    = [aws_security_group.alb-sg.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description = "this is inbound rule"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "nexus"
  }
}
#apacheuserdata
data "template_file" "nexususer" {
  template = file("nexus.sh")

}
# apache instance
resource "aws_instance" "nexus" {
  ami                    = var.ami
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.privatesubnet[2].id
  vpc_security_group_ids = [aws_security_group.nexus.id]
  key_name               = aws_key_pair.deployer.id
  user_data              = data.template_file.nexususer.rendered
  tags = {
    Name = "stage-nexus"
  }
}

resource "aws_lb_target_group" "nexus-tg" {
  name     = "tg-nexus"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.Vpc_main.id
}
    
resource "aws_lb_listener" "nexus-listner" {
  load_balancer_arn = aws_lb.test-alb.arn
  port              = "80"
  protocol          = "HTTP"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg-attachment-nexus" {
  target_group_arn = aws_lb_target_group.nexus-tg.arn
  target_id        = aws_instance.nexus.id
  port             = 8081
}



resource "aws_lb_listener_rule" "nexus-hostbased" {
  listener_arn = aws_lb_listener.nexus-listner.arn
#   priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus-tg.arn
  }

  condition {
    host_header {
      values = ["kopparthi.world-nexus"]
    }
  }
}
