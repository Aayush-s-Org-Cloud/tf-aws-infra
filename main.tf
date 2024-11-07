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
# security_groups.tf  
# Security Group for the Application
resource "aws_security_group" "app_security_group" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "app-sg"

  # Ingress Rules

  # Allow SSH access from trusted CIDR
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from trusted IPs"
  }

  # Allow application traffic from Load Balancer Security Group
  ingress {
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_security_group.id]
    description     = "Allow application traffic from Load Balancer"
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
# Load Balancer Security Group
resource "aws_security_group" "lb_security_group" {
  name        = "lb-security-group"
  description = "Security group for the Load Balancer"
  vpc_id      = aws_vpc.my_vpc.id

  # Ingress Rules
  ingress {
    description      = "Allow HTTP traffic from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  # Ingress Rule for HTTPS
  ingress {
    description      = "Allow HTTPS traffic from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }



  # Egress Rules - Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-security-group"
  }
}
# alb.tf

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_security_group.id]
  subnets            = aws_subnet.public_subnets[*].id

  enable_deletion_protection = false

  tags = {
    Name = "app-alb"
  }
}

# Listener for HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


# Target Group for the Application
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = var.application_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "app-tg"
  }
}

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "app_launch_template" {
  name_prefix   = "csye6225_asg_"
  image_id      = var.custom_ami_id
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  network_interfaces {
    associate_public_ip_address = true  
    subnet_id                   = aws_subnet.public_subnets[0].id
    security_groups             = [aws_security_group.app_security_group.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Starting user data script..."

    # Update package list with retries
    MAX_ATTEMPTS=5
    for attempt in $(seq 1 $MAX_ATTEMPTS); do
      echo "Attempt $attempt: Updating package list..."
      sudo apt-get update -y && break || sleep 10
    done

    # Install MySQL client with retries
    for attempt in $(seq 1 $MAX_ATTEMPTS); do
      echo "Attempt $attempt: Installing MySQL client..."
      sudo apt-get install -y mysql-client-core-8.0 && break || sleep 10
    done

    # Verify MySQL client installation
    if ! which mysql; then
      echo "MySQL client installation failed. Exiting script."
      exit 1
    fi

    # Create the .env file with database configurations
    mkdir -p /opt/nodeapp
    cd /opt/nodeapp
    touch .env

    # Adding environment variables
    echo "DATA_HOST=${aws_db_instance.csye6225_db.address}" >> .env
    echo "DATA_PORT=${var.db_port}" >> .env
    echo "DATA_USER=${var.db_user}" >> .env
    echo "DATA_PASSWORD=${var.db_password}" >> .env
    echo "DATA_DATABASE=${var.db_name}" >> .env
    echo "DATA_DIALECT=${var.db_dialect}" >> .env   
    echo "PORT=${var.application_port}" >> .env
    echo "S3_BUCKET_NAME=${aws_s3_bucket.private_bucket.bucket}" >> .env

    # Display the .env content (optional for debugging)
    cat .env

    # Install CloudWatch Agent if not already present
    if ! which amazon-cloudwatch-agent; then
      echo "Installing CloudWatch Agent..."
      curl -s https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -o amazon-cloudwatch-agent.deb
      sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
    fi

    # Start CloudWatch Agent
    sudo systemctl restart amazon-cloudwatch-agent

    # Start the application
    systemctl start nodeapp

    echo "User data script completed."
  EOF
  )

  tags = {
    Name = "csye6225-launch-template"
  }
}
# autoscaling.tf (continued)

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = aws_subnet.public_subnets[*].id
  min_size            = 3
  max_size            = 5
  desired_capacity    = 3
  default_cooldown    = 60

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "autoscaling-app-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

}
# autoscaling.tf (continued)

# Scale-Up Policy
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

# Scale-Down Policy
resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

# CloudWatch Alarm for Scaling Up
resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = "cpu_high_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "12"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description         = "Alarm when CPU exceeds 12%"
  insufficient_data_actions = []

  alarm_actions = [
    aws_autoscaling_policy.scale_up_policy.arn
  ]
}

# CloudWatch Alarm for Scaling Down
resource "aws_cloudwatch_metric_alarm" "cpu_low_alarm" {
  alarm_name          = "cpu_low_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "8"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description         = "Alarm when CPU falls below 8%"
  insufficient_data_actions = []

  alarm_actions = [
    aws_autoscaling_policy.scale_down_policy.arn
  ]
}
