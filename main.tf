# Credentials
provider "aws" {
    region     = "eu-central-1"
    access_key = ""
    secret_key = ""
}

# Create VPC
resource "aws_vpc" "vpc-1" {
    cidr_block = "10.1.0.0/16"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    instance_tenancy = "default"

    tags = {
        Name = "VPC-1"
    }
}

# Create public subnet
resource "aws_subnet" "vpc-1-public-1" {
    vpc_id = "${aws_vpc.vpc-1.id}"
    cidr_block = "10.1.0.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "eu-central-1a"

    tags = {
        Name = "VPC-1 Public subnet 1"
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "vpc-1-igw-1" {
    vpc_id = "${aws_vpc.vpc-1.id}"
    
    tags = {
        Name  = "VPC-1 Internet Gateway 1"
    }
}

# Create route table and set default route
resource "aws_route_table" "vpc-1-rt-1" {
    vpc_id = "${aws_vpc.vpc-1.id}"
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.vpc-1-igw-1.id}"
  }

    tags = {
        Name = "VPC-1 Route Table 1"
    }
}

# Associate subnet with route table
resource "aws_route_table_association" "vpc-1-rta-1" {
    subnet_id = "${aws_subnet.vpc-1-public-1.id}"
    route_table_id = "${aws_route_table.vpc-1-rt-1.id}"
}

# Create Security Group
resource "aws_security_group" "ssh-http-allow" {
    vpc_id = "${aws_vpc.vpc-1.id}"
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outcoming traffic"
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH traffic on port 22 from any source"
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTP traffic from any source"
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTPS traffic from any source"
    }

    tags = {
        Name = "Allow SSH/HTTP/HTTPS"
    }
}

# Create instance for webserver
resource "aws_instance" "web-1" {
    ami = "${var.AMI}"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.vpc-1-public-1.id}"
    vpc_security_group_ids = ["${aws_security_group.ssh-http-allow.id}"]
    key_name = "acme"

    tags = {
        Name = "Main Webserver"
    }
}