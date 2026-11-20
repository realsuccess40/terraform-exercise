# this main.tf file create the complete three tier infrastructure for the organization

# create vpc

resource "aws_vpc" "successlink-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name  = "successlink-vpc"
    Env   = "Prod"
    Owner = "Success"
  }
}

# create the required six subnets

resource "aws_subnet" "web-public-A" {
  vpc_id                  = aws_vpc.successlink-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name  = "Web-Public-A"
    Evn   = "Prod"
    Owner = "success"
  }
}

resource "aws_subnet" "web-public-B" {
  vpc_id                  = aws_vpc.successlink-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name  = "Web-Public-B"
    Evn   = "Prod"
    Owner = "success"
  }
}

resource "aws_subnet" "App-Private-A" {
  vpc_id                  = aws_vpc.successlink-vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name  = "App-Private-A"
    Env   = "Prod"
    Owner = "success"
  }
}

resource "aws_subnet" "App-Private-B" {
  vpc_id                  = aws_vpc.successlink-vpc.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name  = "App-Private-B"
    Env   = "Prod"
    Owner = "success"
  }
}

resource "aws_subnet" "DB-Private-A" {
  vpc_id                  = aws_vpc.successlink-vpc.id
  cidr_block              = "10.0.21.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name  = "DB-Private-A"
    Env   = "Prod"
    Owner = "success"
  }
}

resource "aws_subnet" "DB-Private-B" {
  vpc_id                  = aws_vpc.successlink-vpc.id
  cidr_block              = "10.0.22.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name  = "DB-Private-B"
    Env   = "Prod"
    Owner = "success"
  }
}

# create the internet gateway

resource "aws_internet_gateway" "successlink-gw" {
  vpc_id = aws_vpc.successlink-vpc.id

  tags = {
    Name = "successlink-gw"
  }
}

# create elastic ip for the NAT gateway

resource "aws_eip" "successlink-eip" {
  domain = "vpc"
}

# create NAT Gateway

resource "aws_nat_gateway" "successlink-NATGW" {
  allocation_id = aws_eip.successlink-eip.id
  subnet_id     = aws_subnet.web-public-A.id

  tags = {
    Name = "successlink-NATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.successlink-gw]
}

# create public route table

resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.successlink-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.successlink-gw.id
  }


  tags = {
    Name = "PublicRT"
  }
}

# create private route table

resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.successlink-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.successlink-NATGW.id
  }


  tags = {
    Name = "PrivateRT"
  }
}

# Create isolated database route table

resource "aws_route_table" "DBRT" {
  vpc_id = aws_vpc.successlink-vpc.id

  tags = {
    Name = "DBRT"
  }
}

# create route table association
resource "aws_route_table_association" "Public_RT_Association_A" {
  subnet_id      = aws_subnet.web-public-A.id
  route_table_id = aws_route_table.PublicRT.id
}

resource "aws_route_table_association" "Public_RT_Association_B" {
  subnet_id      = aws_subnet.web-public-B.id
  route_table_id = aws_route_table.PublicRT.id
}

resource "aws_route_table_association" "Private_RT_Association_A" {
  subnet_id      = aws_subnet.App-Private-A.id
  route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_route_table_association" "Private_RT_Association_B" {
  subnet_id      = aws_subnet.App-Private-B.id
  route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_route_table_association" "DB_RT_Association_A" {
  subnet_id      = aws_subnet.DB-Private-A.id
  route_table_id = aws_route_table.DBRT.id
}

resource "aws_route_table_association" "DB_RT_Association_B" {
  subnet_id      = aws_subnet.DB-Private-B.id
  route_table_id = aws_route_table.DBRT.id
}


# create the required security groups for the infrastructure

## create the web security groups

resource "aws_security_group" "web-SG" {
  name        = "web-SG"
  description = "Allow internet traffic for web tier instances"
  vpc_id      = aws_vpc.successlink-vpc.id

  tags = {
    Name = "web-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.web-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.web-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-icmp" {
  security_group_id = aws_security_group.web-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.web-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

## create the App security groups

resource "aws_security_group" "App-SG" {
  name        = "App-SG"
  description = "Allow selected traffic into the application instances"
  vpc_id      = aws_vpc.successlink-vpc.id

  tags = {
    Name = "App-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh2" {
  security_group_id            = aws_security_group.App-SG.id
  referenced_security_group_id = aws_security_group.web-SG.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-app-port" {
  security_group_id            = aws_security_group.App-SG.id
  referenced_security_group_id = aws_security_group.web-SG.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow-icmp2" {
  security_group_id            = aws_security_group.App-SG.id
  referenced_security_group_id = aws_security_group.web-SG.id
  from_port                    = -1
  ip_protocol                  = "icmp"
  to_port                      = -1
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-2" {
  security_group_id = aws_security_group.App-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

## create the DB security groups

resource "aws_security_group" "DB-SG" {
  name        = "DB-SG"
  description = "Allow selected traffic into the database instances"
  vpc_id      = aws_vpc.successlink-vpc.id

  tags = {
    Name = "DB-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh3" {
  security_group_id            = aws_security_group.DB-SG.id
  referenced_security_group_id = aws_security_group.App-SG.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-DB-port" {
  security_group_id            = aws_security_group.DB-SG.id
  referenced_security_group_id = aws_security_group.App-SG.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "allow-icmp3" {
  security_group_id            = aws_security_group.DB-SG.id
  referenced_security_group_id = aws_security_group.App-SG.id
  from_port                    = -1
  ip_protocol                  = "icmp"
  to_port                      = -1
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-3" {
  security_group_id = aws_security_group.DB-SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# create the aws instances that are required

## set the ami data source

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical

}


resource "aws_instance" "Bastion-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web-public-A.id
  vpc_security_group_ids = [aws_security_group.web-SG.id]
  key_name               = var.key_name

  tags = {
    Name = "Bastion-server"
  }
}

resource "aws_instance" "web-VM" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web-public-B.id
  vpc_security_group_ids = [aws_security_group.web-SG.id]
  key_name               = var.key_name

  tags = {
    Name = "web-VM"
  }
}

resource "aws_instance" "App-VM" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.App-Private-A.id
  vpc_security_group_ids = [aws_security_group.App-SG.id]
  key_name               = var.key_name

  tags = {
    Name = "App-VM"
  }
}

resource "aws_instance" "DB-VM" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.DB-Private-A.id
  vpc_security_group_ids = [aws_security_group.DB-SG.id]
  key_name               = var.key_name

  tags = {
    Name = "DB-VM"
  }
}
#