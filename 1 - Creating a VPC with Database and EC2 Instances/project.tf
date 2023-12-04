# Prepare terraform provider downloaded packages
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Initialise the providers
provider "aws" {
  # Hard coded credentials is a bad practice. USING EXPORT or $ENV: variables instead.
}

# Declare a single variable for your project
# Note: no need to be specific with data types
variable "project" {
  default = {}
}



# NETWORKING RELATED RESOURCES

# VPCs
resource "aws_vpc" "networks" {
  for_each             = var.project.networking.vpcs
  cidr_block           = try(each.value.cidr_block, true)
  instance_tenancy     = try(each.value.instance_tenancy, true)
  enable_dns_support   = try(each.value.enable_dns_support, true)
  enable_dns_hostnames = try(each.value.enable_dns_hostnames, true)
  tags                 = try(each.value.tags, var.project.tags)
}

# SUBNETs
resource "aws_subnet" "subnets" {
  for_each = merge([
    for nKey, nValue in var.project.networking.vpcs : {
      for sKey, sValue in nValue.subnets :
      "${nKey}-${sKey}" => {
        id                = "${nKey}-${sKey}"
        vpc_id            = aws_vpc.networks[nKey].id
        cidr_block        = sValue.cidr_block
        availability_zone = try(sValue.availability_zones, "us-east-1a") #us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1e, us-east-1f
      }
    }
  ]...)
  vpc_id = each.value.vpc_id

  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags              = try(each.value.tags, var.project.tags)
}

# Route Tables
resource "aws_route_table" "route_tables" {
  for_each = var.project.networking.route_tables
  vpc_id   = aws_vpc.networks[each.value.parent_vpc_key].id
  dynamic "route" {
    for_each = each.value.routes
    content {
      cidr_block = route.value.cidr_block
      gateway_id = route.value.next_hop == "igw" ? aws_internet_gateway.igws[each.value.parent_vpc_key].id : null
    }
  }
  tags = try(each.value.tags, var.project.tags)

}

# Route Table Associations
resource "aws_route_table_association" "route_table_associations" {
  for_each = merge([
    for nKey, nValue in var.project.networking.vpcs : {
      for sKey, sValue in nValue.subnets :
      "${nKey}-${sKey}" => {
        route_table_key = "${sValue.route_table_key}"
      }
    }
  ]...)
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.route_tables[each.value.route_table_key].id
}

# Internet Gateway
resource "aws_internet_gateway" "igws" {
  for_each = var.project.networking.internet_gateways
  vpc_id   = aws_vpc.networks[each.value.parent_vpc_key].id
  tags     = try(each.value.tags, var.project.tags)
}


# Security Group
resource "aws_security_group" "sg" {
  for_each = var.project.networking.security_groups
  vpc_id   = aws_vpc.networks[each.value.vpc_key].id

  ## SGs need an EGRESS and INGRESS RULE SET
  dynamic "ingress" {
    for_each = try(each.value.ingress_rules, [])
    content {
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.source_cidr
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
    }
  }
  dynamic "egress" {
    for_each = try(each.value.egress_rules, [])
    content {
      protocol    = egress.value.protocol
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      cidr_blocks = egress.value.destination_cidr
    }
  }
  tags = try(each.value.tags, var.project.tags)
}


# Elastic IPs
resource "aws_eip" "eip" {
  for_each   = var.project.networking.elastic_ip_addresses
  instance   = aws_instance.ec2[each.value.ec2_instance_key].id
  depends_on = [aws_instance.ec2, aws_internet_gateway.igws]
}



resource "aws_db_subnet_group" "subnet_groups" {
  for_each = var.project.compute.rds.subnet_groups
  ##subnet_ids = [aws_subnet.subnets["${each.value.vpc_key}-${each.value.subnet_key}"].id]
  name        = each.value.name
  description = each.value.description
  subnet_ids = [
    for subnet_key in each.value.subnet_keys : aws_subnet.subnets["${each.key}-${subnet_key}"].id
  ]
  tags = try(each.value.tags, var.project.tags)

}

resource "aws_db_parameter_group" "params" {
  for_each = var.project.compute.rds.parameter_groups
  name     = replace(each.value.name, ".", "-")
  family   = each.value.family
  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  tags = try(each.value.tags, var.project.tags)

}
# resource "aws_iam_instance_profile" "AWSRDSCustomInstanceProfile" {

# jsonencode(
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "rds-db:connect"
#             ],
#             "Resource": [
#                 "arn:aws:rds-db:us-east-2:1234567890:dbuser:db-ABCDEFGHIJKL01234/db_user"
#              S3 and RDS Full Access
#             ]
#         }
#     ]
# }
# )

resource "aws_db_instance" "rds" {
  for_each                   = var.project.compute.rds.instances
  allocated_storage          = try(each.value.allocated_storage, 50)
  auto_minor_version_upgrade = try(each.value.auto_minor_version_upgrade, false) # Custom for Oracle does not support minor version upgrades
  ##  custom_iam_instance_profile = try(each.value.custom_iam_instance_profile, "AWSRDSCustomInstanceProfile") # Instance profile is required for Custom for Oracle. See: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/custom-setup-orcl.html#custom-setup-orcl.iam-vpc
  db_subnet_group_name = aws_db_subnet_group.subnet_groups[each.value.subnet_group_key].name
  engine               = try(each.value.engine, "mysql")
  engine_version       = try(each.value.engine_version, "8.0")
  identifier           = each.value.identifier
  instance_class       = each.value.instance_class
  username             = each.value.username
  password             = each.value.password
  parameter_group_name = aws_db_parameter_group.params[each.value.parameter_group_key].name
  storage_encrypted    = try(each.value.storage_encrypted, true)
  skip_final_snapshot  = try(each.value.skip_final_snapshot, false)
  timeouts {
    create = "3h"
    delete = "3h"
    update = "3h"
  }
  tags = try(each.value.tags, var.project.tags)
}

# Generate an RSA key using terraform 
resource "tls_private_key" "rsa" {
  for_each   = var.project.compute.key_pairs
  algorithm = each.value.algorithm
  rsa_bits  = each.value.rsa_bits
}


# Export the OpenSSH formatted public key
resource "aws_key_pair" "rsa" {
  for_each   = var.project.compute.key_pairs
  key_name   = each.value.key_name
  #public_key = replace(replace(replace(file("${each.value.public_key_filename}"),"-----BEGIN RSA PUBLIC KEY-----","ssh-rsa "),"-----END RSA PUBLIC KEY-----"," ${each.value.key_name}"),"\n","")
  public_key = "${tls_private_key.rsa[each.key].public_key_openssh}"

  # NOTE: SAVE THE PRIVATE AND PUBLIC KEYS TO DISK, BY WRITING THEM OUT TO FILES. Terraform output won't work, sensitive data.
  provisioner "local-exec" {
    command = <<-EOT
      echo "${tls_private_key.rsa[each.key].private_key_openssh}" > id_rsa_openssh.priv
      echo "${tls_private_key.rsa[each.key].private_key_pem}" > id_rsa_pem.priv
      echo "${tls_private_key.rsa[each.key].public_key_openssh}" > id_rsa_openssh.pub
      echo "${tls_private_key.rsa[each.key].public_key_pem}" > id_rsa_pem.pub
    EOT
  }
}

resource "aws_instance" "ec2" {
  for_each               = var.project.compute.ec2
  ami                    = try(each.value.ami, "ami-04e914639d0cca79a")
  instance_type          = try(each.value.instance_type, "t2.micro")
  subnet_id              = aws_subnet.subnets["${each.value.vpc_key}-${each.value.subnet_key}"].id
  vpc_security_group_ids = [aws_security_group.sg[each.value.security_group_key].id]
  key_name               = aws_key_pair.rsa[each.value.key_pair_key].key_name
  user_data              = try(each.value.user_data, null)
  tags                   = try(each.value.tags, var.project.tags)
}


resource "null_resource" "test-rsa-key" {
  for_each = var.project.compute.key_pairs
  connection {
    type     = "ssh"
    user     = "ec2-user"
    host     = aws_eip.eip[each.key].public_ip
    private_key = tls_private_key.rsa[each.key].private_key_openssh
  }
  provisioner "remote-exec" {
    inline = [
      # https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec#scripts
      # See Note in the link above about: set -o errexit
      "echo $ipaddr",
      "echo $hostname",
      "exit 0"
    ]
    on_failure = continue
  }
  depends_on = [
    tls_private_key.rsa,
    aws_instance.ec2
  ]
}