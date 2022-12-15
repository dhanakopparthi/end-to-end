resource "aws_security_group" "bastion" {
  name        = "bastion"
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
    Name = "bastion"
  }
}

data "template_file" "elastic-userdata" {
  template = file("elastic-kibana.sh")
}

# bastion instance
resource "aws_instance" "bastion" {
  ami = var.ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.publicsubnet[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.deployer.id
  user_data  = data.template_file.elastic-userdata.rendered
  tags = {
    Name = "stage-bastion"
  }
}