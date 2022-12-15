# Create security group
resource "aws_security_group" "apache-sg" {
  name        = "apache-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Vpc_main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
 
 ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["45.249.77.103/32"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
 ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
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
    Name = "apache-sg"
  }
}

 data "template_file" "apache-userdata" {
  template = file("apache.sh")

  
}

# Creation of ec2 
resource "aws_instance" "apache" {
  ami = var.ami
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.id
  subnet_id = aws_subnet.privatesubnet[1].id
  vpc_security_group_ids = [aws_security_group.apache-sg.id]
  user_data  = data.template_file.apache-userdata.rendered

  tags = {
    Name = "apache-devops"

  }
}

resource "aws_lb_target_group" "apache-tg-1" {
  name     = "test-tg-apache-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Vpc_main.id
}

resource "aws_lb_target_group_attachment" "test-tg-attachment-apache-1" {
  target_group_arn = aws_lb_target_group.apache-tg-1.arn
  target_id        = aws_instance.apache.id
  port             = 80
}

resource "aws_lb_listener" "apache-listner" {
  load_balancer_arn = aws_lb.test-alb.arn
  port              = "80"
  protocol          = "HTTP"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apache-tg-1.arn
  }
}

resource "aws_lb_listener_rule" "apache-hostbased" {
  listener_arn = aws_lb_listener.apache-listner.arn
#   priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apache-tg-1.arn
  }

  condition {
    host_header {
      values = ["kopparthi.world-apache"]
    }
  }
}