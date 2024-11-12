# Infrastructure Setup for Minikube Deployment

- [Infrastructure Setup for Minikube Deployment](#infrastructure-setup-for-minikube-deployment)
  - [1. **AWS Provider Configuration**](#1-aws-provider-configuration)
  - [2. **Security Group Creation**](#2-security-group-creation)
  - [3. **Security Group Ingress Rules**](#3-security-group-ingress-rules)
    - [Allow SSH (Port 22)](#allow-ssh-port-22)
    - [Allow HTTP (Port 80)](#allow-http-port-80)
    - [Allow HTTP on Port 9000](#allow-http-on-port-9000)
    - [Allow All Outbound Traffic](#allow-all-outbound-traffic)
  - [4. **EC2 Instance Configuration**](#4-ec2-instance-configuration)
  - [Variables](#variables)
  - [Output](#output)

## 1. **AWS Provider Configuration**

The provider block defines the AWS region where your infrastructure will be created.

```hcl
# Provider
provider "aws" {
  # Which region we use
  region = "eu-west-1"
}
```

- **region**: The region to deploy the resources (in this case, `eu-west-1`).

## 2. **Security Group Creation**

This block defines a security group for the Minikube EC2 instance, which controls the inbound and outbound traffic.

```hcl
# Security group
resource "aws_security_group" "minikube_sg" {
  name = var.sg_name
  # Tags
  tags = {
    Name = var.sg_name
  }
}
```

- **name**: The security group name is provided by the variable `sg_name`.
- **tags**: The security group is tagged with the same name (`sg_name`) for identification.

## 3. **Security Group Ingress Rules**

These blocks define the rules for allowing inbound traffic to the EC2 instance. Each rule specifies which ports should be open for incoming traffic.

### Allow SSH (Port 22)

```hcl
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
```

- **from_port**: Allows traffic on port 22 (SSH).
- **cidr_ipv4**: Restricts access to the specified CIDR block (provided by `vpc_ssh_inbound_cidr`).

### Allow HTTP (Port 80)

```hcl
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
```

- **from_port**: Allows traffic on port 80 (HTTP).

### Allow HTTP on Port 9000

```hcl
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
```

- **from_port**: Allows traffic on port 9000 (used by your Minikube service or Nginx proxy).

### Allow All Outbound Traffic

```hcl
resource "aws_vpc_security_group_egress_rule" "allow_out_all" {
  security_group_id = aws_security_group.minikube_sg.id
  ip_protocol       = "All"
  cidr_ipv4         = var.vpc_ssh_inbound_cidr
  tags = {
    Name = "Allow_Out_all"
  }
}
```

- **egress rule**: Allows all outbound traffic from the EC2 instance.

## 4. **EC2 Instance Configuration**

This block creates an EC2 instance that will run the Minikube setup.

```hcl
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
```

- **ami**: The AMI ID for the Ubuntu 22.04 LTS image (provided via variable `app_ami_id`).
- **instance_type**: The type of EC2 instance to be created (provided via `instance_type` variable).
- **associate_public_ip_address**: Whether the instance should be assigned a public IP (controlled by `associate_pub_ip` variable).
- **vpc_security_group_ids**: Attaches the previously created security group (`minikube_sg`) to the EC2 instance.
- **key_name**: The SSH key used to access the EC2 instance (`ssh_key_name`).
- **tags**: Tags the EC2 instance with a name (`instance_name`).

---

## Variables

The variables used in the code are placeholders that need to be defined in a `terraform.tfvars` or similar file. Examples of variables:

```hcl
variable "sg_name" {
  type        = string
  description = "The name of the security group"
}

variable "vpc_ssh_inbound_cidr" {
  type        = string
  description = "CIDR block for inbound SSH access"
}

variable "app_ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type"
}

variable "associate_pub_ip" {
  type        = bool
  description = "Whether to associate a public IP"
}

variable "ssh_key_name" {
  type        = string
  description = "The SSH key name"
}

variable "instance_name" {
  type        = string
  description = "The name tag for the EC2 instance"
}
```

---

## Output

The output file in Terraform captures and displays the results of the deployment, such as the public IP address of the EC2 instance. This is especially useful for accessing the instance remotely or configuring other services. By defining an output block in Terraform, we can ensure that the public IP address of the EC2 instance is easily accessible after the infrastructure has been created. This IP address is crucial for accessing the Minikube deployment externally, whether it’s for testing or production purposes. Below is an example of how to capture and display the public IP address of the EC2 instance:

```hcl
output "instance_public_ip" {
  value = aws_instance.minikube_instance.public_ip
  description = "The public IP address of the Minikube EC2 instance"
}
```

With this output, after applying the Terraform configuration, you can retrieve the public IP address of the instance, which will allow you to access the Minikube services running inside the EC2 instance, such as through a web browser or via API calls.

---

This Terraform code creates the necessary security groups and EC2 instance to run your Minikube deployment, allowing inbound access for SSH (port 22), HTTP (port 80), and port 9000 for reverse proxy access. It also defines outbound traffic rules and associates the instance with a public IP for external access.
