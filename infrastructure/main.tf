# Create an EC2 instance

# Provider
provider "aws" {

  # Which region we use
  region = "eu-west-1"
}


# CONTROLLER NODE


# Security group
resource "aws_security_group" "minikube_sg" {
    name = var.sg_name
  # Tags
  tags = {
    Name = var.sg_name

  }

}

# NSG Rules
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_22" {

  security_group_id = aws_security_group.minikube_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  cidr_ipv4         = var.vpc_ssh_inbound_cidr
  tags = {
    Name = "Allow_SSH"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_80" {

  security_group_id = aws_security_group.minikube_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  cidr_ipv4         = var.vpc_ssh_inbound_cidr
  tags = {
    Name = "Allow_http"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_30001" {

  security_group_id = aws_security_group.minikube_sg.id
  from_port         = 30001
  ip_protocol       = "tcp"
  to_port           = 30001
  cidr_ipv4         = var.vpc_ssh_inbound_cidr
  tags = {
    Name = "Allow_30001"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_9000" {

  security_group_id = aws_security_group.minikube_sg.id
  from_port         = 9000
  ip_protocol       = "tcp"
  to_port           = 9000
  cidr_ipv4         = var.vpc_ssh_inbound_cidr
  tags = {
    Name = "Allow_9000"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_39207" {

  security_group_id = aws_security_group.minikube_sg.id
  from_port         = 39207
  ip_protocol       = "tcp"
  to_port           = 39207
  cidr_ipv4         = var.vpc_ssh_inbound_cidr
  tags = {
    Name = "Allow_39207"
  }
}
resource "aws_vpc_security_group_egress_rule" "allow_out_all" {

  security_group_id = aws_security_group.minikube_sg.id
  ip_protocol       = "All"
  cidr_ipv4         = var.vpc_ssh_inbound_cidr
  tags = {
    Name = "Allow_Out_all"
  }
}


# Resource to create
resource "aws_instance" "minikube_instance" {

  # AMI ID ami-0c1c30571d2dae5c9 (for ubuntu 22.04 lts)
  ami = var.app_ami_id

  instance_type = var.instance_type

  # Public ip
  associate_public_ip_address = var.associate_pub_ip

  # Security group
  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

  # SSH Key pair
  key_name = var.ssh_key_name

  # Name the resource
  tags = {
    Name = var.instance_name
  }

}


