# VPC Definition
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "cloud-csye-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Public Subnet Definition
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Private Subnet Definition
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public_subnets" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private-route-table"
  }
}

# Private Route Table Association
resource "aws_route_table_association" "private_subnets" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Group for the Application
resource "aws_security_group" "app_security_group" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "app-sg"

  # Ingress Rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }

  ingress {
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow application traffic"
  }

  # Egress Rule to Allow All Outbound Traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-security-group"
  }
}

# Security Group for RDS
resource "aws_security_group" "db_security_group" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "db-security-group"

  # Ingress rule to allow traffic from the EC2 app security group
  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_security_group.id] # Application security group
    description     = "Allow database traffic from app security group"
  }

  # Egress rule to allow all outbound traffic from the RDS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-security-group"
  }
}


# RDS Parameter Group
resource "aws_db_parameter_group" "db_param_group" {
  name        = "csye6225-db-param-group"
  family      = "mysql8.0"
  description = "Custom DB parameter group for CSYE6225"

  # You can add custom parameters here, for example:
  parameter {
    name         = "max_connections"
    value        = "200"
    apply_method = "immediate"
  }
}


# RDS Instance
resource "aws_db_instance" "csye6225_db" {
  identifier             = "csye6225-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.csye6225_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  apply_immediately      = true
  publicly_accessible    = false # RDS is not publicly accessible
  parameter_group_name   = aws_db_parameter_group.db_param_group.name
  multi_az               = false
  engine_version         = "8.0"
  db_name                = var.db_name
  skip_final_snapshot    = true

  tags = {
    Name = "csye6225-db"
  }
}

# Subnet group for RDS to use private subnets
resource "aws_db_subnet_group" "csye6225_subnet_group" {
  name       = "csye6225-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "csye6225-subnet-group"
  }
}


# EC2 Instance with User Data to pass all database configurations
resource "aws_instance" "app_instance_ud" {
  ami                         = var.custom_ami_id
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.public_subnets[0].id
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.app_security_group.id]
  associate_public_ip_address = true

  # User Data script to inject all necessary environment variables into .env
  user_data = <<-EOF
    #!/bin/bash
    echo "Creating .env file with database configurations"
    sudo apt-get update -y
    sudo apt-get install -y mysql-client-core-8.0
    mkdir -p /opt/nodeapp
    cd /opt/nodeapp
    touch /opt/nodeapp/.env

    # Adding environment variable 
    echo "DATA_HOST=${aws_db_instance.csye6225_db.address}" >> /opt/nodeapp/.env
    echo "DATA_PORT=${var.db_port}" >> /opt/nodeapp/.env
    echo "DATA_USER=${var.db_user}" >> /opt/nodeapp/.env
    echo "DATA_PASSWORD=${var.db_password}" >> /opt/nodeapp/.env
    echo "DATA_DATABASE=${var.db_name}" >> /opt/nodeapp/.env
    echo "DATA_DIALECT=${var.db_dialect}" >> /opt/nodeapp/.env   

    # Add environment variable for the application port
    echo "PORT=${var.application_port}" >> /opt/nodeapp/.env
 
    cat /opt/nodeapp/.env

    systemctl start nodeapp
  EOF

  tags = {
    Name = "user-app-instance-user_data"
  }
}



 