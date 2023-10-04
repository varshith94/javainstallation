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