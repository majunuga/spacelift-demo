terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Ubuntu 20.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Default Subnet
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Instances definition
locals {
  instances = {
    instance1 = {
      instance_type = "t3.micro"
    }

    instance2 = {
      instance_type = "t3.micro"
    }

    instance3 = {
      instance_type = "t3.micro"
    }

    instance4 = {
      instance_type = "t3.micro"
    }
  }
}

# Import/Create Key Pair
resource "aws_key_pair" "ssh_key" {
  key_name   = "ec2-demo-key"
  public_key = file(var.public_key)
}

# Security Group
resource "aws_security_group" "ssh" {
  name        = "allow-ssh"
  description = "Allow SSH"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = data.aws_vpc.default.id
}

# EC2 Instances
resource "aws_instance" "this" {
  for_each = local.instances

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = each.value.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  associate_public_ip_address = true

  tags = {
    Name = each.key
  }
}
