data "aws_ami" "win22" {

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "image-id"
    values = ["ami-05938e59901d65337"]
  }
}


# Define the security group for ?
resource "aws_security_group" "server-ssg" {
  name        = "${lower(var.app_name)}-${var.app_environment}-ssg"
  description = "Servers Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-ssg"
    Environment = var.app_environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "server-ingress-1" {
  security_group_id = aws_security_group.server-ssg.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  referenced_security_group_id = aws_security_group.server-ssg.id
  description = "Allow incoming HTTPS"
}

resource "aws_vpc_security_group_ingress_rule" "server-ingress-2" {
  security_group_id = aws_security_group.server-ssg.id

  from_port   = 3389
  to_port     = 3389
  ip_protocol = "tcp"
  cidr_ipv4   = var.rdp_cidr
  description = "Allow incoming RDP"
}

resource "aws_vpc_security_group_ingress_rule" "server-ingress-3" {
  security_group_id = aws_security_group.server-ssg.id

  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.server-ssg.id
}

resource "aws_vpc_security_group_ingress_rule" "server-ingress-4" {
  security_group_id = aws_security_group.server-ssg.id

  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.server-nlb.id
}

resource "aws_vpc_security_group_egress_rule" "server-egress-1" {
  security_group_id = aws_security_group.server-ssg.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_security_group" "server-nlb" {
  name        = "${lower(var.app_name)}-${var.app_environment}-nlb-ssg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS connections"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-nlb-ssg"
    Environment = var.app_environment
  }
}

# Create the Launch Template
resource "aws_launch_template" "server_primary" {
  name                   = "${lower(var.app_name)}-${var.app_environment}-server-primary"
  image_id               = data.aws_ami.win22.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.server-ssg.id]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.server-profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${lower(var.app_name)}-${var.app_environment}-server-windows"
      Environment = var.app_environment
    }
  }
}

resource "aws_launch_template" "server_secondary" {
  name                   = "${lower(var.app_name)}-${var.app_environment}-server-secondary"
  image_id               = data.aws_ami.win22.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.server-ssg.id]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.server-profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${lower(var.app_name)}-${var.app_environment}-server"
      Environment = var.app_environment
    }
  }
}

resource "aws_instance" "server-primary" {
  launch_template {
    id      = aws_launch_template.server_primary.id
    version = "$Latest"
  }

  subnet_id = var.private_subnet_1_id

  tags = {
    Name = "test-server-primary"
    backup = "true"
    PatchGroup = "test-win-az1"
  }
}

resource "aws_instance" "server-secondary" {
  launch_template {
    id      = aws_launch_template.server_secondary.id
    version = "$Latest"
  }

  subnet_id = var.private_subnet_2_id

  tags = {
    Name = "test-server-secondary"
    backup = "true"
    PatchGroup = "test-win-az2"
  }
}

# IAM Policy with Assume Role to EC2
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Configure IAM Role
resource "aws_iam_role" "server-role" {
  name               = "test-server-ec2"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}

resource "aws_iam_instance_profile" "server-profile" {
  name = "server-profile"
  role = aws_iam_role.server-role.name
}