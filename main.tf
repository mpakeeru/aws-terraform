terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}
# Create a VPC
resource "aws_vpc" "test-tf-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "test-tf-vpc"
  }
}
resource "aws_subnet" "public-subnet1"{
  vpc_id     = aws_vpc.test-tf-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-2b"
  tags = {
    Name = "public-subnet1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public-subnet2"{
  vpc_id     = aws_vpc.test-tf-vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-2c"
  tags = {
    Name = "public-subnet2"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private-subnet1"{
  vpc_id     = aws_vpc.test-tf-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "private-subnet1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private-subnet2"{
  vpc_id     = aws_vpc.test-tf-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-2c"
  tags = {
    Name = "private-subnet2"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_internet_gateway" "aws-tf-gw" {
  vpc_id = aws_vpc.test-tf-vpc.id

  tags = {
    Name = "aws-tf-gw"
  }
}

#creating a route table for public subnet
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.test-tf-vpc.id
    tags = {
      Name = "public-route-table"
    
    }
}

#creating a route table for public subnet
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.test-tf-vpc.id
    tags = {
      Name = "private-route-table"
    }
}

#add route for IGW
resource "aws_route" "public_internet_gateway" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws-tf-gw.id

  
}
#route table associations for public and private subnets
resource "aws_route_table_association" "public1" {
    subnet_id = aws_subnet.public-subnet1.id
    route_table_id = aws_route_table.public.id

  
}
#route table associations for public and private subnets
resource "aws_route_table_association" "public2" {
    subnet_id = aws_subnet.public-subnet2.id
    route_table_id = aws_route_table.public.id

  
}
#creating a elastic IP for NAT 
resource "aws_eip" "nat_eip" {
    
    depends_on = [ aws_internet_gateway.aws-tf-gw ]
    tags = {
    Name        = "nat_eip"
   
  }
  
}
#creating NAT gateway 
resource "aws_nat_gateway" "nat_gateway-terraform" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public-subnet1.id
    tags = {
      Name = "nat-gateway"
     
    }


}

#add route for nat gateway
resource "aws_route" "private_internet_gateway" {
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway-terraform.id
  
}
resource "aws_route_table_association" "private1" {
    subnet_id = aws_subnet.private-subnet1.id
    route_table_id = aws_route_table.private.id
  
}
resource "aws_route_table_association" "private2" {
    subnet_id = aws_subnet.private-subnet2.id
    route_table_id = aws_route_table.private.id
  
}