provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my-TF-VPC" {
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "my-TF-VPC"
  }
}

resource "tls_private_key" "my-TF-priv-key" {
  algorithm = "RSA"
}
resource "aws_key_pair" "generated_key" {
  key_name   = "my-TF-priv-key"
  public_key = tls_private_key.my-TF-priv-key.public_key_openssh
  depends_on = [
    tls_private_key.my-TF-priv-key
  ]
}
resource "local_file" "key" {
  content         = tls_private_key.my-TF-priv-key.private_key_pem
  filename        = "my-TF-priv-key.pem"
  file_permission = "0400"
  depends_on = [
    tls_private_key.my-TF-priv-key
  ]
}


resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.my_vpc.id}"
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "my_public_subnet"
  }
}
resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.my_vpc.id}"
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "my_private_subnet"
  }
}

resource "aws_security_group" "my-TF-SG" {
  name        = "my-TF-SG"
  description = "This firewall allows SSH, HTTP and MYSQL"
  vpc_id      = "${aws_vpc.my_vpc.id}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-TF-SG"
  }
}

resource "aws_internet_gateway" "my-TF-IGW" {
  vpc_id = aws_vpc.my-TF-VPC.id

  tags = {
    Name = "my-TF-IGW"
  }
}

resource "aws_route_table" "my-TF-RT" {
  vpc_id = aws_vpc.my-TF-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-TF-IGW.id
  }

  tags = {
    Name = "my-TF-RT"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = "${aws_route_table.my-TF-RT.id}"
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private.id
  route_table_id = "${aws_route_table.my-TF-RT.id}"
}

resource "aws_instance" "wordpress" {
  ami                    = "ami-03a115bbd6928e698"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = ["${aws_security_group.sg.id}"]
  subnet_id              = aws_subnet.public.id

  tags = {
    Name = "my-TF-WP-ec2"
  }
}

resource "aws_instance" "mysql" {
  ami                    = "ami-04e98b8bcc00d2678"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = ["${aws_security_group.mysg.id}"]
  subnet_id              = aws_subnet.private.id

  tags = {
    Name = "my-TF-mysql"
  }
}
