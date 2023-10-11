provider "aws" {
    access_key = "AKIAXMYPIXTZXACQSVIE"
    secret_key = "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"
    region = "us-east-1"
  
}

resource "aws_vpc" "prod" {
    cidr_block = var.cidr_block
    enable_dns_hostnames = true
    tags = {
        Name=var.vpc_name
            }
  
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.prod.id
    tags = {
      Name = "${var.vpc_name}-igw"
          }
  
}


resource "aws_subnet" "subnet" {
    count = 2
vpc_id = aws_vpc.prod.id
cidr_block = element(var.cidr_block_subnet,count.index)
availability_zone = element(var.azs,count.index)
map_public_ip_on_launch = true
tags = {
    Name = "${var.vpc_name}-pubilc${count.index+1}"
}

}

resource "aws_route_table" "rt" {
    vpc_id= aws_vpc.prod.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "${var.vpc_name}-rt"
    }
  
}

resource "aws_route_table_association" "association" {
    count = 2
    route_table_id = aws_route_table.rt.id
    subnet_id = element(aws_subnet.subnet[*].id,count.index) 
  
}


resource "aws_security_group" "sg" {
vpc_id = aws_vpc.prod.id
name = "allow all rules"
description = "allow inbound and outbound rules"
tags = {
    Name = "${var.vpc_name}-sg"
}
ingress  {
    to_port = 1
    from_port = 1
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow inbound rules"

}
egress {
     to_port = 1
    from_port = 1
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow outbound rules"
}
}

resource "aws_instance" "jenkins-server" {
  count=1
  ami = "ami-008b85aa3ff5c1b02"
  instance_type = "t2.micro"
  key_name = ""
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = element(aws_subnet.subnet[0].id,count.index)
  associate_public_ip_address = true
  root_block_device {
    volume_size = "20"
    volume_type = "gp2"
    encrypted = false
    delete_on_termination = true
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install openjdk-11-jre-headless -y
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
  echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install jenkins -y
  
  EOF
}