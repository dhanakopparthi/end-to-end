# Create security group
resource "aws_security_group" "tomcat-sg" {
  name        = "tomcat-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Vpc_main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
 
 ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    security_groups    = [aws_security_group.alb-sg.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  
  ingress {
    description     = "this is inbound rule"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "tomcat-sg"
  }
}

  data "template_file" "tomcat-userdata" {
  template = file("tomcat.sh")
  }


resource "aws_instance" "tomcat" {
  ami = var.ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.privatesubnet[0].id
  vpc_security_group_ids = [aws_security_group.tomcat-sg.id]
  key_name               = aws_key_pair.deployer.id
  user_data              = data.template_file.tomcat-userdata.rendered
  tags = {
    Name = "stage-tomcat"
  }
}

resource "aws_lb_target_group" "tomcat-tg" {
  name     = "test-tomcat-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.Vpc_main.id
}

resource "aws_lb_target_group_attachment" "tomcat-tg" {
  target_group_arn = aws_lb_target_group.tomcat-tg.arn
  target_id        = aws_instance.tomcat.id
  port             = 8080
}

resource "aws_lb_listener" "tomcat-listner" {
  load_balancer_arn = aws_lb.test-alb.arn
  port              = "80"
  protocol          = "HTTP"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tomcat-tg.arn
  }
}

resource "aws_lb_listener_rule" "tomcat-hostbased" {
  listener_arn = aws_lb_listener.tomcat-listner.arn
#   priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tomcat-tg.arn
  }

  condition {
    host_header {
      values = ["kopparthi.world-tomcat"]
    }
  }
}

