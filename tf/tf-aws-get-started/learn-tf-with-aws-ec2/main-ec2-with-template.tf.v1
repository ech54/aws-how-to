# declare directory
/*
data "aws_directory_service_directory" "my_domain_controller" {
  directory_id = var.directory_id
}
*/

/*
resource "aws_ssm_document" "ad-join-domain" {
  name          = "ad-join-domain"
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" = "2.2"
      "description"   = "aws:domainJoin"
      "mainSteps" = [
        {
          "action" = "aws:domainJoin",
          "name"   = "domainJoin",
          "inputs" = {
            "directoryId" : data.aws_directory_service_directory.my_domain_controller.id,
            "directoryName" : data.aws_directory_service_directory.my_domain_controller.name
            "dnsIpAddresses" : sort(data.aws_directory_service_directory.my_domain_controller.dns_ip_addresses)
          }
        }
      ]
    }
  )
}
*/
/*
resource "aws_ssm_association" "windows_server" {
  name = aws_ssm_document.ad-join-domain.name
  targets {
    key    = "InstanceIds"
    values = [
      aws_instance.adfs-primary.id,
      aws_instance.adfs-secondary.id
    ]
  }
}
*/

data "aws_ami" "win22" {

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "image-id"
    values = ["ami-05938e59901d65337"]
  }
}


# Define the security group for the MFA server
resource "aws_security_group" "adfs" {
  name        = "${lower(var.app_name)}-${var.app_environment}-adfs"
  description = "ADFS Servers Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${lower(var.app_name)}-${var.app_environment}-adfs"
    Environment = var.app_environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "adfs-1" {
  security_group_id = aws_security_group.adfs.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  referenced_security_group_id = aws_security_group.adfs-nlb.id
  description = "Allow incoming HTTPS"
}

resource "aws_vpc_security_group_ingress_rule" "adfs-2" {
  security_group_id = aws_security_group.adfs.id

  from_port   = 3389
  to_port     = 3389
  ip_protocol = "tcp"
  cidr_ipv4   = var.srv4dev_cidr
  description = "Allow incoming RDP"
}

resource "aws_vpc_security_group_ingress_rule" "adfs-3" {
  security_group_id = aws_security_group.adfs.id

  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.adfs.id
}

resource "aws_vpc_security_group_ingress_rule" "adfs-4" {
  security_group_id = aws_security_group.adfs.id

  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.adfs-nlb.id
}

resource "aws_vpc_security_group_egress_rule" "adfs-1" {
  security_group_id = aws_security_group.adfs.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_security_group" "adfs-nlb" {
  name        = "${lower(var.app_name)}-${var.app_environment}-adfs-nlb"
  description = "ADFS ALB Security Group"
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
    Name        = "${lower(var.app_name)}-${var.app_environment}-adfs-nlb"
    Environment = var.app_environment
  }
}

# Create the Launch Template
resource "aws_launch_template" "adfs_primary" {
  name                   = "${lower(var.app_name)}-${var.app_environment}-adfs-primary"
  image_id               = data.aws_ami.win22.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.adfs.id]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.adfs.name
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
      Name        = "${lower(var.app_name)}-${var.app_environment}-adfs"
      Environment = var.app_environment
    }
  }
}

resource "aws_launch_template" "adfs_secondary" {
  name                   = "${lower(var.app_name)}-${var.app_environment}-adfs-secondary"
  image_id               = data.aws_ami.win22.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.adfs.id]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.adfs.name
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
      Name        = "${lower(var.app_name)}-${var.app_environment}-adfs"
      Environment = var.app_environment
    }
  }
}

resource "aws_instance" "adfs-primary" {
  launch_template {
    id      = aws_launch_template.adfs_primary.id
    version = "$Latest"
  }

  subnet_id = var.private_subnet_1_id

  tags = {
    Name = "common-test-adfs-primary"
    backup = "true"
    PatchGroup = "test-win-az1"
  }
}

resource "aws_instance" "adfs-secondary" {
  launch_template {
    id      = aws_launch_template.adfs_secondary.id
    version = "$Latest"
  }

  subnet_id = var.private_subnet_2_id

  tags = {
    Name = "common-test-adfs-secondary"
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
resource "aws_iam_role" "adfs" {
  name               = "adfs-ec2"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}

# Configure IAM Instance Profile
/*
resource "aws_iam_instance_profile" "adfs" {
  name = "adfs"
  role = aws_iam_role.adfs.name
}
*/
