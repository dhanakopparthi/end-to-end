resource "aws_security_group" "alb-sg" {
  name        = "alb"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.Vpc_main.id

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "albsg"
  }
}

resource "aws_lb" "test-alb" {
  name               = "test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.publicsubnet[0].id, aws_subnet.publicsubnet[1].id, aws_subnet.publicsubnet[2].id]



  tags = {
    Environment = "alb-sg"
  }
}


