project = {
  tags = {
    owner   = "Simon Jackson"
    course = "AWS Cloud Fundamentals"
    project = "Create a VPC, with multiple subnets, Internet Gateway, Security Groups and a backend RDS database instance to host a website"
  }
  networking = {
    vpcs = {
      0 = {
        tags                 = { Name = "myvpc" }
        cidr_block           = "10.99.0.0/16"
        instance_tenancy     = "default"
        enable_dns_support   = true
        enable_dns_hostnames = true
        subnets = {
          0 = {
            tags               = { Name = "public" }
            cidr_block         = "10.99.0.0/24"
            availability_zones = "us-east-1d"
            route_table_key    = 0 # public routes in rt0
          }
          1 = {
            tags               = { Name = "private1" }
            cidr_block         = "10.99.1.0/24"
            availability_zones = "us-east-1d"
            route_table_key    = 1 # private routes in rt1
          }
          2 = {
            tags               = { Name = "private2" }
            cidr_block         = "10.99.2.0/24"
            availability_zones = "us-east-1b"
            route_table_key    = 1 # private routes in rt1
          }
        }
      }
    }
    route_tables = {
      0 = { #public
        tags             = { Name = "public" }
        parent_vpc_key   = 0
        propagating_vgws = false
        routes = {
          0 = {
            cidr_block = "0.0.0.0/0"
            next_hop   = "igw"
          }
        }
      }
      1 = { #private
        tags             = { Name = "private" }
        parent_vpc_key   = 0
        propagating_vgws = true
        routes = {
          # 0 = {
          #     name = "private_traffic"
          #     cidr_block = "10.99.1.0/24"
          #     next_hop = "vpc"
          # }
        }
      }
    }
    internet_gateways = {
      0 = {
        tags           = { Name = "myigw" }
        parent_vpc_key = 0
      }
    }
    elastic_ip_addresses = { #must be created AFTER the internet gateway. not possible to associate beforehand
      0 = {
        ec2_instance_key = "0"
      }
    }
    security_groups = {
      0 = {
        vpc_key     = 0
        description = "sg for public endpoints"
        ingress_rules = {
          0 = {
            source_cidr = ["/32"] # home wan ip
            protocol    = "tcp"
            from_port   = 0
            to_port     = 22 # ssh
          }
          1 = {
            source_cidr = ["0.0.0.0/0"]
            protocol    = "tcp"
            from_port   = 0
            to_port     = 80 # http
          }
          2 = {
            source_cidr = ["0.0.0.0/0"]
            protocol    = "tcp"
            from_port   = 0
            to_port     = 443 # https
          }
        }
        egress_rules = {
          0 = {
            protocol         = "udp"
            from_port        = 0
            to_port          = 123 # ntp
            destination_cidr = ["0.0.0.0/0"]
          }
          1 = {
            protocol         = "udp"
            from_port        = 0
            to_port          = 53 # dns
            destination_cidr = ["0.0.0.0/0"]
          }
          2 = {
            protocol         = "tcp"
            from_port        = 0
            to_port          = 80 # http
            destination_cidr = ["0.0.0.0/0"]
          }
          3 = {
            protocol         = "tcp"
            from_port        = 0
            to_port          = 443 # https
            destination_cidr = ["0.0.0.0/0"]
          }
          4 = {
            protocol         = "tcp"
            from_port        = 0
            to_port          = 3306          # mysql
            destination_cidr = ["0.0.0.0/0"] #should really lock down to target subnet
          }
        }
      }
      1 = {
        vpc_key     = 0
        description = "sg for private endpoints"
        ingress_rules = {
          0 = {
            source_cidr = ["10.99.0.0/24"]
            protocol    = "tcp"
            from_port   = 0
            to_port     = 3306 # http
          }
        }
        egress_rules = {
          0 = {
            protocol         = "udp"
            from_port        = 0
            to_port          = 123 # ntp
            destination_cidr = ["0.0.0.0/0"]
          }
          1 = {
            protocol         = "udp"
            from_port        = 0
            to_port          = 53 # dns
            destination_cidr = ["0.0.0.0/0"]
          }
          2 = {
            protocol         = "tcp"
            from_port        = 0
            to_port          = 80 # http
            destination_cidr = ["0.0.0.0/0"]
          }
          3 = {
            protocol         = "tcp"
            from_port        = 0
            to_port          = 443 # https
            destination_cidr = ["0.0.0.0/0"]
          }
        }
      }
    }
  }
  compute = {
    key_pairs = {
      0 = {
        key_name            = "simon.jackson"
        algorithm           = "RSA"
        rsa_bits            = 2048
        public_key_filename = "../id_rsa.pub"
      }
    }
    ec2 = {
      0 = {
        tags               = { Name = "myec2" }
        ami                = "ami-0230bd60aa48260c6" #Amazon Linux 2023 AMI x64
        instance_type      = "t2.micro"
        vpc_key            = 0
        subnet_key         = 0
        security_group_key = 0 #public
        key_pair_key       = 0 #rsa key
        user_data          = <<EOF
        #!/bin/bash
        echo 'STARTUP SCRIPT
        pip install dbus-python -y
        EOF
      }
    }
    rds = {
      subnet_groups = {
        0 = { # group0 - linking subnet1 to vpc0, with the db instances
          name        = "application"
          description = "rds database backend subnets"
          subnet_keys = ["1", "2"]
        }
      }
      parameter_groups = {
        0 = {
          name   = "mysql5.7" #only lowercase, with hyphens allowed
          family = "mysql5.7"
          parameters = {
            #   0 = {
            #     name  = "log_connections"
            #     value = "1"
            #   }
          }
        }
      }
      instances = {
        0 = {
          allocated_storage   = 10 #gb
          subnet_group_key    = 0
          identifier          = "rdsinstance"
          db_name             = "mydb"
          engine              = "mysql"
          engine_version      = "5.7.44"
          instance_class      = "db.t3.micro"
          username            = "rds_user"
          password            = "fcWeWBWDFARc3Eqx7dswY2R7" #not insecure, private ip, and this lab is only alive for 8 hours.
          parameter_group_key = 0
          storage_encrypted   = true
          skip_final_snapshot = true
          tags                = { Name = "myrds" }
        }
      }
    }
  }
}