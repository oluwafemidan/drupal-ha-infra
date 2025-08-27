terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC and Networking
resource "aws_vpc" "drupal_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "drupal-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.drupal_vpc.id

  tags = {
    Name = "drupal-igw"
  }
}

# Public Subnets in 2 AZs
resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.drupal_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Private Subnets for RDS
resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.drupal_vpc.id
  cidr_block        = "10.0.${count.index + 3}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.drupal_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "drupal-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.drupal_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "drupal-alb-sg"
  }
}

# Security Group for Drupal Instances
resource "aws_security_group" "drupal_sg" {
  name        = "drupal-instance-sg"
  description = "Security group for Drupal instances"
  vpc_id      = aws_vpc.drupal_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "drupal-instance-sg"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "drupal-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.drupal_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.drupal_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "drupal-rds-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "drupal_alb" {
  name               = "drupal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

  tags = {
    Name = "drupal-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "drupal_tg" {
  name     = "drupal-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.drupal_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener
resource "aws_lb_listener" "drupal_listener" {
  load_balancer_arn = aws_lb.drupal_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.drupal_tg.arn
  }
}

# RDS MySQL Database
resource "aws_db_subnet_group" "drupal_db_subnet_group" {
  name       = "drupal-db-new-subnet-group-new"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "drupal-db-new-subnet-group-new"
  }
}

resource "aws_db_instance" "drupal_db" {
  identifier             = "drupal-db-new"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.drupal_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = true
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = "drupal-db-new"
  }
}



# Staging instances
resource "aws_instance" "staging_instances" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnets[count.index % 2].id
  vpc_security_group_ids = [aws_security_group.drupal_sg.id]
  key_name               = "drupal-staging-key"  # ← Use existing key name
  user_data              = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3
              EOF

  tags = {
    Name = "drupal-staging-${count.index + 1}"
    Environment = "staging"
  }
}

# Production instances
resource "aws_instance" "production_instances" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnets[count.index % 2].id
  vpc_security_group_ids = [aws_security_group.drupal_sg.id]
  key_name               = "drupal-production-key"  # ← Use existing key name
  user_data              = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3
              EOF

  tags = {
    Name = "drupal-production-${count.index + 1}"
    Environment = "production"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "staging_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.drupal_tg.arn
  target_id        = aws_instance.staging_instances[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "production_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.drupal_tg.arn
  target_id        = aws_instance.production_instances[count.index].id
  port             = 80
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}