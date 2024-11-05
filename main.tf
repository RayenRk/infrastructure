# AWS Account Access Key and Secret Key
variable "aws_access_key" {
  description = "AWS Account Access Key"
  type        = string
  sensitive   = true
}
variable "aws_secret_key" {
  description = "AWS Account Secret Key"
  type        = string
  sensitive   = true
}
variable "aws_token" {
  description = "AWS Account Token"
  type        = string
  sensitive   = true
}
variable "key_pair" {
  description = "Key pair name for the bastion host"
  type        = string
  sensitive   = true
}

# GitHub personal access token for cloning the repository
variable "github_token" {
  description = "GitHub personal access token for cloning the repository"
  type        = string
  sensitive   = true
}
variable "github_repo" {
  description = "GitHub repository to clone"
  type        = string

}
variable "github_user" {
  description = "GitHub user to clone the repository"
  type        = string
}

# Provider configuration
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_token
}

# Create a custom VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "lab-vpc"
  }
}

# Create public subnets in two availability zones
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-b"
  }
}

# Create private subnets in two availability zones
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-b"
  }
}

# Create an Internet Gateway for public subnets
resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id
  tags = {
    Name = "lab-igw"
  }
}

# Create a NAT Gateway for private subnets
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "lab_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags = {
    Name = "lab-nat-gw"
  }
}

# Create route table for public subnets and associate it
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.lab_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create route table for private subnets and associate it
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.lab_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_nat_gw.id
  }
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_subnet_a_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_b_association" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id
}

# Security group for HTTP
resource "aws_security_group" "http_sg" {
  name        = "http-sg"
  description = "Allow inbound HTTP traffic on port 80"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
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
}

resource "aws_security_group" "ssh_sg" {
  name        = "ssh-sg"
  description = "Allow inbound SSH traffic on port 22"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
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
}

resource "aws_security_group" "app_sg" {
  name        = "custom-sg"
  description = "Allow inbound traffic on port 8000"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch template for EC2 instances with user data
resource "aws_launch_template" "lab_template" {
  name          = "lab-template"
  image_id      = "ami-0ddc798b3f1a5117e" # Amazon Linux 2 AMI ID for us-east-1
  instance_type = "t2.micro"
  key_name      = var.key_pair

  # User data script
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 git
    pip3 install fastapi[all]
    pip3 install uvicorn[standard]
    git clone https://${var.github_token}@github.com/${var.github_user}/${var.github_repo}.git
    cd ${var.github_repo}
    /usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000 &
  EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.app_sg.id,
      aws_security_group.ssh_sg.id
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Target Group for the Application Load Balancer
resource "aws_lb_target_group" "lab_target_group" {
  name     = "lab-target-group"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create Application Load Balancer
resource "aws_lb" "lab_alb" {
  name               = "lab-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.http_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  enable_deletion_protection = false
  idle_timeout               = 400

  tags = {
    Name = "lab-alb"
  }
}

# Create a listener for the Application Load Balancer
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.lab_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab_target_group.arn
  }
}

# Modify the Auto Scaling Group to use the private subnets
resource "aws_autoscaling_group" "lab_asg" {
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  target_group_arns   = [aws_lb_target_group.lab_target_group.arn]

  launch_template {
    id      = aws_launch_template.lab_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "lab-instance"
    propagate_at_launch = true
  }
}

# Bastion host in public subnet A for SSH access to private instances
resource "aws_instance" "bastion" {
  ami           = "ami-0ddc798b3f1a5117e" # Amazon Linux 2 AMI ID for us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_a.id
  key_name      = var.key_pair

  security_groups = [
    aws_security_group.ssh_sg.id
  ]

  tags = {
    Name = "bastion-host"
  }
}


output "load_balancer_dns" {
  value = aws_lb.lab_alb.dns_name
}
