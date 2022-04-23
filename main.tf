provider "aws" {
  region = var.region
}

resource "aws_vpc" "default" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags                 = merge(var.project_tags)
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags   = { Name = "igw-MCTEST" }
}

resource "aws_route" "RT-public" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_subnet" "SN-public-1" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags                    = { Name = "SN-public-1-MC" }
}

resource "aws_subnet" "SN-private-1" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "SN-private-1-MC" }
}

resource "aws_security_group" "ssh" {
  name        = "public ssh"
  description = "Security Group Deployment"
  vpc_id      = aws_vpc.default.id
  tags        = merge(var.project_tags)

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "http" {
  name        = "public http"
  description = "Security Group Deployment"
  vpc_id      = aws_vpc.default.id
  tags        = merge(var.project_tags)

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "egress" {
  name        = "egress all"
  description = "Security Group Deployment"
  vpc_id      = aws_vpc.default.id
  tags        = merge(var.project_tags)

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web1" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.SN-public-1.id
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.http.id,
    aws_security_group.egress.id
  ]
  tags      = { Name = "MC-01" }
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        cd /var/www/html
        echo "VM $(hostname -f)" > index.html
        systemctl restart httpd
        systemctl enable httpd
        EOF
}

resource "aws_instance" "web2" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.SN-private-1.id
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.http.id,
    aws_security_group.egress.id
  ]
  tags      = { Name = "MC-02" }
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        cd /var/www/html
        echo "VM $(hostname -f)" > index.html
        systemctl restart httpd
        systemctl enable httpd
        EOF
}

resource "aws_eip" "ip_address" {
  instance = aws_instance.web1.id
  vpc      = true
}