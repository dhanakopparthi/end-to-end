resource "aws_security_group" "jenkins-sg" {
  name        = "jenkins-devops"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Vpc_main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  /* ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  } */

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
    Name = "jenkins-devops"
  }
}
 data "template_file" "jenkins-userdata" {
  template = file("jenkins.sh")

} 
resource "aws_instance" "jenkins" {
  ami = var.ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.privatesubnet[1].id
  vpc_security_group_ids = [aws_security_group.jenkins-sg.id]
  key_name               = aws_key_pair.deployer.id
  #iam_instance_profile = aws_iam_instance_profile.jenkins-iam.name
  user_data = data.template_file.jenkins-userdata.rendered
  tags = {
    Name = "jenkins-devops"
  }

}

resource "aws_lb_target_group" "jenkins-tg" {
  name     = "test-jenkins-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.Vpc_main.id
}

resource "aws_lb_target_group_attachment" "test-tg-attachment-jenkins" {
  target_group_arn = aws_lb_target_group.jenkins-tg.arn
  target_id        = aws_instance.apache.id
  port             = 8080
}

resource "aws_lb_listener" "jenkins-listner" {
  load_balancer_arn = aws_lb.test-alb.arn
  port              = "80"
  protocol          = "HTTP"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins-tg.arn
  }
}

resource "aws_lb_listener_rule" "jenkins-hostbased" {
  listener_arn = aws_lb_listener.jenkins-listner.arn
#   priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins-tg.arn
  }

  condition {
    host_header {
      values = ["kopparthi.world-jenkins"]
    }
  }
}