terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.68.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "my-public-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.public-subnet-cidr_block

  tags = {
    Name = "my-public-subnet"
  }
}

resource "aws_internet_gateway" "my-internet-gateway" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-internet-gateway"
  }
}

resource "aws_default_route_table" "my-route-table" {
  default_route_table_id = aws_vpc.my-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-internet-gateway.id
  }

  tags = {
    Name = "my-route-table"
  }
}

resource "aws_security_group" "my-security-group" {
  name        = "allow tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.my-vpc.ipv6_cidr_block]
  }
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # egress {
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "-1"
  #   cidr_blocks      = ["0.0.0.0/0"]
  #   ipv6_cidr_blocks = ["::/0"]
  # }

  tags = {
    Name = "allow tls"
  }
}

resource "aws_key_pair" "my-key-pair" {
  key_name   = "key"
  public_key = file("/home/tyss/.ssh/id_rsa.pub")
}

resource "aws_instance" "my-instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.my-public-subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.my-security-group.id]
  key_name                    = aws_key_pair.my-key-pair.key_name

  # user_data = <<EOF
  #               #! /bin/bash
  #               sudo apt update
  #               sudo apt install apache2 -y
  #               sudo rm -rf /var/www/html/index.html
  #               sudo echo "Hi, this is Hariharan EP" >> /var/www/html/index.html
  #               sudo systemctl restart apache2
  #             EOF

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install apache2 -y",
      # "sudo systemctl start apache2",
      "sudo rm -rf /var/www/html/*",
      "touch index.html",
      "sudo echo Hi this is Harish, I would like to join Xylem. >> index.html",
      "sudo mv index.html /var/www/html/",
      "sudo systemctl restart apache2"
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("/home/tyss/.ssh/id_rsa")
  }
  tags = {
    Name = "my-instance"
  }
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.my-instance.public_ip
}